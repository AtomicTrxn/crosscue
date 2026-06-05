import 'package:crosscue/core/sync/adapters/puzzles_sync_adapter.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_adapter_test_helpers.dart';

void main() {
  group('PuzzlesSyncAdapter', () {
    test('concurrent puzzle imports merge as a lossless union', () async {
      final cloud = <String, String>{};
      final dbA = newTestDb();
      final dbB = newTestDb();
      addTearDown(dbA.close);
      addTearDown(dbB.close);
      final adapterA = PuzzlesSyncAdapter(dbA);
      final adapterB = PuzzlesSyncAdapter(dbB);

      await insertPuzzle(dbA, id: 'local:a', title: 'A');
      await insertPuzzle(dbB, id: 'local:b', title: 'B');

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

      final titlesA = (await dbA.select(dbA.puzzlesTable).get())
          .map((row) => row.title)
          .toSet();
      final titlesB = (await dbB.select(dbB.puzzlesTable).get())
          .map((row) => row.title)
          .toSet();
      expect(titlesA, {'A', 'B'});
      expect(titlesB, {'A', 'B'});
    });

    test('re-applying the same remote puzzle is a no-op', () async {
      final cloud = <String, String>{};
      final sourceDb = newTestDb();
      final targetDb = newTestDb();
      addTearDown(sourceDb.close);
      addTearDown(targetDb.close);
      final source = PuzzlesSyncAdapter(sourceDb);
      final target = PuzzlesSyncAdapter(targetDb);

      await insertPuzzle(sourceDb, id: 'local:a', title: 'A');
      await source.push(FakeSyncTransport(store: cloud), deviceA);

      expect((await target.pull(FakeSyncTransport(store: cloud))).pulled, 1);
      expect((await target.pull(FakeSyncTransport(store: cloud))).pulled, 0);
      expect(await targetDb.select(targetDb.puzzlesTable).get(), hasLength(1));
    });

    test('newer schema blobs are skipped without crashing', () async {
      final cloud = <String, String>{
        'puzzles/local:future.json': encodedBlob(
          schemaVersion: 999,
          deviceId: deviceA,
          syncVersion: 1,
          updatedAt: t1,
          payload: const {'sourceId': 'local_import'},
        ),
      };
      final db = newTestDb();
      addTearDown(db.close);

      final outcome = await PuzzlesSyncAdapter(db).pull(
        FakeSyncTransport(store: cloud),
      );

      expect(outcome.pulled, 0);
      expect(await db.select(db.puzzlesTable).get(), isEmpty);
    });
  });
}
