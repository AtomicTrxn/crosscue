import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/database/tables/remote_sync_cursors_table.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:drift/drift.dart';

part 'remote_sync_cursor_dao.g.dart';

@DriftAccessor(tables: [RemoteSyncCursorsTable])
class RemoteSyncCursorDao extends DatabaseAccessor<AppDatabase>
    with _$RemoteSyncCursorDaoMixin {
  RemoteSyncCursorDao(super.db);

  Future<RemoteSyncCursorRow?> getCursor(
    SyncNamespace namespace,
    String syncKey,
  ) {
    return (select(remoteSyncCursorsTable)
          ..where((t) => t.namespace.equals(namespace.name))
          ..where((t) => t.syncKey.equals(syncKey)))
        .getSingleOrNull();
  }

  Future<List<RemoteSyncCursorRow>> getNamespaceCursors(
    SyncNamespace namespace,
  ) {
    return (select(remoteSyncCursorsTable)
          ..where((t) => t.namespace.equals(namespace.name)))
        .get();
  }

  Future<void> upsertCursor({
    required SyncNamespace namespace,
    required String syncKey,
    required SyncManifestEntry metadata,
    String? transportToken,
    DateTime? lastSeenAt,
  }) {
    return into(remoteSyncCursorsTable).insertOnConflictUpdate(
      RemoteSyncCursorsTableCompanion.insert(
        namespace: namespace.name,
        syncKey: syncKey,
        syncVersion: metadata.syncVersion,
        updatedAt: metadata.updatedAt.toUtc(),
        deviceId: metadata.deviceId,
        transportToken: Value(transportToken),
        lastSeenAt: lastSeenAt?.toUtc() ?? DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> deleteCursor(SyncNamespace namespace, String syncKey) {
    return (delete(remoteSyncCursorsTable)
          ..where((t) => t.namespace.equals(namespace.name))
          ..where((t) => t.syncKey.equals(syncKey)))
        .go();
  }

  Future<void> clearAll() => delete(remoteSyncCursorsTable).go();
}
