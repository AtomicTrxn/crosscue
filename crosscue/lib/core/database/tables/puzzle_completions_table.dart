import 'package:crosscue/core/database/tables/puzzles_table.dart';
import 'package:drift/drift.dart';

/// Immutable per-completion record. One row is written every time a puzzle
/// reaches a terminal state (solved / solved-with-help / solved-with-reveal /
/// revealed). Rows are never mutated and are only deleted by:
///
/// 1. Pruning (see [PuzzleCompletionDao.recordCompletion] — bounds rows per
///    puzzle while preserving first + best).
/// 2. The user's privacy "Clear all data" action.
/// 3. Cascade delete when the underlying puzzle is removed.
///
/// This is the source of truth for streak history and future leaderboard
/// features. The live `solve_sessions` row is allowed to be wiped by
/// "Reset puzzle" without losing the record of the original completion.
@DataClassName('PuzzleCompletionRow')
class PuzzleCompletionsTable extends Table {
  @override
  String get tableName => 'puzzle_completions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId =>
      text().references(PuzzlesTable, #id, onDelete: KeyAction.cascade)();

  /// DB values: clean | checked | hinted | revealed
  TextColumn get completionType => text()();

  DateTimeColumn get completedAt => dateTime()();

  /// Calendar date string in device-local timezone: 'yyyy-MM-dd'.
  TextColumn get solvedDateLocal => text()();
  TextColumn get solvedTimezone => text().nullable()();

  IntColumn get elapsedMs => integer()();
  IntColumn get checkCount => integer().withDefault(const Constant(0))();
  IntColumn get revealCount => integer().withDefault(const Constant(0))();

  /// UUID v4 generated at insert. Acts as the dedupe key when merging
  /// completion history across devices — every row is content-stable and
  /// append-only, so set-union by [clientUuid] is conflict-free.
  TextColumn get clientUuid => text()();

  /// Originating device id (mirror of `app_settings.device_id` at insert
  /// time). Provenance + LWW tiebreaks elsewhere.
  TextColumn get deviceId => text().withDefault(const Constant('local'))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {clientUuid},
      ];
}
