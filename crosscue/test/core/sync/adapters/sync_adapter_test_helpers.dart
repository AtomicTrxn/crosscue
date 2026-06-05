import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

const deviceA = 'device-a';
const deviceB = 'device-b';
final t0 = DateTime.utc(2026, 1, 1, 12);
final t1 = DateTime.utc(2026, 1, 1, 13);
final t2 = DateTime.utc(2026, 1, 1, 14);

bool _driftWarningsSuppressed = false;

AppDatabase newTestDb() {
  if (!_driftWarningsSuppressed) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    _driftWarningsSuppressed = true;
  }
  return AppDatabase.forTesting(NativeDatabase.memory());
}

Future<void> insertPuzzle(
  AppDatabase db, {
  required String id,
  String title = 'Puzzle',
  DateTime? createdAt,
  bool isSynced = false,
  int syncVersion = 0,
}) async {
  final now = createdAt ?? t0;
  await db.into(db.puzzlesTable).insert(
        PuzzlesTableCompanion.insert(
          id: id,
          sourceId: 'local_import',
          format: 'puz',
          title: title,
          width: 5,
          height: 5,
          checksum: 'checksum-$id',
          canonicalJson: '{"id":"$id"}',
          createdAt: now,
          updatedAt: now,
          isSynced: Value(isSynced),
          syncVersion: Value(syncVersion),
        ),
      );
}

Future<int> insertSession(
  AppDatabase db, {
  required String puzzleId,
  required String deviceId,
  String status = 'in_progress',
  DateTime? updatedAt,
  DateTime? lastPlayedAt,
  DateTime? completedAt,
  int elapsedMs = 0,
  int syncVersion = 0,
  bool isSynced = false,
}) {
  final now = updatedAt ?? t0;
  return db.into(db.solveSessionsTable).insert(
        SolveSessionsTableCompanion.insert(
          puzzleId: puzzleId,
          deviceId: deviceId,
          status: Value(status),
          completionType: Value(status == 'completed' ? 'clean' : null),
          startedAt: t0,
          lastPlayedAt: lastPlayedAt ?? now,
          completedAt: Value(completedAt),
          elapsedMs: Value(elapsedMs),
          isSynced: Value(isSynced),
          syncVersion: Value(syncVersion),
          createdAt: t0,
          updatedAt: now,
        ),
      );
}

Future<void> insertCell(
  AppDatabase db, {
  required int sessionId,
  int row = 0,
  int col = 0,
  String guess = 'A',
  DateTime? updatedAt,
}) async {
  await db.into(db.cellProgressTable).insert(
        CellProgressTableCompanion.insert(
          sessionId: sessionId,
          row: row,
          col: col,
          guess: Value(guess),
          state: const Value('filled'),
          updatedAt: updatedAt ?? t0,
        ),
      );
}

Future<void> insertCompletion(
  AppDatabase db, {
  required String puzzleId,
  required String clientUuid,
  String deviceId = deviceA,
  DateTime? completedAt,
  int elapsedMs = 1000,
}) async {
  await db.into(db.puzzleCompletionsTable).insert(
        PuzzleCompletionsTableCompanion.insert(
          puzzleId: puzzleId,
          completionType: 'clean',
          completedAt: completedAt ?? t1,
          solvedDateLocal: '2026-01-01',
          elapsedMs: elapsedMs,
          clientUuid: clientUuid,
          deviceId: Value(deviceId),
        ),
      );
}

Future<void> insertSetting(
  AppDatabase db, {
  required String key,
  required String valueJson,
  DateTime? updatedAt,
  int syncVersion = 0,
}) async {
  await db.into(db.appSettingsTable).insert(
        AppSettingsTableCompanion.insert(
          key: key,
          valueJson: valueJson,
          updatedAt: updatedAt ?? t0,
          syncVersion: Value(syncVersion),
        ),
      );
}

String encodedBlob({
  required String deviceId,
  required int syncVersion,
  required DateTime updatedAt,
  required Map<String, Object?> payload,
  int schemaVersion = SyncBlob.currentSchemaVersion,
}) {
  return SyncBlob(
    schemaVersion: schemaVersion,
    deviceId: deviceId,
    syncVersion: syncVersion,
    updatedAt: updatedAt,
    payload: payload,
  ).encode();
}
