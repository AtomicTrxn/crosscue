import 'dart:typed_data';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/home/presentation/notifiers/past_puzzles_notifier.dart';
import 'package:crosscue/features/home/presentation/providers/home_providers.dart';
import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/models/crosshare_entry.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Captures `fetchMonth` calls and serves pre-canned responses keyed by
/// `(year, month)`.
class _FakeDownloader implements CrosshareDownloader {
  _FakeDownloader();

  final Map<(int, int), Result<List<CrosshareEntry>, CrosshareFetchMonthError>>
      monthResponses = {};
  final Map<String, Result<Uint8List, CrosshareDownloadError>>
      downloadResponses = {};
  final List<(int, int)> monthCalls = [];
  final List<String> downloadCalls = [];

  @override
  Future<Result<List<CrosshareEntry>, CrosshareFetchMonthError>> fetchMonth(
    int year,
    int month,
  ) async {
    monthCalls.add((year, month));
    return monthResponses[(year, month)] ??
        const Err(CrosshareFetchMonthError.networkError);
  }

  @override
  Future<Result<Uint8List, CrosshareDownloadError>> downloadById(
    String id,
  ) async {
    downloadCalls.add(id);
    return downloadResponses[id] ??
        const Err(CrosshareDownloadError.networkError);
  }

  @override
  Future<Result<Uint8List, CrosshareDownloadError>> downloadToday() async =>
      const Err(CrosshareDownloadError.networkError);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImportRepository implements ImportRepository {
  _FakeImportRepository();

  final List<PuzzleMetadata> stored = [];
  ImportJobResult Function(String? sourcePuzzleId)? nextImportResult;

  @override
  Future<List<PuzzleMetadata>> getAllMetadata() async =>
      List.unmodifiable(stored);

  @override
  Stream<List<PuzzleMetadata>> watchAllMetadata() =>
      Stream.value(List.unmodifiable(stored));

  @override
  Future<Puzzle?> getPuzzle(String id) async => null;

  @override
  Future<void> deletePuzzle(String id) async {
    stored.removeWhere((m) => m.id == id);
  }

  @override
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
    DateTime? publishDate,
  }) async {
    final result = (nextImportResult ?? _defaultImport)(sourcePuzzleId);
    if (result case JobSuccess(:final puzzle)) {
      stored.add(puzzle.metadata);
    }
    return result;
  }

  ImportJobResult _defaultImport(String? sourcePuzzleId) {
    final puzzle = _makePuzzle(
      id: 'local:${sourcePuzzleId ?? DateTime.now().microsecond}',
      sourcePuzzleId: sourcePuzzleId,
    );
    return ImportJobResult.success(puzzle);
  }
}

Puzzle _makePuzzle({required String id, String? sourcePuzzleId}) {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: id,
      sourceId: 'crosshare_daily_mini',
      sourcePuzzleId: sourcePuzzleId,
      title: 'Test',
      author: 'Author',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 5,
      height: 5,
      importedAt: DateTime.utc(2026, 5, 14),
    ),
    grid: Grid<SolutionCell>(
      width: 1,
      height: 1,
      cells: const [SolutionCell(isBlack: false, solution: 'A')],
    ),
    clues: const <Clue>[],
  );
}

CrosshareEntry _entry({
  required String id,
  required DateTime date,
  String title = 'Mini',
  String author = 'Author',
}) =>
    CrosshareEntry(
      id: id,
      date: date,
      title: title,
      authorName: author,
      width: 5,
      height: 5,
    );

// Today is 2026-05-14 per the runtime injection used in this session.
final _today = DateTime(2026, 5, 14);

