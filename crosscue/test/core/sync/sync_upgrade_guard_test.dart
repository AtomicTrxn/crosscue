// ADR-0016 mixed-version guard tests (#258). When a remote blob carries an
// envelope schemaVersion newer than this build understands, the orchestrator
// must suspend PUSHES to that namespace (so a stale device can't fork
// last-writer-wins data), keep pulling everything else, persist the
// suspension across restarts, surface it on SyncIdle, and clear it
// automatically once the app updates past the observed schema.

import 'dart:convert';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/sync/sync_orchestrator.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> cloud;
  late AppDatabase db;
  late SyncOrchestrator orchestrator;

  setUp(() async {
    cloud = <String, String>{};
    db = AppDatabase.forTesting(NativeDatabase.memory());
    orchestrator = SyncOrchestrator(
      transport: FakeSyncTransport(store: cloud),
      db: db,
    );
    await orchestrator.enable();
  });

  tearDown(() async {
    await orchestrator.dispose();
    await db.close();
  });

  Future<void> insertPuzzleWithSession(String id) async {
    final now = DateTime.now().toUtc();
    await db.into(db.puzzlesTable).insert(
          PuzzlesTableCompanion.insert(
            id: id,
            sourceId: 'local_import',
            format: 'ipuz',
            title: 'Puzzle $id',
            width: 5,
            height: 5,
            checksum: 'cksum-$id',
            canonicalJson: '{"w":5,"h":5}',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db.into(db.solveSessionsTable).insert(
          SolveSessionsTableCompanion.insert(
            puzzleId: id,
            deviceId: 'device-test',
            startedAt: now,
            lastPlayedAt: now,
            createdAt: now,
            updatedAt: now,
            status: const Value('in_progress'),
          ),
        );
  }

  /// A structurally valid envelope written by a hypothetical future app.
  String futureSchemaBlob({int schemaVersion = 2}) => jsonEncode({
        'schemaVersion': schemaVersion,
        'deviceId': 'future-device',
        'syncVersion': 7,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'payload': <String, Object?>{'shape': 'from-the-future'},
      });

  test(
      'newer-schema blob suspends pushes to its namespace only; '
      'others keep syncing and the state surfaces the suspension', () async {
    cloud['sessions/future-entity.json'] = futureSchemaBlob();
    await insertPuzzleWithSession('puz-1');

    await orchestrator.syncNow();

    // Puzzles still pushed; sessions push suppressed.
    expect(cloud.keys.where((k) => k.startsWith('puzzles/')), isNotEmpty);
    expect(
      cloud.keys.where((k) => k.startsWith('sessions/')),
      ['sessions/future-entity.json'],
      reason: 'the stale device must not write into a newer-schema namespace',
    );

    final state = orchestrator.currentState;
    expect(state, isA<SyncIdle>());
    expect(
      (state as SyncIdle).upgradeRequired,
      {SyncNamespace.sessions},
    );

    // Suspension record persisted (and would never sync: the key is in
    // SettingsSyncAdapter.excludedKeys).
    final raw =
        await db.appSettingsDao.getValue(SyncOrchestrator.upgradeGuardKey);
    expect(raw, isNotNull);
    final record = jsonDecode(raw!) as Map<String, Object?>;
    expect(record['schemaVersion'], 2);
    expect(record['namespaces'], ['sessions']);
  });

  test('suspension survives a restart and keeps suppressing pushes', () async {
    cloud['sessions/future-entity.json'] = futureSchemaBlob();
    await insertPuzzleWithSession('puz-1');
    await orchestrator.syncNow();

    // Simulate an app restart: new orchestrator, same database. Even with
    // the future blob gone from the cloud, the persisted record governs.
    cloud.remove('sessions/future-entity.json');
    final restarted = SyncOrchestrator(
      transport: FakeSyncTransport(store: cloud),
      db: db,
    );
    addTearDown(restarted.dispose);

    await restarted.enable();
    expect(
      (restarted.currentState as SyncIdle).upgradeRequired,
      {SyncNamespace.sessions},
      reason: 'the notice must show at boot, before any sync pass',
    );

    await restarted.syncNow();
    expect(
      cloud.keys.where((k) => k.startsWith('sessions/')),
      isEmpty,
      reason: 'pushes stay suspended until the app updates',
    );
  });

  test(
      'guard clears automatically once the app understands the schema '
      '(simulated update: stored version <= currentSchemaVersion)', () async {
    await insertPuzzleWithSession('puz-1');
    // A record left behind by "before the update": the observed schema is
    // now within what this build understands.
    await db.appSettingsDao.setValue(
      SyncOrchestrator.upgradeGuardKey,
      jsonEncode({
        'schemaVersion': SyncBlob.currentSchemaVersion,
        'namespaces': ['sessions'],
      }),
    );

    await orchestrator.enableSilently();
    expect(
      (orchestrator.currentState as SyncIdle).upgradeRequired,
      isEmpty,
      reason: 'an understood schema is not an upgrade condition',
    );
    expect(
      await db.appSettingsDao.getValue(SyncOrchestrator.upgradeGuardKey),
      isNull,
      reason: 'the stale record is removed, not just ignored',
    );

    await orchestrator.syncNow();
    expect(
      cloud.keys.where((k) => k.startsWith('sessions/')),
      isNotEmpty,
      reason: 'pushes resume with no user action',
    );
  });

  test('malformed blobs stay a silent skip — no suspension', () async {
    cloud['sessions/garbage.json'] = 'not json at all';
    await insertPuzzleWithSession('puz-1');

    await orchestrator.syncNow();

    expect((orchestrator.currentState as SyncIdle).upgradeRequired, isEmpty);
    expect(
      cloud.keys.where(
        (k) => k.startsWith('sessions/') && k != 'sessions/garbage.json',
      ),
      isNotEmpty,
      reason: 'sessions still push; malformed bytes are not an upgrade signal',
    );
  });
}
