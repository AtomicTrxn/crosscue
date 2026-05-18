import 'package:crosscue/core/database/tables/sources_table.dart';
import 'package:drift/drift.dart';

@DataClassName('PuzzleRow')
class PuzzlesTable extends Table {
  @override
  String get tableName => 'puzzles';

  TextColumn get id =>
      text()(); // 'source_id:source_puzzle_id' or checksum for local imports
  TextColumn get sourceId =>
      text().references(SourcesTable, #id, onDelete: KeyAction.restrict)();
  TextColumn get sourcePuzzleId => text().nullable()();
  TextColumn get format => text()(); // PuzzleFormat enum as string
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get editor => text().nullable()();
  TextColumn get publisher => text().nullable()();
  TextColumn get copyright => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get publishDate => dateTime().nullable()();
  TextColumn get difficulty => text().nullable()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  TextColumn get checksum => text()(); // SHA-256 of canonical content
  TextColumn get canonicalJson => text()(); // Full puzzle as ipuz-style JSON
  TextColumn get rawPayload =>
      text().nullable()(); // Original file bytes (if retained)
  DateTimeColumn get fetchedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Sync-readiness columns — populated by SyncOrchestrator.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {sourceId, sourcePuzzleId},
      ];
}
