// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_session_dao.dart';

// ignore_for_file: type=lint
mixin _$SolveSessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $SourcesTableTable get sourcesTable => attachedDatabase.sourcesTable;
  $PuzzlesTableTable get puzzlesTable => attachedDatabase.puzzlesTable;
  $SolveSessionsTableTable get solveSessionsTable =>
      attachedDatabase.solveSessionsTable;
  $CellProgressTableTable get cellProgressTable =>
      attachedDatabase.cellProgressTable;
  SolveSessionDaoManager get managers => SolveSessionDaoManager(this);
}

class SolveSessionDaoManager {
  final _$SolveSessionDaoMixin _db;
  SolveSessionDaoManager(this._db);
  $$SourcesTableTableTableManager get sourcesTable =>
      $$SourcesTableTableTableManager(_db.attachedDatabase, _db.sourcesTable);
  $$PuzzlesTableTableTableManager get puzzlesTable =>
      $$PuzzlesTableTableTableManager(_db.attachedDatabase, _db.puzzlesTable);
  $$SolveSessionsTableTableTableManager get solveSessionsTable =>
      $$SolveSessionsTableTableTableManager(
          _db.attachedDatabase, _db.solveSessionsTable);
  $$CellProgressTableTableTableManager get cellProgressTable =>
      $$CellProgressTableTableTableManager(
          _db.attachedDatabase, _db.cellProgressTable);
}
