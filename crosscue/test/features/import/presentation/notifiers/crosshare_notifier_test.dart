// Unit tests for CrosshareNotifier — the settings-screen / onboarding
// interactive Crosshare download notifier (distinct from
// CrosshareAutoDownloadService, the silent background one).
//
// Focused specifically on a regression found in on-device review: this
// notifier resolves its dependencies into `late final` fields inside
// build(), which throws LateInitializationError if Riverpod ever
// re-invokes build() on the same instance (see
// past_puzzles_notifier_test.dart for the same bug, reproduced via a real
// device). CrosshareNotifier has no confirmed live trigger for that
// rebuild path today (nothing in the app currently calls
// `ref.invalidate(crosshareProvider)`), but it had the exact same
// `late final`-in-build() pattern and got the identical fix — this test
// exercises that rebuild directly via the container, independent of
// whether current call sites happen to reach it, since any future caller
// invalidating this provider would otherwise silently reintroduce the
// crash.

import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/models/crosshare_entry.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/notifiers/crosshare_notifier.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDownloader implements CrosshareDownloader {
  _FakeDownloader(this.result);

  Result<CrosshareDailyDownload, CrosshareDownloadError> result;
  int calls = 0;

  @override
  Future<Result<CrosshareDailyDownload, CrosshareDownloadError>>
      downloadTodayWithMetadata() async {
    calls++;
    return result;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImportRepo implements ImportRepository {
  _FakeImportRepo(this.result);

  ImportJobResult result;

  @override
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
    DateTime? publishDate,
  }) async =>
      result;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Puzzle _puzzle() {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'local:1',
      sourceId: 'crosshare_daily_mini',
      title: 'Test',
      author: 'Author',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 5,
      height: 5,
      importedAt: DateTime.utc(2026, 5, 14),
    ),
    grid: Grid(width: 0, height: 0, cells: const []),
    clues: const [],
  );
}

Result<CrosshareDailyDownload, CrosshareDownloadError> _download() => Ok(
      CrosshareDailyDownload(bytes: Uint8List.fromList([1]), entry: _entry()),
    );

CrosshareEntry _entry() => CrosshareEntry(
      id: 'crosshare-today',
      date: DateTime.utc(2026, 5, 14),
      title: 'Today',
      authorName: 'Crosshare',
      width: 5,
      height: 5,
    );

void main() {
  late AppDatabase db;
  late AppSettingsRepositoryImpl settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = AppSettingsRepositoryImpl(dao: db.appSettingsDao);
  });
  tearDown(() => db.close());

  ProviderContainer container({
    required _FakeDownloader downloader,
    required _FakeImportRepo importRepo,
  }) {
    return ProviderContainer(
      overrides: [
        crosshareDownloaderProvider.overrideWith((ref) => downloader),
        importRepositoryProvider.overrideWith((ref) => importRepo),
        appSettingsProvider.overrideWithValue(settings),
      ],
    );
  }

  test('download succeeds on a normal, single build()', () async {
    final downloader = _FakeDownloader(_download());
    final repo = _FakeImportRepo(ImportJobResult.success(_puzzle()));
    final c = container(downloader: downloader, importRepo: repo);
    addTearDown(c.dispose);

    await c.read(crosshareProvider.notifier).download();

    expect(c.read(crosshareProvider), isA<CrosshareSuccess>());
  });

  test(
      'download still works after build() is re-invoked on the same '
      'instance (does not throw LateInitializationError)', () async {
    final downloader = _FakeDownloader(_download());
    final repo = _FakeImportRepo(ImportJobResult.success(_puzzle()));
    final c = container(downloader: downloader, importRepo: repo);
    addTearDown(c.dispose);

    // Keep a listener open — matches how a real screen's `ref.watch`
    // keeps the (autoDispose) notifier instance alive across a rebuild
    // instead of letting it fully dispose and recreate.
    final sub = c.listen(crosshareProvider, (_, __) {});
    addTearDown(sub.close);

    // First build() already ran as a side effect of the container reading
    // the provider above. Force a second build() on the *same* instance —
    // this is what `ref.invalidate(crosshareProvider)` would do from any
    // future caller (there is none today), and is exactly the path that
    // threw LateInitializationError before the fix.
    c.invalidate(crosshareProvider);
    c.read(crosshareProvider);

    await c.read(crosshareProvider.notifier).download();

    expect(c.read(crosshareProvider), isA<CrosshareSuccess>());
    expect(downloader.calls, 1);
  });
}
