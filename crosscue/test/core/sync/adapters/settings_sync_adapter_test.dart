import 'package:crosscue/core/sync/adapters/settings_sync_adapter.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
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
