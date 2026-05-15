import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/database/tables/imported_solve_stats_table.dart';
import 'package:crosscue/core/database/tables/puzzle_completions_table.dart';
import 'package:crosscue/core/database/tables/puzzles_table.dart';
import 'package:crosscue/core/database/tables/solve_sessions_table.dart';
import 'package:drift/drift.dart';

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

typedef StatsExportRecord = ({
  String completionType,
  int elapsedMs,
  String solvedDateLocal,
  String? solvedTimezone,
  int width,
  int height,
  String puzzleTitle,
});

/// Provides aggregate and streak-related queries for the Stats screen.
///
/// Raw data is fetched here; all computation (streak algorithm, averages,
/// personal-best comparisons) is done in [StatsRepositoryImpl] so it is
/// easily unit-testable without a database.
@DriftAccessor(
  tables: [
    SolveSessionsTable,
    PuzzlesTable,
    ImportedSolveStatsTable,
    PuzzleCompletionsTable,
  ],
)
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

    final localRows = rows.map((row) {
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

    final importedRows = await select(importedSolveStatsTable).get();
    return [
      ...localRows,
      ...importedRows.map(
        (row) => (
          completionType: row.completionType,
          elapsedMs: row.elapsedMs,
          solvedDateLocal: row.solvedDateLocal,
          width: row.width,
          height: row.height,
          difficulty: null,
        ),
      ),
    ];
  }

  Future<List<StatsExportRecord>> getExportRecords() async {
    final rows = await (select(solveSessionsTable)
          ..where((t) => t.completionType.isNotNull()))
        .join([
      innerJoin(
        puzzlesTable,
        puzzlesTable.id.equalsExp(solveSessionsTable.puzzleId),
      ),
    ]).get();

    final localRecords = rows.map((row) {
      final session = row.readTable(solveSessionsTable);
      final puzzle = row.readTable(puzzlesTable);
      return (
        completionType: session.completionType ?? 'clean',
        elapsedMs: session.elapsedMs,
        solvedDateLocal: session.solvedDateLocal ?? '',
        solvedTimezone: session.solvedTimezone,
        width: puzzle.width,
        height: puzzle.height,
        puzzleTitle: puzzle.title,
      );
    }).where((row) => row.solvedDateLocal.isNotEmpty);

    final importedRows = await select(importedSolveStatsTable).get();
    return [
      ...localRecords,
      ...importedRows.map(
        (row) => (
          completionType: row.completionType,
          elapsedMs: row.elapsedMs,
          solvedDateLocal: row.solvedDateLocal,
          solvedTimezone: row.solvedTimezone,
          width: row.width,
          height: row.height,
          puzzleTitle: row.puzzleTitle,
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Streak dates
  // ---------------------------------------------------------------------------

  /// Distinct [solvedDateLocal] values for streak-eligible completions
  /// (clean / checked / hinted — excludes 'revealed').
  ///
  /// Reads from [puzzleCompletionsTable] — the immutable per-completion
  /// history — so that "Reset puzzle" wiping the live `solve_sessions` row
  /// does not erase the original solve date from a user's streak.
  ///
  /// Returns strings in 'yyyy-MM-dd' format; nulls are filtered out in the
  /// repository before running the streak algorithm.
  Future<List<String?>> getStreakDates() async {
    final localDates = await (selectOnly(puzzleCompletionsTable)
          ..addColumns([puzzleCompletionsTable.solvedDateLocal])
          ..where(
            puzzleCompletionsTable.completionType.isNotValue('revealed'),
          ))
        .map((r) => r.read(puzzleCompletionsTable.solvedDateLocal))
        .get();
    final importedDates = await (selectOnly(importedSolveStatsTable)
          ..addColumns([importedSolveStatsTable.solvedDateLocal])
          ..where(
            importedSolveStatsTable.completionType.isNotValue('revealed'),
          ))
        .map((r) => r.read(importedSolveStatsTable.solvedDateLocal))
        .get();
    return [...localDates, ...importedDates];
  }

  // ---------------------------------------------------------------------------
  // Completion rate denominator
  // ---------------------------------------------------------------------------

  /// Total number of solve sessions ever started (for completion-rate stat).
  Future<int> countAllSessions() async {
    final count = solveSessionsTable.id.count();
    final q = selectOnly(solveSessionsTable)..addColumns([count]);
    final result = await q.getSingle();
    final importedCount = importedSolveStatsTable.id.count();
    final importedQ = selectOnly(importedSolveStatsTable)
      ..addColumns([importedCount]);
    final importedResult = await importedQ.getSingle();
    return (result.read(count) ?? 0) +
        (importedResult.read(importedCount) ?? 0);
  }

  Future<bool> hasCompletedRecord({
    required String puzzleTitle,
    required String solvedDateLocal,
  }) async {
    final localCount = solveSessionsTable.id.count();
    final local = await (selectOnly(solveSessionsTable)
          ..addColumns([localCount])
          ..join([
            innerJoin(
              puzzlesTable,
              puzzlesTable.id.equalsExp(solveSessionsTable.puzzleId),
            ),
          ])
          ..where(
            solveSessionsTable.completionType.isNotNull() &
                solveSessionsTable.solvedDateLocal.equals(solvedDateLocal) &
                puzzlesTable.title.equals(puzzleTitle),
          ))
        .getSingle();
    if ((local.read(localCount) ?? 0) > 0) return true;

    final importedCount = importedSolveStatsTable.id.count();
    final imported = await (selectOnly(importedSolveStatsTable)
          ..addColumns([importedCount])
          ..where(
            importedSolveStatsTable.puzzleTitle.equals(puzzleTitle) &
                importedSolveStatsTable.solvedDateLocal.equals(solvedDateLocal),
          ))
        .getSingle();
    return (imported.read(importedCount) ?? 0) > 0;
  }

  Future<void> insertImportedRecord(StatsExportRecord record) {
    final now = DateTime.now().toUtc();
    return into(importedSolveStatsTable).insert(
      ImportedSolveStatsTableCompanion.insert(
        completionType: record.completionType,
        elapsedMs: record.elapsedMs,
        solvedDateLocal: record.solvedDateLocal,
        solvedTimezone: Value(record.solvedTimezone),
        width: record.width,
        height: record.height,
        puzzleTitle: record.puzzleTitle,
        importedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}
