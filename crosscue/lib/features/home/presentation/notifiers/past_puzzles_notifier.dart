import 'dart:async';

import 'package:crosscue/features/home/domain/models/past_puzzle_item.dart';
import 'package:crosscue/features/home/presentation/notifiers/past_puzzles_state.dart';
import 'package:crosscue/features/home/presentation/providers/home_providers.dart';
import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/models/crosshare_entry.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'past_puzzles_notifier.g.dart';

/// Source ID used when stamping imports from the Crosshare daily-mini archive.
const _crosshareSourceId = 'crosshare_daily_mini';

/// Loads and manages the "Past puzzles" listing on the Today screen.
///
/// Walks Crosshare's monthly archive pages backward from the current month,
/// excludes today and any future-scheduled days, and joins each archive entry
/// with the local puzzle list so the UI can show download/solve state.
@riverpod
class PastPuzzlesNotifier extends _$PastPuzzlesNotifier {
  late final CrosshareDownloader _downloader;
  late final ImportRepository _importRepo;

  @override
  Future<PastPuzzlesState> build() async {
    _downloader = ref.read(crosshareDownloaderProvider);
    _importRepo = ref.read(importRepositoryProvider);

    // Re-merge local import status whenever the puzzle list changes (e.g.
    // a download succeeded elsewhere, or the user deleted a puzzle).
    ref.listen(puzzleListProvider, (_, __) => _resyncLocalStatus());

    return _loadInitial();
  }

  /// Fetches the initial page: the current month minus today and future days.
  Future<PastPuzzlesState> _loadInitial() async {
    final today = _today();
    final monthKey = _encodeMonth(today.year, today.month);

    final result = await _downloader.fetchMonth(today.year, today.month);
    if (result.isErr) {
      // Surface as AsyncError via throw so the initial-load UI can show the
      // error+retry affordance. Mid-stream errors are handled differently.
      throw _initialLoadException(result.error);
    }

    final items = await _toItems(
      _filterEntries(result.value, beforeOrEqual: today, excludeToday: true),
    );

    return PastPuzzlesState(
      items: items,
      oldestMonthFetched: monthKey,
      hasMore: true,
    );
  }

  /// Fetches one month older than the current cursor. No-op when there are
  /// no more months or a fetch is already in flight.
  Future<void> loadMore() async {
    final current = _currentState();
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state =
        AsyncData(current.copyWith(isLoadingMore: true, loadMoreError: null));

    final (year, month) = _previousMonth(current.oldestMonthFetched);
    final result = await _downloader.fetchMonth(year, month);

    if (result.isErr) {
      final stillCurrent = _currentState();
      if (stillCurrent == null) return;
      switch (result.error) {
        case CrosshareFetchMonthError.beforeArchiveStart:
          state = AsyncData(
            stillCurrent.copyWith(isLoadingMore: false, hasMore: false),
          );
        case CrosshareFetchMonthError.networkError:
          state = AsyncData(
            stillCurrent.copyWith(
              isLoadingMore: false,
              loadMoreError: 'Could not load more puzzles. Check your '
                  'connection and try again.',
            ),
          );
        case CrosshareFetchMonthError.malformedPage:
          state = AsyncData(
            stillCurrent.copyWith(
              isLoadingMore: false,
              loadMoreError: 'Could not read the Crosshare archive page.',
            ),
          );
      }
      return;
    }

    final older = await _toItems(_filterEntries(result.value));
    final stillCurrent = _currentState();
    if (stillCurrent == null) return;
    state = AsyncData(
      stillCurrent.copyWith(
        items: [...stillCurrent.items, ...older],
        oldestMonthFetched: _encodeMonth(year, month),
        isLoadingMore: false,
        loadMoreError: null,
      ),
    );
  }

  /// Retries the most recent failed [loadMore].
  Future<void> retryLoadMore() => loadMore();

