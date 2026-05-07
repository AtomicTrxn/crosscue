import 'package:drift/drift.dart';

@DataClassName('ImportedSolveStatRow')
class ImportedSolveStatsTable extends Table {
  @override
  String get tableName => 'imported_solve_stats';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get completionType => text()();
  IntColumn get elapsedMs => integer()();
  TextColumn get solvedDateLocal => text()();
  TextColumn get solvedTimezone => text().nullable()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  TextColumn get puzzleTitle => text()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {puzzleTitle, solvedDateLocal},
      ];
}
