import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
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

  /// Keys excluded from sync. Device-local identifiers, secrets, and any
  /// "set once per install" flags belong on the device, not in the cloud.
  ///
  /// The challenge_* keys are the Challenge Boards identity and submission
  /// queue (see `ChallengeIdentityStore` / `ChallengeResultOutbox`; literals
  /// duplicated here because core must not import feature code — a test
  /// cross-checks them). The server keeps a single auth token per player, so
  /// syncing it across devices both exposes a bearer secret to cloud storage
  /// and lets a stale copy clobber a freshly rotated token; a synced outbox
  /// would let another device re-submit pending results.
  static const Set<String> excludedKeys = {
    'device_id',
    'has_seen_onboarding',
    'challenge_player_id',
    'challenge_auth_token',
    'challenge_recovery_secret',
    'challenge_result_outbox_v1',
  };

  @override
  SyncNamespace get namespace => SyncNamespace.settings;

  @override
  Future<PushResult> push(
    SyncTransport transport,
    String deviceId, {
    Map<String, SyncManifestEntry>? remoteIndex,
  }) async {
    final all = await db.select(db.appSettingsTable).get();
    final localRows = all.where((r) => !excludedKeys.contains(r.key)).toList();
    if (localRows.isEmpty) return PushResult.zero;

    final written = <String, SyncManifestEntry>{};
    var pushed = 0;
    for (final row in localRows) {
      final key = keyFor(_encodeKey(row.key));

      // Cheap metadata check: trust the manifest's version for this key when
      // given, otherwise read the remote blob to learn it.
      final int? remoteVersion;
      if (remoteIndex != null) {
        remoteVersion = remoteIndex[key]?.syncVersion;
      } else {
        final existing = await transport.read(key);
        remoteVersion =
            existing == null ? null : SyncBlob.decode(existing)?.syncVersion;
      }

      if (remoteVersion != null && remoteVersion >= row.syncVersion) {
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
      written[key] = manifestEntryFor(blob);
      pushed++;

      await (db.update(db.appSettingsTable)
            ..where((t) => t.key.equals(row.key)))
          .write(
        AppSettingsTableCompanion(
          syncVersion: Value(row.syncVersion + 1),
        ),
      );
    }
    return PushResult(
      outcome: NamespaceSyncOutcome(pushed: pushed),
      written: written,
    );
  }

  @override
  Future<PullResult> pull(
    SyncTransport transport, {
    Iterable<String>? onlyKeys,
  }) async {
    final remoteKeys = onlyKeys ?? await transport.list(namespace.prefix);

    final seen = <String, SyncManifestEntry>{};
    final caughtUp = <String, SyncManifestEntry>{};
    var pulled = 0;
    var conflicts = 0;
    for (final transportKey in remoteKeys) {
      final encodedKey = idFromKey(transportKey);
      if (encodedKey == null) continue;

      final bytes = await transport.read(transportKey);
      if (bytes == null) continue;
      final blob = SyncBlob.decode(bytes);
      if (blob == null) continue;

      final entry = manifestEntryFor(blob);
      seen[transportKey] = entry;

      final settingKey = blob.payload['key'];
      final valueJson = blob.payload['valueJson'];
      if (settingKey is! String || valueJson is! String) {
        // Malformed blob — we've seen it; don't re-read it.
        caughtUp[transportKey] = entry;
        continue;
      }
      if (excludedKeys.contains(settingKey)) {
        // Device-local key that an older app version uploaded. Remove the
        // cloud copy (it may hold a secret); on failure leave it out of
        // caughtUp so the next pass retries the delete.
        try {
          await transport.delete(transportKey);
          seen.remove(transportKey);
        } on Exception {
          // Retried next pass.
        }
        continue;
      }

      final local = await (db.select(db.appSettingsTable)
            ..where((t) => t.key.equals(settingKey)))
          .getSingleOrNull();

      if (local != null) {
        if (_isIdempotentReapply(local, blob, valueJson)) {
          caughtUp[transportKey] = entry;
          continue;
        }
        if (!_shouldTakeRemote(local, blob)) {
          conflicts++;
          caughtUp[transportKey] = entry;
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
      caughtUp[transportKey] = entry;
    }
    return PullResult(
      outcome: NamespaceSyncOutcome(pulled: pulled, conflicts: conflicts),
      seen: seen,
      caughtUp: caughtUp,
    );
  }

  /// Setting keys can contain characters (like `.`) that are awkward in
  /// blob keys; URL-encode to keep transports happy.
  String _encodeKey(String key) => Uri.encodeComponent(key);

  bool _isIdempotentReapply(
    AppSettingRow local,
    SyncBlob remote,
    String valueJson,
  ) {
    return local.syncVersion == remote.syncVersion &&
        local.updatedAt.isAtSameMomentAs(remote.updatedAt) &&
        local.valueJson == valueJson;
  }

  bool _shouldTakeRemote(AppSettingRow local, SyncBlob remote) {
    if (local.syncVersion > remote.syncVersion) return false;
    if (local.syncVersion < remote.syncVersion) {
      if (local.updatedAt.isAfter(remote.updatedAt)) return false;
      if (local.updatedAt.isBefore(remote.updatedAt)) return true;
      return remote.deviceId.compareTo('local') > 0;
    }

    if (remote.updatedAt.isAfter(local.updatedAt)) return true;
    if (remote.updatedAt.isBefore(local.updatedAt)) return false;
    return remote.deviceId.compareTo('local') > 0;
  }
}
