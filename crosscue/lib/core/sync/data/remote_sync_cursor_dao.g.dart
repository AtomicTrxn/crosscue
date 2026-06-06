// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_sync_cursor_dao.dart';

// ignore_for_file: type=lint
mixin _$RemoteSyncCursorDaoMixin on DatabaseAccessor<AppDatabase> {
  $RemoteSyncCursorsTableTable get remoteSyncCursorsTable =>
      attachedDatabase.remoteSyncCursorsTable;
  RemoteSyncCursorDaoManager get managers => RemoteSyncCursorDaoManager(this);
}

class RemoteSyncCursorDaoManager {
  final _$RemoteSyncCursorDaoMixin _db;
  RemoteSyncCursorDaoManager(this._db);
  $$RemoteSyncCursorsTableTableTableManager get remoteSyncCursorsTable =>
      $$RemoteSyncCursorsTableTableTableManager(
          _db.attachedDatabase, _db.remoteSyncCursorsTable);
}
