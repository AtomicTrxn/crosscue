// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puzzle_completion_dao.dart';

// ignore_for_file: type=lint
mixin _$PuzzleCompletionDaoMixin on DatabaseAccessor<AppDatabase> {
  $SourcesTableTable get sourcesTable => attachedDatabase.sourcesTable;
  $PuzzlesTableTable get puzzlesTable => attachedDatabase.puzzlesTable;
  $PuzzleCompletionsTableTable get puzzleCompletionsTable =>
      attachedDatabase.puzzleCompletionsTable;
  PuzzleCompletionDaoManager get managers => PuzzleCompletionDaoManager(this);
}

class PuzzleCompletionDaoManager {
  final _$PuzzleCompletionDaoMixin _db;
  PuzzleCompletionDaoManager(this._db);
  $$SourcesTableTableTableManager get sourcesTable =>
      $$SourcesTableTableTableManager(_db.attachedDatabase, _db.sourcesTable);
  $$PuzzlesTableTableTableManager get puzzlesTable =>
      $$PuzzlesTableTableTableManager(_db.attachedDatabase, _db.puzzlesTable);
  $$PuzzleCompletionsTableTableTableManager get puzzleCompletionsTable =>
      $$PuzzleCompletionsTableTableTableManager(
          _db.attachedDatabase, _db.puzzleCompletionsTable);
}
