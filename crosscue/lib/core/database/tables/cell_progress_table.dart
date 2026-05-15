import 'package:crosscue/core/database/tables/solve_sessions_table.dart';
import 'package:drift/drift.dart';

@DataClassName('CellProgressRow')
class CellProgressTable extends Table {
  @override
  String get tableName => 'cell_progress';

  IntColumn get sessionId => integer()
      .references(SolveSessionsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get row => integer()();
  IntColumn get col => integer()();
  TextColumn get guess => text().nullable()();

  /// CellState as string: empty | filled | checkedCorrect | checkedIncorrect | revealed
  TextColumn get state => text().withDefault(const Constant('empty'))();
  BoolColumn get wasChecked => boolean().withDefault(const Constant(false))();
  BoolColumn get wasRevealed => boolean().withDefault(const Constant(false))();

  /// Hash of the last wrong guess to avoid double-counting mistakes.
  TextColumn get lastWrongGuessHash => text().nullable()();

  /// Reserved for a future pencil-mode feature — present in the schema now so
  /// adding the feature later does not require a migration.
  BoolColumn get isPencil => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId, row, col};
}
