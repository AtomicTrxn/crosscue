import 'package:drift/drift.dart';
import 'puzzles_table.dart';

/// TypeConverter: PuzzleStatus domain enum ↔ DB status string.
/// DB values: not_started | in_progress | completed | revealed
class SessionStatusConverter extends TypeConverter<String, String> {
  const SessionStatusConverter();

  @override
  String fromSql(String fromDb) => fromDb;

  @override
  String toSql(String value) => value;
}

@DataClassName('SolveSessionRow')
class SolveSessionsTable extends Table {
  @override
  String get tableName => 'solve_sessions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId =>
      text().references(PuzzlesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get deviceId => text()();

  /// DB values: not_started | in_progress | completed | revealed
  TextColumn get status =>
      text().withDefault(const Constant('not_started'))();

  /// DB values: clean | checked | hinted | revealed (only set when completed)
  TextColumn get completionType => text().nullable()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get lastPlayedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Calendar date string in device-local timezone: 'yyyy-MM-dd'.
  /// Used by streak algorithm (see topic-15).
  TextColumn get solvedDateLocal => text().nullable()();
  TextColumn get solvedTimezone => text().nullable()();

  IntColumn get elapsedMs => integer().withDefault(const Constant(0))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  IntColumn get totalPausedMs => integer().withDefault(const Constant(0))();

  IntColumn get mistakeCount => integer().withDefault(const Constant(0))();
  IntColumn get checkCount => integer().withDefault(const Constant(0))();
  IntColumn get revealCount => integer().withDefault(const Constant(0))();
  BoolColumn get usedCheck => boolean().withDefault(const Constant(false))();
  BoolColumn get usedReveal => boolean().withDefault(const Constant(false))();
  BoolColumn get cleanSolveEligible =>
      boolean().withDefault(const Constant(true))();

  IntColumn get focusRow => integer().withDefault(const Constant(0))();
  IntColumn get focusCol => integer().withDefault(const Constant(0))();
  TextColumn get direction =>
      text().withDefault(const Constant('across'))();

  // Sync-readiness columns (topic-09) — NoOpSyncAdapter in Phase 1
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
