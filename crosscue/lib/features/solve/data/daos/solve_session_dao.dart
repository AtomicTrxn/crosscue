import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/database/tables/cell_progress_table.dart';
import 'package:crosscue/core/database/tables/solve_sessions_table.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:drift/drift.dart';

part 'solve_session_dao.g.dart';

@DriftAccessor(tables: [SolveSessionsTable, CellProgressTable])
class SolveSessionDao extends DatabaseAccessor<AppDatabase>
    with _$SolveSessionDaoMixin {
  SolveSessionDao(super.db);

  // ---------------------------------------------------------------------------
  // Session queries
  // ---------------------------------------------------------------------------

  /// Returns the most recent in-progress session for [puzzleId], or null.
  Future<SolveSessionRow?> findActiveSession(String puzzleId) =>
      (select(solveSessionsTable)
            ..where(
              (t) =>
                  t.puzzleId.equals(puzzleId) & t.status.equals('in_progress'),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Returns the most recent session for [puzzleId] regardless of status,
  /// or null if no session has ever been started for this puzzle.
  /// Used by the Archive screen to determine puzzle status.
  Future<SolveSessionRow?> getLatestSession(String puzzleId) =>
      (select(solveSessionsTable)
            ..where((t) => t.puzzleId.equals(puzzleId))
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Returns the latest session per puzzle in a single query, keyed by
  /// `puzzleId`. Replaces the per-puzzle [getLatestSession] N+1 the Archive
  /// screen used to run — see issue #121.
  ///
  /// Rows are fetched ordered by `lastPlayedAt` descending and de-duplicated
  /// in Dart (first occurrence wins), matching the `orderBy desc ..limit(1)`
  /// semantics of [getLatestSession] per puzzle, including the tie-break.
  Future<Map<String, SolveSessionRow>> latestSessionByPuzzle() async {
    final rows = await (select(solveSessionsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)]))
        .get();
    final byPuzzle = <String, SolveSessionRow>{};
    for (final row in rows) {
      byPuzzle.putIfAbsent(row.puzzleId, () => row);
    }
    return byPuzzle;
  }

  /// Returns the number of filled cells (non-null `guess`) per session in a
  /// single grouped query, keyed by `sessionId`. Sessions with no filled
  /// cells are absent from the map (callers default to 0).
  ///
  /// Used by the Archive completion-fraction pie together with
  /// `puzzles.fillable_cell_count` so the fraction can be computed without
  /// loading and JSON-decoding the full puzzle grid. See issue #121.
  Future<Map<int, int>> filledCellCountsBySession() async {
    final sessionId = cellProgressTable.sessionId;
    final filled = cellProgressTable.guess.count();
    final query = selectOnly(cellProgressTable)
      ..addColumns([sessionId, filled])
      ..where(cellProgressTable.guess.isNotNull())
      ..groupBy([sessionId]);
    final rows = await query.get();
    return {
      for (final row in rows) row.read(sessionId)!: row.read(filled) ?? 0,
    };
  }

  /// Emits whenever any solve session changes. Archive/Home projections use
  /// this as a table-change signal and then reload their denormalized rows.
  Stream<List<SolveSessionRow>> watchAllSessions() =>
      select(solveSessionsTable).watch();

  /// Creates a new session and returns its auto-increment id.
  Future<int> createSession(String puzzleId) {
    final now = DateTime.now().toUtc();
    return into(solveSessionsTable).insert(
      SolveSessionsTableCompanion.insert(
        puzzleId: puzzleId,
        deviceId: 'local',
        status: const Value('in_progress'),
        startedAt: now,
        lastPlayedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Session writes
  // ---------------------------------------------------------------------------

  /// Persists all mutable session fields after each autosave tick.
  Future<void> updateSession({
    required int sessionId,
    required int elapsedMs,
    required int focusRow,
    required int focusCol,
    required String direction,
    required String status,
    required bool isPaused,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
    String? completionType,
    DateTime? completedAt,
    String? solvedDateLocal,
    String? solvedTimezone,
  }) {
    final now = DateTime.now().toUtc();
    return (update(solveSessionsTable)..where((t) => t.id.equals(sessionId)))
        .write(
      SolveSessionsTableCompanion(
        elapsedMs: Value(elapsedMs),
        focusRow: Value(focusRow),
        focusCol: Value(focusCol),
        direction: Value(direction),
        status: Value(status),
        isPaused: Value(isPaused),
        checkCount: Value(checkCount),
        revealCount: Value(revealCount),
        usedCheck: Value(usedCheck),
        usedReveal: Value(usedReveal),
        cleanSolveEligible: Value(cleanSolveEligible),
        lastPlayedAt: Value(now),
        updatedAt: Value(now),
        completionType: Value(completionType),
        completedAt: Value(completedAt),
        solvedDateLocal: Value(solvedDateLocal),
        solvedTimezone: Value(solvedTimezone),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cell progress
  // ---------------------------------------------------------------------------

  /// Replaces all cell-progress rows for [sessionId] with the current
  /// non-blank cells from [progress].
  ///
  /// Uses delete-then-insert inside a transaction so that cells cleared by
  /// backspace or reset do not leave orphan rows in the database.
  Future<void> saveCellProgress(
    int sessionId,
    Grid<CellProgress> progress,
    int width,
    int height,
  ) async {
    final now = DateTime.now().toUtc();
    final companions = <CellProgressTableCompanion>[];

    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        final cell = progress.cell(r, c);
        if (cell.letter.isEmpty && cell.state == CellState.empty) continue;
        companions.add(
          CellProgressTableCompanion.insert(
            sessionId: sessionId,
            row: r,
            col: c,
            guess: Value(cell.letter.isEmpty ? null : cell.letter),
            state: Value(cell.state.name),
            isPencil: Value(cell.isPencil),
            updatedAt: now,
          ),
        );
      }
    }

    await transaction(() async {
      // The parent session can be deleted out from under an open solve screen
      // — e.g. the puzzle is removed from the Archive (or wiped), cascading the
      // session away — while a debounced autosave is still in flight. Guard the
      // delete-then-insert so a vanished parent is a no-op instead of a FOREIGN
      // KEY violation that silently drops the write and logs an unhandled error.
      final parent = await (selectOnly(solveSessionsTable)
            ..addColumns([solveSessionsTable.id])
            ..where(solveSessionsTable.id.equals(sessionId))
            ..limit(1))
          .getSingleOrNull();
      if (parent == null) return;

      await (delete(cellProgressTable)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      if (companions.isNotEmpty) {
        await batch((b) => b.insertAll(cellProgressTable, companions));
      }
    });
  }

  /// Loads all cell-progress rows for a session (used when resuming).
  Future<List<CellProgressRow>> loadCellProgress(int sessionId) =>
      (select(cellProgressTable)..where((t) => t.sessionId.equals(sessionId)))
          .get();

  /// Emits whenever cell progress changes. Archive completion fractions depend
  /// on these rows, so this drives reactive Archive/Home status refreshes.
  Stream<List<CellProgressRow>> watchAllCellProgress() =>
      select(cellProgressTable).watch();
}
