import 'package:drift/drift.dart';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/database/tables/puzzles_table.dart';
import 'package:crosscue/core/database/tables/solve_sessions_table.dart';

part 'stats_dao.g.dart';

/// One completed session with the puzzle dimensions needed for personal-best
/// computation.  Returned by [StatsDao.getCompletedSessionsWithPuzzle].
typedef CompletedSessionStat = ({
  String? completionType,
  int elapsedMs,
  String? solvedDateLocal,
  int width,
  int height,
  String? difficulty,
});

/// Provides aggregate and streak-related queries for the Stats screen.
///
/// Raw data is fetched here; all computation (streak algorithm, averages,
/// personal-best comparisons) is done in [StatsRepositoryImpl] so it is
/// easily unit-testable without a database.
@DriftAccessor(tables: [SolveSessionsTable, PuzzlesTable])
class StatsDao extends DatabaseAccessor<AppDatabase> with _$StatsDaoMixin {
  StatsDao(super.db);

  // ---------------------------------------------------------------------------
  // Completed sessions
  // ---------------------------------------------------------------------------

  /// All sessions that have a [completionType] set, joined with the puzzle's
  /// grid dimensions.  Used for PB computation and average-time calculation.
  Future<List<CompletedSessionStat>> getCompletedSessionsWithPuzzle() async {
    final rows = await (select(solveSessionsTable)
          ..where((t) => t.completionType.isNotNull()))
        .join([
      innerJoin(
        puzzlesTable,
        puzzlesTable.id.equalsExp(solveSessionsTable.puzzleId),
      ),
    ]).get();

    return rows.map((row) {
      final session = row.readTable(solveSessionsTable);
      final puzzle = row.readTable(puzzlesTable);
      return (
        completionType: session.completionType,
        elapsedMs: session.elapsedMs,
        solvedDateLocal: session.solvedDateLocal,
        width: puzzle.width,
        height: puzzle.height,
        difficulty: puzzle.difficulty,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Streak dates
  // ---------------------------------------------------------------------------

  /// Distinct [solvedDateLocal] values for streak-eligible completions
  /// (clean / checked / hinted — excludes 'revealed').
  ///
  /// Returns strings in 'yyyy-MM-dd' format; nulls are filtered out in the
  /// repository before running the streak algorithm.
  Future<List<String?>> getStreakDates() {
    return (selectOnly(solveSessionsTable)
          ..addColumns([solveSessionsTable.solvedDateLocal])
          ..where(
            solveSessionsTable.completionType.isNotNull() &
                solveSessionsTable.completionType.isNotValue('revealed'),
          ))
        .map((r) => r.read(solveSessionsTable.solvedDateLocal))
        .get();
  }

  // ---------------------------------------------------------------------------
  // Completion rate denominator
  // ---------------------------------------------------------------------------

  /// Total number of solve sessions ever started (for completion-rate stat).
  Future<int> countAllSessions() async {
    final count = solveSessionsTable.id.count();
    final q = selectOnly(solveSessionsTable)..addColumns([count]);
    final result = await q.getSingle();
    return result.read(count) ?? 0;
  }
}
