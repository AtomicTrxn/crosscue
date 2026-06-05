import 'package:crosscue/core/sync/adapters/completions_sync_adapter.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_adapter_test_helpers.dart';

void main() {
  group('CompletionsSyncAdapter', () {
    test('concurrent completions merge as a client-uuid union', () async {
      final cloud = <String, String>{};
      final dbA = newTestDb();
      final dbB = newTestDb();
      addTearDown(dbA.close);
      addTearDown(dbB.close);
      final adapterA = CompletionsSyncAdapter(dbA);
      final adapterB = CompletionsSyncAdapter(dbB);

      await insertPuzzle(dbA, id: 'puzzle');
      await insertPuzzle(dbB, id: 'puzzle');
      await insertCompletion(
        dbA,
        puzzleId: 'puzzle',
        clientUuid: 'completion-a',
        deviceId: deviceA,
      );
      await insertCompletion(
        dbB,
        puzzleId: 'puzzle',
        clientUuid: 'completion-b',
        deviceId: deviceB,
      );

      expect(
        (await adapterA.push(FakeSyncTransport(store: cloud), deviceA)).pushed,
        1,
      );
      expect(
        (await adapterB.push(FakeSyncTransport(store: cloud), deviceB)).pushed,
        1,
      );

      expect(
        (await adapterA.pull(FakeSyncTransport(store: cloud))).pulled,
        1,
      );
      expect(
        (await adapterB.pull(FakeSyncTransport(store: cloud))).pulled,
        1,
      );

      final uuidsA = (await dbA.select(dbA.puzzleCompletionsTable).get())
          .map((row) => row.clientUuid)
          .toSet();
      final uuidsB = (await dbB.select(dbB.puzzleCompletionsTable).get())
          .map((row) => row.clientUuid)
          .toSet();
      expect(uuidsA, {'completion-a', 'completion-b'});
      expect(uuidsB, {'completion-a', 'completion-b'});
    });

    test('re-applying the same completion blob is a no-op', () async {
      final cloud = <String, String>{};
      final sourceDb = newTestDb();
      final targetDb = newTestDb();
      addTearDown(sourceDb.close);
      addTearDown(targetDb.close);
      final source = CompletionsSyncAdapter(sourceDb);
      final target = CompletionsSyncAdapter(targetDb);

      await insertPuzzle(sourceDb, id: 'puzzle');
      await insertPuzzle(targetDb, id: 'puzzle');
      await insertCompletion(
        sourceDb,
        puzzleId: 'puzzle',
        clientUuid: 'completion-a',
      );
      await source.push(FakeSyncTransport(store: cloud), deviceA);

      expect((await target.pull(FakeSyncTransport(store: cloud))).pulled, 1);
      expect((await target.pull(FakeSyncTransport(store: cloud))).pulled, 0);
      expect(
        await targetDb.select(targetDb.puzzleCompletionsTable).get(),
        hasLength(1),
      );
    });

    test('completion is skipped until its parent puzzle exists', () async {
      final cloud = <String, String>{
        'completions/orphan.json': encodedBlob(
          deviceId: deviceA,
          syncVersion: 1,
          updatedAt: t1,
          payload: const {
            'puzzleId': 'missing-puzzle',
            'completionType': 'clean',
            'completedAt': '2026-01-01T13:00:00.000Z',
            'solvedDateLocal': '2026-01-01',
            'elapsedMs': 1000,
          },
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);

      final outcome = await CompletionsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      expect(await db.select(db.puzzleCompletionsTable).get(), isEmpty);
    });

    test('newer schema blobs are skipped without crashing', () async {
      final cloud = <String, String>{
        'completions/future.json': encodedBlob(
          schemaVersion: 999,
          deviceId: deviceA,
          syncVersion: 1,
          updatedAt: t1,
          payload: const {'puzzleId': 'puzzle'},
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);
      await insertPuzzle(db, id: 'puzzle');

      final outcome = await CompletionsSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      expect(await db.select(db.puzzleCompletionsTable).get(), isEmpty);
    });
  });
}