  /// Downloads the .puz for [entry], imports it, and flips that row to the
  /// imported state. Returns the local puzzle ID on success, or null on
  /// failure (an inline error is also written into state).
  Future<String?> download(CrosshareEntry entry) async {
    final current = _currentState();
    if (current == null) return null;
    if (current.downloadingIds.contains(entry.id)) return null;

    state = AsyncData(
      current.copyWith(
        downloadingIds: <String>{...current.downloadingIds, entry.id},
        downloadErrors: <String, String>{...current.downloadErrors}
          ..remove(entry.id),
      ),
    );

    final dl = await _downloader.downloadById(entry.id);
    if (dl.isErr) {
      _markDownloadFailed(entry.id, 'Could not reach Crosshare. Try again.');
      return null;
    }

    final import = await _importRepo.importBytes(
      dl.value,
      sourceId: _crosshareSourceId,
      sourcePuzzleId: entry.id,
      publishDate: entry.date,
    );

    switch (import) {
      case JobSuccess(:final puzzle):
        _markDownloadSucceeded(entry.id, puzzle.id);
        return puzzle.id;
      case JobDuplicate():
        // Already imported (e.g. user imported it from another path). Mark
        // the row as imported by re-resolving local status from the DB.
        await _resyncLocalStatus();
        return _currentState()
            ?.items
            .firstWhere(
              (item) => item.entry.id == entry.id,
              orElse: () => PastPuzzleItem(entry: entry),
            )
            .localPuzzleId;
      case JobFailure():
        _markDownloadFailed(entry.id, 'Could not import the puzzle.');
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Riverpod 3 dropped `AsyncValue.valueOrNull`; replicate locally.
  PastPuzzlesState? _currentState() => switch (state) {
        AsyncData(:final value) => value,
        _ => null,
      };

  /// Re-queries the local puzzle list and updates `localPuzzleId` for every
  /// item. Called after a successful import and whenever puzzleList changes.
  Future<void> _resyncLocalStatus() async {
    final current = _currentState();
    if (current == null) return;
    final byCrosshareId = await _byCrosshareId();
    final next = [
      for (final item in current.items)
        item.copyWith(localPuzzleId: byCrosshareId[item.entry.id]),
    ];
    state = AsyncData(current.copyWith(items: next));
  }

  /// Loads the imported-puzzle map: Crosshare entry id → local puzzle id.
  Future<Map<String, String>> _byCrosshareId() async {
    final metas = await _importRepo.getAllMetadata();
    return {
      for (final m in metas)
        if (m.sourceId == _crosshareSourceId && m.sourcePuzzleId != null)
          m.sourcePuzzleId!: m.id,
    };
  }

  /// Returns Crosshare entries filtered to the visible-past range:
  ///   - drops anything dated in the future (e.g. day 14 when today is day 13)
  ///   - optionally drops today itself
  ///   - sorts most-recent-first
  List<CrosshareEntry> _filterEntries(
    List<CrosshareEntry> entries, {
    DateTime? beforeOrEqual,
    bool excludeToday = false,
  }) {
    final today = _today();
    final filtered = entries.where((e) {
      if (e.date.isAfter(today)) return false;
      if (excludeToday && _isSameDay(e.date, today)) return false;
      if (beforeOrEqual != null && e.date.isAfter(beforeOrEqual)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<List<PastPuzzleItem>> _toItems(List<CrosshareEntry> entries) async {
    final byCrosshareId = await _byCrosshareId();
    return [
      for (final entry in entries)
        PastPuzzleItem(
          entry: entry,
          localPuzzleId: byCrosshareId[entry.id],
        ),
    ];
  }

  void _markDownloadSucceeded(String entryId, String localPuzzleId) {
    final current = _currentState();
    if (current == null) return;
    final downloading = <String>{...current.downloadingIds}..remove(entryId);
    final errors = <String, String>{...current.downloadErrors}..remove(entryId);
    final items = [
      for (final item in current.items)
        if (item.entry.id == entryId)
          item.copyWith(localPuzzleId: localPuzzleId)
        else
          item,
    ];
    state = AsyncData(
      current.copyWith(
        items: items,
        downloadingIds: downloading,
        downloadErrors: errors,
      ),
    );
  }

  void _markDownloadFailed(String entryId, String message) {
    final current = _currentState();
    if (current == null) return;
    final downloading = <String>{...current.downloadingIds}..remove(entryId);
    final errors = <String, String>{
      ...current.downloadErrors,
      entryId: message,
    };
    state = AsyncData(
      current.copyWith(
        downloadingIds: downloading,
        downloadErrors: errors,
      ),
    );
  }

  Exception _initialLoadException(CrosshareFetchMonthError error) {
    return switch (error) {
      CrosshareFetchMonthError.beforeArchiveStart =>
        Exception('Crosshare archive is unavailable.'),
      CrosshareFetchMonthError.networkError =>
        Exception('Could not reach Crosshare. Check your connection.'),
      CrosshareFetchMonthError.malformedPage =>
        Exception('Could not read the Crosshare archive page.'),
    };
  }

  DateTime _today() => ref.read(currentLocalDateProvider);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _encodeMonth(int year, int month) => year * 12 + (month - 1);

  static (int year, int month) _previousMonth(int encoded) {
    final prev = encoded - 1;
    return (prev ~/ 12, (prev % 12) + 1);
  }
}
