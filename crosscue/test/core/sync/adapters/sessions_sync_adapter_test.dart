import 'package:crosscue/core/sync/adapters/sessions_sync_adapter.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_adapter_test_helpers.dart';

void main() {
  group('SessionsSyncAdapter', () {
    test('concurrent sessions for different puzzles merge losslessly',
        () async {
      final cloud = <String, String>{};
      final dbA = newTestDb();
      final dbB = newTestDb();
      addTearDown(dbA.close);
      addTearDown(dbB.close);
      final adapterA = SessionsSyncAdapter(dbA);
      final adapterB = SessionsSyncAdapter(dbB);

      await insertPuzzle(dbA, id: 'puzzle-a');
      await insertPuzzle(dbA, id: 'puzzle-b');
      await insertPuzzle(dbB, id: 'puzzle-a');
      await insertPuzzle(dbB, id: 'puzzle-b');
      await insertSession(
        dbA,
        puzzleId: 'puzzle-a',
        deviceId: deviceA,
        updatedAt: t1,
      );
      await insertSession(
        dbB,
        puzzleId: 'puzzle-b',
        deviceId: deviceB,
        updatedAt: t1,
      );

      await adapterA.push(FakeSyncTransport(store: cloud), deviceA);
      await adapterB.push(FakeSyncTransport(store: cloud), deviceB);

      expect((await adapterA.pull(FakeSyncTransport(store: cloud))).pulled, 1);
      expect((await adapterB.pull(FakeSyncTransport(store: cloud))).pulled, 1);

      expect(await dbA.select(dbA.solveSessionsTable).get(), hasLength(2));
      expect(await dbB.select(dbB.solveSessionsTable).get(), hasLength(2));
    });

    test('equal updatedAt tie-break compares remote and local device ids',
        () async {
      final cloud = <String, String>{
        'sessions/puzzle.json': encodedBlob(
          deviceId: 'm-device',
          syncVersion: 1,
          updatedAt: t1,
          payload: {
            'status': 'in_progress',
            'startedAt': t0.toIso8601String(),
            'lastPlayedAt': t1.toIso8601String(),
            'elapsedMs': 20,
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertPuzzle(db, id: 'puzzle');
      await insertSession(
        db,
        puzzleId: 'puzzle',
        deviceId: 'z-device',
        updatedAt: t1,
        elapsedMs: 10,
        syncVersion: 1,
        isSynced: true,
      );

      final outcome = await SessionsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      final session = (await db.select(db.solveSessionsTable).get()).single;
      expect(session.deviceId, 'z-device');
      expect(session.elapsedMs, 10);
    });

    test('remote completed progress beats older local in-progress data',
        () async {
      final cloud = <String, String>{
        'sessions/puzzle.json': encodedBlob(
          deviceId: deviceB,
          syncVersion: 1,
          updatedAt: t1,
          payload: {
            'status': 'completed',
            'completionType': 'clean',
            'startedAt': t0.toIso8601String(),
            'lastPlayedAt': t1.toIso8601String(),
            'completedAt': t1.toIso8601String(),
            'elapsedMs': 1000,
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertPuzzle(db, id: 'puzzle');
      await insertSession(
        db,
        puzzleId: 'puzzle',
        deviceId: deviceA,
        status: 'in_progress',
        updatedAt: t2,
        syncVersion: 5,
      );

      final outcome = await SessionsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 1);
      expect(outcome.conflicts, 1);
      final session = (await db.select(db.solveSessionsTable).get()).single;
      expect(session.status, 'completed');
      expect(session.syncVersion, 1);
    });

    test('local completed progress is not regressed by newer in-progress data',
        () async {
      final cloud = <String, String>{
        'sessions/puzzle.json': encodedBlob(
          deviceId: deviceB,
          syncVersion: 9,
          updatedAt: t2,
          payload: {
            'status': 'in_progress',
            'startedAt': t0.toIso8601String(),
            'lastPlayedAt': t2.toIso8601String(),
            'elapsedMs': 500,
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertPuzzle(db, id: 'puzzle');
      await insertSession(
        db,
        puzzleId: 'puzzle',
        deviceId: deviceA,
        status: 'completed',
        updatedAt: t1,
        completedAt: t1,
        elapsedMs: 1000,
        syncVersion: 1,
        isSynced: true,
      );

      final outcome = await SessionsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      final session = (await db.select(db.solveSessionsTable).get()).single;
      expect(session.status, 'completed');
      expect(session.elapsedMs, 1000);
    });

    test('re-applying the same session blob is a no-op', () async {
      final cloud = <String, String>{
        'sessions/puzzle.json': encodedBlob(
          deviceId: deviceB,
          syncVersion: 1,
          updatedAt: t1,
          payload: {
            'status': 'in_progress',
            'startedAt': t0.toIso8601String(),
            'lastPlayedAt': t1.toIso8601String(),
            'elapsedMs': 100,
            'cells': const [
              {'row': 0, 'col': 0, 'guess': 'A', 'state': 'filled'},
            ],
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertPuzzle(db, id: 'puzzle');
      final adapter = SessionsSyncAdapter(db);

      expect((await adapter.pull(FakeSyncTransport(store: cloud))).pulled, 1);
      expect((await adapter.pull(FakeSyncTransport(store: cloud))).pulled, 0);
      expect(await db.select(db.solveSessionsTable).get(), hasLength(1));
      expect(await db.select(db.cellProgressTable).get(), hasLength(1));
    });

    test('session is skipped until its parent puzzle exists', () async {
      final cloud = <String, String>{
        'sessions/missing-puzzle.json': encodedBlob(
          deviceId: deviceB,
          syncVersion: 1,
          updatedAt: t1,
          payload: {
            'status': 'in_progress',
            'startedAt': t0.toIso8601String(),
            'lastPlayedAt': t1.toIso8601String(),
            'elapsedMs': 100,
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);

      final outcome = await SessionsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      expect(await db.select(db.solveSessionsTable).get(), isEmpty);
    });

    test('newer schema blobs are skipped without crashing', () async {
      final cloud = <String, String>{
        'sessions/puzzle.json': encodedBlob(
          schemaVersion: 999,
          deviceId: deviceB,
          syncVersion: 1,
          updatedAt: t1,
          payload: const {'status': 'completed'},
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertPuzzle(db, id: 'puzzle');

      final outcome = await SessionsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      expect(await db.select(db.solveSessionsTable).get(), isEmpty);
    });
  });
}
