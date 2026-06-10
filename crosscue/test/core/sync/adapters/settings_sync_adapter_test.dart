import 'package:crosscue/core/sync/adapters/settings_sync_adapter.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_result_outbox.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_adapter_test_helpers.dart';

void main() {
  group('SettingsSyncAdapter', () {
    test('concurrent edits to different keys merge losslessly', () async {
      final cloud = <String, String>{};
      final dbA = newTestDb();
      final dbB = newTestDb();
      addTearDown(dbA.close);
      addTearDown(dbB.close);
      final adapterA = SettingsSyncAdapter(dbA);
      final adapterB = SettingsSyncAdapter(dbB);

      await insertSetting(dbA, key: 'haptics_enabled', valueJson: 'true');
      await insertSetting(dbB, key: 'sound_enabled', valueJson: 'false');

      await adapterA.push(FakeSyncTransport(store: cloud), deviceA);
      await adapterB.push(FakeSyncTransport(store: cloud), deviceB);
      await adapterA.pull(FakeSyncTransport(store: cloud));
      await adapterB.pull(FakeSyncTransport(store: cloud));

      final rowsA = {
        for (final row in await dbA.select(dbA.appSettingsTable).get())
          row.key: row.valueJson,
      };
      final rowsB = {
        for (final row in await dbB.select(dbB.appSettingsTable).get())
          row.key: row.valueJson,
      };
      expect(rowsA['haptics_enabled'], 'true');
      expect(rowsA['sound_enabled'], 'false');
      expect(rowsB['haptics_enabled'], 'true');
      expect(rowsB['sound_enabled'], 'false');
    });

    test('same-version equal-updatedAt tie-break is deterministic', () async {
      final cloud = <String, String>{
        'settings/theme_mode.json': encodedBlob(
          deviceId: 'z-device',
          syncVersion: 1,
          updatedAt: t1,
          payload: const {
            'key': 'theme_mode',
            'valueJson': '"dark"',
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertSetting(
        db,
        key: 'theme_mode',
        valueJson: '"light"',
        updatedAt: t1,
        syncVersion: 1,
      );

      final outcome = await SettingsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 1);
      final row = (await db.select(db.appSettingsTable).get()).single;
      expect(row.valueJson, '"dark"');
    });

    test('re-applying the same setting blob is a no-op', () async {
      final cloud = <String, String>{
        'settings/theme_mode.json': encodedBlob(
          deviceId: 'z-device',
          syncVersion: 1,
          updatedAt: t1,
          payload: const {
            'key': 'theme_mode',
            'valueJson': '"dark"',
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      final adapter = SettingsSyncAdapter(db);

      expect((await adapter.pull(FakeSyncTransport(store: cloud))).pulled, 1);
      expect((await adapter.pull(FakeSyncTransport(store: cloud))).pulled, 0);
      expect(await db.select(db.appSettingsTable).get(), hasLength(1));
    });

    test('excluded keys are not pushed or pulled', () async {
      final cloud = <String, String>{
        'settings/device_id.json': encodedBlob(
          deviceId: deviceA,
          syncVersion: 1,
          updatedAt: t1,
          payload: const {
            'key': 'device_id',
            'valueJson': '"remote"',
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertSetting(db, key: 'has_seen_onboarding', valueJson: 'true');
      final adapter = SettingsSyncAdapter(db);

      expect(
        (await adapter.push(FakeSyncTransport(store: cloud), deviceA)).pushed,
        0,
      );
      expect((await adapter.pull(FakeSyncTransport(store: cloud))).pulled, 0);
      expect(
        (await db.select(db.appSettingsTable).get()).map((r) => r.key),
        ['has_seen_onboarding'],
      );
    });

    test('challenge identity and outbox keys never leave the device', () async {
      // The exclusion list duplicates the feature-owned key literals because
      // core must not import feature code; this pins them together.
      expect(
        SettingsSyncAdapter.excludedKeys,
        containsAll(<String>{
          ChallengeIdentityStore.playerIdKey,
          ChallengeIdentityStore.authTokenKey,
          ChallengeIdentityStore.recoverySecretKey,
          ChallengeResultOutbox.storageKey,
        }),
      );

      final cloud = <String, String>{};
      final db = newTestDb();
      addTearDown(db.close);
      await insertSetting(
        db,
        key: ChallengeIdentityStore.authTokenKey,
        valueJson: '"secret-token"',
      );
      await insertSetting(db, key: 'haptics_enabled', valueJson: 'true');

      final pushed = await SettingsSyncAdapter(db)
          .push(FakeSyncTransport(store: cloud), deviceA);

      expect(pushed.pushed, 1);
      expect(cloud.keys, ['settings/haptics_enabled.json']);
      expect(cloud.values.single, isNot(contains('secret-token')));
    });

    test('excluded blobs uploaded by older versions are deleted on pull',
        () async {
      final cloud = <String, String>{
        'settings/challenge_auth_token.json': encodedBlob(
          deviceId: deviceA,
          syncVersion: 1,
          updatedAt: t1,
          payload: {
            'key': ChallengeIdentityStore.authTokenKey,
            'valueJson': '"stale-cloud-token"',
          },
        ),
        'settings/theme_mode.json': encodedBlob(
          deviceId: deviceA,
          syncVersion: 1,
          updatedAt: t1,
          payload: const {
            'key': 'theme_mode',
            'valueJson': '"dark"',
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);

      final outcome = await SettingsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      // The secret blob is gone from the cloud, was not applied locally, and
      // is absent from the manifest maps; the normal setting still syncs.
      expect(outcome.pulled, 1);
      expect(cloud.keys, ['settings/theme_mode.json']);
      expect(outcome.seen.keys, ['settings/theme_mode.json']);
      expect(outcome.caughtUp.keys, ['settings/theme_mode.json']);
      expect(
        (await db.select(db.appSettingsTable).get()).map((r) => r.key),
        ['theme_mode'],
      );
    });

    test('newer schema blobs are skipped without crashing', () async {
      final cloud = <String, String>{
        'settings/theme_mode.json': encodedBlob(
          schemaVersion: 999,
          deviceId: deviceA,
          syncVersion: 1,
          updatedAt: t1,
          payload: const {
            'key': 'theme_mode',
            'valueJson': '"dark"',
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);

      final outcome = await SettingsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      expect(await db.select(db.appSettingsTable).get(), isEmpty);
    });
  });
}
