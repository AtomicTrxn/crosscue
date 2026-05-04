import 'package:drift/drift.dart';
import 'puzzles_table.dart';

@DataClassName('ClueRow')
class CluesTable extends Table {
  @override
  String get tableName => 'clues';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId =>
      text().references(PuzzlesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get direction => text()(); // 'across' or 'down'
  IntColumn get number => integer()();
  IntColumn get sortOrder => integer()();
  IntColumn get startRow => integer()();
  IntColumn get startCol => integer()();
  TextColumn get clueText => text().named('text')();
  IntColumn get answerLength => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {puzzleId, direction, number},
      ];
}