ProviderContainer _container({
  required _FakeDownloader downloader,
  required _FakeImportRepository repo,
}) {
  return ProviderContainer(
    overrides: [
      currentLocalDateProvider.overrideWith((ref) => _today),
      crosshareDownloaderProvider.overrideWith((ref) => downloader),
      importRepositoryProvider.overrideWith((ref) => repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeDownloader downloader;
  late _FakeImportRepository repo;

  setUp(() {
    downloader = _FakeDownloader();
    repo = _FakeImportRepository();
  });

  test('initial load: filters today and future-scheduled days', () async {
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'fut', date: DateTime(2026, 5, 15), title: 'Future'),
      _entry(id: 'today', date: _today, title: 'Today'),
      _entry(id: 'yest', date: DateTime(2026, 5, 13), title: 'Yesterday'),
      _entry(id: 'old', date: DateTime(2026, 5, 1), title: 'Day 1'),
    ]);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    final state = await container.read(pastPuzzlesProvider.future);
    expect(state.items.map((i) => i.entry.id), ['yest', 'old']);
    expect(state.hasMore, isTrue);
  });

  test('initial load: items are sorted most-recent-first', () async {
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'a', date: DateTime(2026, 5, 1)),
      _entry(id: 'b', date: DateTime(2026, 5, 10)),
      _entry(id: 'c', date: DateTime(2026, 5, 5)),
    ]);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    final state = await container.read(pastPuzzlesProvider.future);
    expect(state.items.map((i) => i.entry.id), ['b', 'c', 'a']);
  });

  test('initial load: marks already-imported entries', () async {
    repo.stored.add(
      _makePuzzle(id: 'local:1', sourcePuzzleId: 'yest').metadata,
    );
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'yest', date: DateTime(2026, 5, 13)),
      _entry(id: 'old', date: DateTime(2026, 5, 1)),
    ]);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    final state = await container.read(pastPuzzlesProvider.future);
    expect(state.items[0].localPuzzleId, 'local:1');
    expect(state.items[1].localPuzzleId, isNull);
  });

  test('initial load: surfaces AsyncError on network failure', () async {
    downloader.monthResponses[(2026, 5)] =
        const Err(CrosshareFetchMonthError.networkError);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await expectLater(
      container.read(pastPuzzlesProvider.future),
      throwsA(anything),
    );
  });

  test('loadMore: appends the previous month', () async {
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'may1', date: DateTime(2026, 5, 13)),
    ]);
    downloader.monthResponses[(2026, 4)] = Ok([
      _entry(id: 'apr30', date: DateTime(2026, 4, 30)),
      _entry(id: 'apr1', date: DateTime(2026, 4, 1)),
    ]);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    await container.read(pastPuzzlesProvider.notifier).loadMore();
    final state = container.read(pastPuzzlesProvider).requireValue;
    expect(state.items.map((i) => i.entry.id), ['may1', 'apr30', 'apr1']);
    expect(state.hasMore, isTrue);
    expect(downloader.monthCalls, [(2026, 5), (2026, 4)]);
  });

  test('loadMore: crosses year boundary correctly', () async {
    downloader.monthResponses[(2026, 5)] = const Ok([]);
    // Walk back: 2026/05 → 2025/12 takes five loadMore calls.
    downloader.monthResponses[(2026, 4)] = const Ok([]);
    downloader.monthResponses[(2026, 3)] = const Ok([]);
    downloader.monthResponses[(2026, 2)] = const Ok([]);
    downloader.monthResponses[(2026, 1)] = const Ok([]);
    downloader.monthResponses[(2025, 12)] = Ok([
      _entry(id: 'dec', date: DateTime(2025, 12, 31)),
    ]);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    final notifier = container.read(pastPuzzlesProvider.notifier);
    for (var i = 0; i < 5; i++) {
      await notifier.loadMore();
    }
    final state = container.read(pastPuzzlesProvider).requireValue;
    expect(state.items.map((i) => i.entry.id), ['dec']);
    expect(downloader.monthCalls.last, (2025, 12));
  });

  test('loadMore: beforeArchiveStart flips hasMore to false', () async {
    downloader.monthResponses[(2026, 5)] = const Ok([]);
    downloader.monthResponses[(2026, 4)] =
        const Err(CrosshareFetchMonthError.beforeArchiveStart);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    await container.read(pastPuzzlesProvider.notifier).loadMore();
    final state = container.read(pastPuzzlesProvider).requireValue;
    expect(state.hasMore, isFalse);
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreError, isNull);
  });

  test('loadMore: networkError keeps existing items, sets loadMoreError',
      () async {
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'a', date: DateTime(2026, 5, 1)),
    ]);
    downloader.monthResponses[(2026, 4)] =
        const Err(CrosshareFetchMonthError.networkError);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    await container.read(pastPuzzlesProvider.notifier).loadMore();
    final state = container.read(pastPuzzlesProvider).requireValue;
    expect(state.items.map((i) => i.entry.id), ['a']);
    expect(state.loadMoreError, isNotNull);
    expect(state.hasMore, isTrue);
  });

  test('download: flips row to imported on success', () async {
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'yest', date: DateTime(2026, 5, 13)),
    ]);
    downloader.downloadResponses['yest'] = Ok(Uint8List.fromList([1, 2, 3]));

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    final entry =
        container.read(pastPuzzlesProvider).requireValue.items.first.entry;
    final puzzleId =
        await container.read(pastPuzzlesProvider.notifier).download(entry);

    expect(puzzleId, isNotNull);
    final state = container.read(pastPuzzlesProvider).requireValue;
    expect(state.items.first.isImported, isTrue);
    expect(state.items.first.localPuzzleId, puzzleId);
    expect(state.downloadingIds, isEmpty);
    expect(state.downloadErrors, isEmpty);
  });

  test('download: records error and clears downloading flag on failure',
      () async {
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'fail', date: DateTime(2026, 5, 13)),
    ]);
    downloader.downloadResponses['fail'] =
        const Err(CrosshareDownloadError.networkError);

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    final entry =
        container.read(pastPuzzlesProvider).requireValue.items.first.entry;
    final puzzleId =
        await container.read(pastPuzzlesProvider.notifier).download(entry);

    expect(puzzleId, isNull);
    final state = container.read(pastPuzzlesProvider).requireValue;
    expect(state.items.first.isImported, isFalse);
    expect(state.downloadErrors['fail'], isNotNull);
    expect(state.downloadingIds, isEmpty);
  });

  test('download: duplicate JobDuplicate re-syncs and marks imported',
      () async {
    repo.stored.add(
      _makePuzzle(id: 'local:dup', sourcePuzzleId: 'dup').metadata,
    );
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'dup', date: DateTime(2026, 5, 13)),
    ]);
    downloader.downloadResponses['dup'] = Ok(Uint8List.fromList([1]));
    repo.nextImportResult = (_) => const ImportJobResult.duplicate();

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    final entry =
        container.read(pastPuzzlesProvider).requireValue.items.first.entry;
    final puzzleId =
        await container.read(pastPuzzlesProvider.notifier).download(entry);

    expect(puzzleId, 'local:dup');
    final state = container.read(pastPuzzlesProvider).requireValue;
    expect(state.items.first.localPuzzleId, 'local:dup');
  });

  test('download: rejects a second concurrent tap for the same entry',
      () async {
    downloader.monthResponses[(2026, 5)] = Ok([
      _entry(id: 'busy', date: DateTime(2026, 5, 13)),
    ]);
    downloader.downloadResponses['busy'] = Ok(Uint8List.fromList([1]));

    final container = _container(downloader: downloader, repo: repo);
    addTearDown(container.dispose);

    await container.read(pastPuzzlesProvider.future);
    final entry =
        container.read(pastPuzzlesProvider).requireValue.items.first.entry;

    // Fire both; the second should short-circuit and return null because the
    // first is already in flight in the (synchronous) state-update path.
    final notifier = container.read(pastPuzzlesProvider.notifier);
    final firstFuture = notifier.download(entry);
    final second = await notifier.download(entry);
    final first = await firstFuture;

    expect(first, isNotNull);
    expect(second, isNull);
    // Only one network attempt for that entry.
    expect(downloader.downloadCalls, ['busy']);
  });
}

// ParseError is referenced indirectly via JobFailure; ensure the import is
// not stripped if unused above. (Reference left explicit to document intent.)
// ignore: unused_element
ParseError _ = ParseError.invalidFormat;
