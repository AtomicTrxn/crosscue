import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:drift/drift.dart';

/// Settings are keyed by string. Merge rule: LWW per key by `updatedAt`,
/// with `(updatedAt, deviceId)` as tiebreak.
///
/// `device_id` itself is intentionally excluded — it's device-local and
/// must never be synced.
class SettingsSyncAdapter extends NamespaceSyncAdapter {
  SettingsSyncAdapter(this.db);

  final AppDatabase db;

  /// Keys excluded from sync. Device-local identifiers and any "set once
  /// per install" flags belong on the device, not in the cloud.
  static const Set<String> excludedKeys = {
    'device_id',
    'has_seen_onboarding',
    'notifications_last_scheduled_at',
  };

  @override
  SyncNamespace get namespace => SyncNamespace.settings;

  @override
  Future<NamespaceSyncOutcome> push(
    SyncTransport transport,
    String deviceId,
  ) async {
    final all = await db.select(db.appSettingsTable).get();
    final localRows = all
        .where((r) => !excludedKeys.contains(r.key))
        .toList();
    if (localRows.isEmpty) return NamespaceSyncOutcome.zero;

    var pushed = 0;
    for (final row in localRows) {
      final key = keyFor(_encodeKey(row.key));
      final existing = await transport.read(key);
      final remote = existing == null ? null : SyncBlob.decode(existing);

      if (remote != null && remote.syncVersion >= row.syncVersion) {
        // Remote already at-or-above our version — nothing to push.
        continue;
      }

      final blob = SyncBlob(
        schemaVersion: SyncBlob.currentSchemaVersion,
        deviceId: deviceId,
        syncVersion: row.syncVersion + 1,
        updatedAt: row.updatedAt,
        payload: <String, Object?>{
          'key': row.key,
          'valueJson': row.valueJson,
        },
      );
      await transport.write(key, blob.encode());
      pushed++;

      await (db.update(db.appSettingsTable)
            ..where((t) => t.key.equals(row.key)))
          .write(
        AppSettingsTableCompanion(
          syncVersion: Value(row.syncVersion + 1),
        ),
      );
    }
    return NamespaceSyncOutcome(pushed: pushed);
  }

  @override
  Future<NamespaceSyncOutcome> pull(SyncTransport transport) async {
    final remoteKeys = await transport.list(namespace.prefix);
    if (remoteKeys.isEmpty) return NamespaceSyncOutcome.zero;

    var pulled = 0;
    var conflicts = 0;
    for (final transportKey in remoteKeys) {
      final encodedKey = idFromKey(transportKey);
      if (encodedKey == null) continue;

      final bytes = await transport.read(transportKey);
      if (bytes == null) continue;
      final blob = SyncBlob.decode(bytes);
      if (blob == null) continue;

      final settingKey = blob.payload['key'];
      final valueJson = blob.payload['valueJson'];
      if (settingKey is! String ||
          valueJson is! String ||
          excludedKeys.contains(settingKey)) {
        continue;
      }

      final local = await (db.select(db.appSettingsTable)
            ..where((t) => t.key.equals(settingKey)))
          .getSingleOrNull();

      if (local != null) {
        if (local.syncVersion >= blob.syncVersion) continue;
        if (local.updatedAt.isAfter(blob.updatedAt)) {
          conflicts++;
          continue;
        }
      }

      await db.into(db.appSettingsTable).insertOnConflictUpdate(
            AppSettingsTableCompanion.insert(
              key: settingKey,
              valueJson: valueJson,
              updatedAt: blob.updatedAt,
              syncVersion: Value(blob.syncVersion),
            ),
          );
      pulled++;
    }
    return NamespaceSyncOutcome(pulled: pulled, conflicts: conflicts);
  }

  /// Setting keys can contain characters (like `.`) that are awkward in
  /// blob keys; URL-encode to keep transports happy.
  String _encodeKey(String key) => Uri.encodeComponent(key);
}
