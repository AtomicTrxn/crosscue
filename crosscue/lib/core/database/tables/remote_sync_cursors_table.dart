import 'package:drift/drift.dart';

/// Local cache of the last remote metadata observed per sync blob.
///
/// This is device-local operational metadata. It is intentionally kept out of
/// `app_settings`, because settings are partly user-facing and syncable.
@DataClassName('RemoteSyncCursorRow')
class RemoteSyncCursorsTable extends Table {
  @override
  String get tableName => 'remote_sync_cursors';

  TextColumn get namespace => text()();
  TextColumn get syncKey => text().named('sync_key')();
  IntColumn get syncVersion => integer().named('sync_version')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  TextColumn get deviceId => text().named('device_id')();
  TextColumn get transportToken => text().named('transport_token').nullable()();
  DateTimeColumn get lastSeenAt => dateTime().named('last_seen_at')();

  @override
  Set<Column> get primaryKey => {namespace, syncKey};
}
