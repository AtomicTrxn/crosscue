// Unit tests for CrosshareAutoDownloadService — covers the silent-download
// orchestration added for #116 Phase 1: live progress phases, retry with
// backoff on transient network errors, and the slow-network path (an
// in-flight download reads as `inProgress` until it resolves).
//
// Uses a real in-memory AppSettingsRepository (mirrors the repo tests) plus
// hand-written fakes for the downloader and import repo — the project has no
// mock framework.

import 'dart:async';
import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake downloader. Returns the result at index `min(call - 1, last)` so a
/// single-element list repeats forever and a multi-element list scripts the
/// first N attempts. An optional [gate] lets a test hold a call mid-flight to
/// observe the in-progress phase (slow-network path).
class _FakeDownloader implements CrosshareDownloader {
  _FakeDownloader(this._results, {this.gate});

  final List<Result<Uint8List, CrosshareDownloadError>> _results;
  final Completer<void>? gate;
  int calls = 0;

  @override
  Future<Result<Uint8List, CrosshareDownloadError>> downloadToday() async {
    calls++;
    if (gate != null) await gate!.future;
    final i = (calls - 1).clamp(0, _results.length - 1);
    return _results[i];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// Fake import repo. Returns a fixed [result] from [importBytes]; everything
/// else is unused by the service.
class _FakeImportRepo implements ImportRepository {
  _FakeImportRepo(this.result);

  final ImportJobResult result;
  int imports = 0;

  @override
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
    DateTime? publishDate,
  }) async {
    imports++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

Uint8List _bytes() => Uint8List.fromList(const [1, 2, 3]);

Result<Uint8List, CrosshareDownloadError> _ok() => Ok(_bytes());
Result<Uint8List, CrosshareDownloadError> _err(CrosshareDownloadError e) =>
    Err(e);

void main() {
  late AppDatabase db;
  late AppSettingsRepositoryImpl settings;
  late List<CrosshareAutoDownloadPhase> phases;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = AppSettingsRepositoryImpl(dao: db.appSettingsDao);
    phases = [];
  });
  tearDown(() => db.close());

  CrosshareAutoDownloadService build({
    required _FakeDownloader downloader,
    ImportJobResult importResult = const JobDuplicate(),
    int maxAttempts = 3,
  }) {
    return CrosshareAutoDownloadService(
      downloader: downloader,
      settings: settings,
      importRepo: _FakeImportRepo(importResult),
      onPhase: phases.add,
      retryBackoff: Duration.zero,
      maxAttempts: maxAttempts,
    );
  }

  String today() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  group('attemptIfNeeded short-circuits', () {
    test('does nothing when auto-download is disabled', () async {
      final dl = _FakeDownloader([_ok()]);
      await settings.setCrosshareAutoDownload(false);

      await build(downloader: dl).attemptIfNeeded();

      expect(dl.calls, 0);
      expect(phases, isEmpty);
    });

    test('does nothing when already downloaded today (cheap cold start)',
        () async {
      final dl = _FakeDownloader([_ok()]);
      await settings.setCrosshareAutoDownload(true);
      await settings.setCrosshareLastDownloadedDate(today());

      await build(downloader: dl).attemptIfNeeded();

      expect(dl.calls, 0);
      expect(phases, isEmpty);
    });
  });

  group('success / terminal-without-retry', () {
    setUp(() => settings.setCrosshareAutoDownload(true));

    test('success emits inProgress then idle and records today', () async {
      final dl = _FakeDownloader([_ok()]);
      await build(
        downloader: dl,
        importResult: JobSuccess(_FakePuzzle()),
      ).attemptIfNeeded();

      expect(phases, [
        CrosshareAutoDownloadPhase.inProgress,
        CrosshareAutoDownloadPhase.idle,
      ]);
      expect(await settings.getCrosshareLastDownloadedDate(), today());
      expect(dl.calls, 1);
    });

    test('duplicate is treated as success (idle, no retry)', () async {
      final dl = _FakeDownloader([_ok()]);
      await build(downloader: dl).attemptIfNeeded(); // default JobDuplicate

      expect(phases.last, CrosshareAutoDownloadPhase.idle);
      expect(await settings.getCrosshareLastDownloadedDate(), today());
      expect(dl.calls, 1);
    });

    test('notFound is not an error and is not retried', () async {
      final dl = _FakeDownloader([_err(CrosshareDownloadError.notFound)]);
      await build(downloader: dl).attemptIfNeeded();

      expect(phases, [
        CrosshareAutoDownloadPhase.inProgress,
        CrosshareAutoDownloadPhase.idle,
      ]);
      expect(dl.calls, 1);
    });
  });

  group('retry with backoff on transient network errors', () {
    setUp(() => settings.setCrosshareAutoDownload(true));

    test('retries up to maxAttempts then reports failed', () async {
      final dl = _FakeDownloader([_err(CrosshareDownloadError.networkError)]);
      await build(downloader: dl, maxAttempts: 3).attemptIfNeeded();

      expect(dl.calls, 3);
      expect(phases, [
        CrosshareAutoDownloadPhase.inProgress,
        CrosshareAutoDownloadPhase.failed,
      ]);
    });

    test('recovers when a retry succeeds', () async {
      final dl = _FakeDownloader([
        _err(CrosshareDownloadError.networkError),
        _err(CrosshareDownloadError.networkError),
        _ok(),
      ]);
      await build(downloader: dl, maxAttempts: 3).attemptIfNeeded();

      expect(dl.calls, 3);
      expect(phases.last, CrosshareAutoDownloadPhase.idle);
      expect(await settings.getCrosshareLastDownloadedDate(), today());
    });
  });

  group('slow network', () {
    test('stays inProgress until the in-flight download resolves', () async {
      await settings.setCrosshareAutoDownload(true);
      final gate = Completer<void>();
      final dl = _FakeDownloader([_ok()], gate: gate);

      final future = build(downloader: dl).attemptIfNeeded();
      // Let the settings reads + the download dispatch run, then hold.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(dl.calls, 1);
      expect(phases, [CrosshareAutoDownloadPhase.inProgress]);

      gate.complete();
      await future;

      expect(phases, [
        CrosshareAutoDownloadPhase.inProgress,
        CrosshareAutoDownloadPhase.idle,
      ]);
    });
  });
}

/// Minimal stand-in Puzzle for the JobSuccess case; the service never inspects
/// it, so an empty metadata shell is enough.
class _FakePuzzle implements Puzzle {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}
