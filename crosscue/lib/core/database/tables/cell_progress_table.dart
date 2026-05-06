import 'package:drift/drift.dart';
import 'solve_sessions_table.dart';

@DataClassName('CellProgressRow')
class CellProgressTable extends Table {
  @override
  String get tableName => 'cell_progress';

  IntColumn get sessionId =>
      integer().references(SolveSessionsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get row => integer()();
  IntColumn get col => integer()();
  TextColumn get guess => text().nullable()();

  /// CellState as string: empty | filled | checkedCorrect | checkedIncorrect | revealed
  TextColumn get state => text().withDefault(const Constant('empty'))();
  BoolColumn get wasChecked => boolean().withDefault(const Constant(false))();
  BoolColumn get wasRevealed => boolean().withDefault(const Constant(false))();

  /// Hash of the last wrong guess to avoid double-counting mistakes (topic-11).
  TextColumn get lastWrongGuessHash => text().nullable()();

  /// isPencil stored for post-MVP pencil mode without requiring a migration.
  BoolColumn get isPencil => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId, row, col};
}
