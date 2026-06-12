// Widget tests for PastPuzzlesSection's degradation rendering (#257).
//
// Locks the stale-but-honest policy from
// docs/architecture/compatibility.md → "External dependency: Crosshare":
// when a Crosshare fetch fails mid-stream, already-loaded rows stay visible
// and the failure surfaces as a quiet inline message — never a crash, never
// fabricated content. (Initial-load failures and the notifier-level state
// transitions are covered in past_puzzles_notifier_test.dart.)

import 'dart:typed_data';

import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/home/presentation/providers/home_providers.dart';
import 'package:crosscue/features/home/presentation/widgets/past_puzzles_section.dart';
import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/models/crosshare_entry.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Crosshare daily minis roll over by UTC date.
final _today = DateTime.utc(2026, 5, 14);

class _FakeDownloader implements CrosshareDownloader {
  final Map<(int, int), Result<List<CrosshareEntry>, CrosshareFetchMonthError>>
      monthResponses = {};

  @override
  Future<Result<List<CrosshareEntry>, CrosshareFetchMonthError>> fetchMonth(
    int year,
    int month,
  ) async {
    return monthResponses[(year, month)] ??
        const Err(CrosshareFetchMonthError.networkError);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImportRepository implements ImportRepository {
  @override
  Future<List<PuzzleMetadata>> getAllMetadata() async => const [];

  @override
  Stream<List<PuzzleMetadata>> watchAllMetadata() => Stream.value(const []);

  @override
  Future<Puzzle?> getPuzzle(String id) async => null;

  @override
  Stream<bool> watchPuzzleExists(String id) => Stream.value(false);

  @override
  Future<void> deletePuzzle(String id) async {}

  @override
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
    DateTime? publishDate,
  }) async =>
      const ImportJobResult.failure(ParseError.unknown);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The section is gated behind the auto-download setting; force it on
/// without standing up the boot-settings plumbing.
class _AutoDownloadOn extends CrosshareAutoDownload {
  @override
  bool build() => true;
}

CrosshareEntry _entry({required String id, required DateTime date}) =>
    CrosshareEntry(
      id: id,
      date: DateTime.utc(date.year, date.month, date.day),
      title: 'Mini $id',
      authorName: 'Author',
      width: 5,
      height: 5,
    );

Future<void> _pumpFrames(WidgetTester tester, [int frames = 6]) async {
  // Never pumpAndSettle (project convention) — pump a fixed budget instead.
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
      'mid-stream fetch failure keeps loaded rows and shows a quiet error',
      (tester) async {
    final downloader = _FakeDownloader()
      ..monthResponses[(2026, 5)] = Ok([
        _entry(id: 'abc123', date: DateTime.utc(2026, 5, 13)),
      ])
      // The older month the footer's "Load more" walks back to.
      ..monthResponses[(2026, 4)] =
          const Err(CrosshareFetchMonthError.networkError);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentLocalDateProvider.overrideWith((ref) => _today),
          crosshareDownloaderProvider.overrideWith((ref) => downloader),
          importRepositoryProvider
              .overrideWith((ref) => _FakeImportRepository()),
          crosshareAutoDownloadProvider.overrideWith(_AutoDownloadOn.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PastPuzzlesSection()),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    // Initial load succeeded: the row is visible.
    expect(find.text('Mini abc123'), findsOneWidget);

    // Walk back a month — that fetch fails.
    await tester.tap(find.text('Load more'));
    await _pumpFrames(tester);

    // Stale-but-honest: the loaded row survives, the failure is a quiet
    // inline message with a retry, and nothing fabricated appears.
    expect(find.text('Mini abc123'), findsOneWidget);
    expect(
      find.textContaining('Could not load more puzzles'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
