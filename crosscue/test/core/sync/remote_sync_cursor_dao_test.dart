import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('upsertCursor inserts and replaces by namespace/key', () async {
    await db.remoteSyncCursorDao.upsertCursor(
      namespace: SyncNamespace.sessions,
      syncKey: 'sessions/puz-1.json',
      metadata: SyncManifestEntry(
        syncVersion: 1,
        updatedAt: DateTime.utc(2026, 6, 5),
        deviceId: 'device-a',
      ),
      transportToken: 'etag-1',
      lastSeenAt: DateTime.utc(2026, 6, 5, 1),
    );

    await db.remoteSyncCursorDao.upsertCursor(
      namespace: SyncNamespace.sessions,
      syncKey: 'sessions/puz-1.json',
      metadata: SyncManifestEntry(
        syncVersion: 2,
        updatedAt: DateTime.utc(2026, 6, 6),
        deviceId: 'device-b',
      ),
      transportToken: 'etag-2',
      lastSeenAt: DateTime.utc(2026, 6, 6, 1),
    );

    final rows = await db.select(db.remoteSyncCursorsTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.namespace, equals('sessions'));
    expect(rows.single.syncKey, equals('sessions/puz-1.json'));
    expect(rows.single.syncVersion, equals(2));
    expect(rows.single.updatedAt.toUtc(), equals(DateTime.utc(2026, 6, 6)));
    expect(rows.single.deviceId, equals('device-b'));
    expect(rows.single.transportToken, equals('etag-2'));
    expect(
      rows.single.lastSeenAt.toUtc(),
      equals(DateTime.utc(2026, 6, 6, 1)),
    );
  });

  test('getNamespaceCursors and deleteCursor scope by namespace/key', () async {
    await db.remoteSyncCursorDao.upsertCursor(
      namespace: SyncNamespace.puzzles,
      syncKey: 'puzzles/puz-1.json',
      metadata: SyncManifestEntry(
        syncVersion: 1,
        updatedAt: DateTime.utc(2026),
        deviceId: 'device-a',
      ),
    );
    await db.remoteSyncCursorDao.upsertCursor(
      namespace: SyncNamespace.settings,
      syncKey: 'settings/theme_mode.json',
      metadata: SyncManifestEntry(
        syncVersion: 1,
        updatedAt: DateTime.utc(2026),
        deviceId: 'device-a',
      ),
    );

    expect(
      await db.remoteSyncCursorDao.getNamespaceCursors(SyncNamespace.puzzles),
      hasLength(1),
    );

    await db.remoteSyncCursorDao.deleteCursor(
      SyncNamespace.puzzles,
      'puzzles/puz-1.json',
    );

    expect(
      await db.remoteSyncCursorDao.getCursor(
        SyncNamespace.puzzles,
        'puzzles/puz-1.json',
      ),
      isNull,
    );
    expect(
      await db.remoteSyncCursorDao.getNamespaceCursors(SyncNamespace.settings),
      hasLength(1),
    );
  });
}
