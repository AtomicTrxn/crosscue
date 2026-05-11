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
}
