// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_dao.dart';

// ignore_for_file: type=lint
mixin _$StatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SourcesTableTable get sourcesTable => attachedDatabase.sourcesTable;
  $PuzzlesTableTable get puzzlesTable => attachedDatabase.puzzlesTable;
  $SolveSessionsTableTable get solveSessionsTable =>
      attachedDatabase.solveSessionsTable;
  StatsDaoManager get managers => StatsDaoManager(this);
}

class StatsDaoManager {
  final _$StatsDaoMixin _db;
  StatsDaoManager(this._db);
  $$SourcesTableTableTableManager get sourcesTable =>
      $$SourcesTableTableTableManager(_db.attachedDatabase, _db.sourcesTable);
  $$PuzzlesTableTableTableManager get puzzlesTable =>
      $$PuzzlesTableTableTableManager(_db.attachedDatabase, _db.puzzlesTable);
  $$SolveSessionsTableTableTableManager get solveSessionsTable =>
      $$SolveSessionsTableTableTableManager(
          _db.attachedDatabase, _db.solveSessionsTable);
}
