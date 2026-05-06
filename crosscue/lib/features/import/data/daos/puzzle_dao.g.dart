// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puzzle_dao.dart';

// ignore_for_file: type=lint
mixin _$PuzzleDaoMixin on DatabaseAccessor<AppDatabase> {
  $SourcesTableTable get sourcesTable => attachedDatabase.sourcesTable;
  $PuzzlesTableTable get puzzlesTable => attachedDatabase.puzzlesTable;
  $CluesTableTable get cluesTable => attachedDatabase.cluesTable;
  PuzzleDaoManager get managers => PuzzleDaoManager(this);
}

class PuzzleDaoManager {
  final _$PuzzleDaoMixin _db;
  PuzzleDaoManager(this._db);
  $$SourcesTableTableTableManager get sourcesTable =>
      $$SourcesTableTableTableManager(_db.attachedDatabase, _db.sourcesTable);
  $$PuzzlesTableTableTableManager get puzzlesTable =>
      $$PuzzlesTableTableTableManager(_db.attachedDatabase, _db.puzzlesTable);
  $$CluesTableTableTableManager get cluesTable =>
      $$CluesTableTableTableManager(_db.attachedDatabase, _db.cluesTable);
}
