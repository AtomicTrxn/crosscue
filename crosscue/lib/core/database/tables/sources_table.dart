import 'package:drift/drift.dart';

class SourcesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get url => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get sourceType => text()(); // From SourceType enum
}
