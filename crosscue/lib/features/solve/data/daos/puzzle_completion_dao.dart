import 'package:crosscue/core/constants/retention.dart';
import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/database/tables/puzzle_completions_table.dart';
import 'package:crosscue/core/utils/uuid.dart';
import 'package:drift/drift.dart';

part 'puzzle_completion_dao.g.dart';

/// DAO for [PuzzleCompletionsTable].
///
/// All writes go through [recordCompletion], which inserts a row and then
/// prunes older rows for the same puzzle to bound storage growth.
@DriftAccessor(tables: [PuzzleCompletionsTable])
class PuzzleCompletionDao extends DatabaseAccessor<AppDatabase>
    with _$PuzzleCompletionDaoMixin {
  PuzzleCompletionDao(super.db);

  /// Inserts a completion row and prunes older rows for [puzzleId] so that
  /// at most [CrosscueRetention.completionsPerPuzzle] rows remain. Pruning
  /// keeps the earliest completion, the fastest completion, and the most
  /// recent rows (oldest extras dropped first).
  Future<int> recordCompletion({
    required String puzzleId,
    required String completionType,
    required DateTime completedAt,
    required String solvedDateLocal,
    String? solvedTimezone,
    required int elapsedMs,
    int checkCount = 0,
    int revealCount = 0,
    String? clientUuid,
    String deviceId = 'local',
  }) async {
    return transaction(() async {
      final id = await into(puzzleCompletionsTable).insert(
        PuzzleCompletionsTableCompanion.insert(
          puzzleId: puzzleId,
          completionType: completionType,
          completedAt: completedAt,
          solvedDateLocal: solvedDateLocal,
          solvedTimezone: Value(solvedTimezone),
          elapsedMs: elapsedMs,
          checkCount: Value(checkCount),
          revealCount: Value(revealCount),
          clientUuid: clientUuid ?? Uuid.v4(),
          deviceId: Value(deviceId),
        ),
      );
      await _pruneForPuzzle(puzzleId);
      return id;
    });
  }

  /// Distinct [solvedDateLocal] values for streak-eligible completions
  /// (clean / checked / hinted — excludes 'revealed'). Matches the historical
  /// behavior of the [SolveSessionsTable]-based query.
  ///
  /// `solvedDateLocal` is non-nullable on this table, so callers don't need
  /// to filter for nulls. Returned as nullable strings for symmetry with the
  /// previous API consumed by [StatsDao.getStreakDates].
  Future<List<String?>> getStreakDates() async {
    final dates = await (selectOnly(puzzleCompletionsTable, distinct: true)
          ..addColumns([puzzleCompletionsTable.solvedDateLocal])
          ..where(
            puzzleCompletionsTable.completionType.isNotValue('revealed'),
          ))
        .map((r) => r.read(puzzleCompletionsTable.solvedDateLocal))
        .get();
    return dates;
  }

  /// Returns all completion rows for [puzzleId] in insertion order. Test /
  /// debug helper.
  Future<List<PuzzleCompletionRow>> rowsForPuzzle(String puzzleId) =>
      (select(puzzleCompletionsTable)
            ..where((t) => t.puzzleId.equals(puzzleId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<void> _pruneForPuzzle(String puzzleId) async {
    const cap = CrosscueRetention.completionsPerPuzzle;
    final rows = await (select(puzzleCompletionsTable)
          ..where((t) => t.puzzleId.equals(puzzleId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    if (rows.length <= cap) return;

    // Always keep:
    //   * earliest (rows.first — ordered ascending by id),
    //   * fastest (min elapsedMs),
    //   * most recent (cap - keepers) rows.
    final keep = <int>{};
    keep.add(rows.first.id);
    final fastest = rows.reduce(
      (a, b) => a.elapsedMs <= b.elapsedMs ? a : b,
    );
    keep.add(fastest.id);

    // Walk from newest backward, adding ids until we hit the cap.
    for (final row in rows.reversed) {
      if (keep.length >= cap) break;
      keep.add(row.id);
    }

    final toDelete =
        rows.where((r) => !keep.contains(r.id)).map((r) => r.id).toList();
    if (toDelete.isEmpty) return;

    await (delete(puzzleCompletionsTable)..where((t) => t.id.isIn(toDelete)))
        .go();
  }
}
