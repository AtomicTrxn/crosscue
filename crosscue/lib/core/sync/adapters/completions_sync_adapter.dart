import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:drift/drift.dart';

/// Completions are immutable and append-only. Merge rule: set union by
/// `client_uuid`. No conflicts are possible.
class CompletionsSyncAdapter extends NamespaceSyncAdapter {
  CompletionsSyncAdapter(this.db);

  final AppDatabase db;

  @override
  SyncNamespace get namespace => SyncNamespace.completions;

  @override
  Future<NamespaceSyncOutcome> push(
    SyncTransport transport,
    String deviceId,
  ) async {
    final remoteUuids = (await transport.list(namespace.prefix))
        .map(idFromKey)
        .whereType<String>()
        .toSet();

    final localRows = await db.select(db.puzzleCompletionsTable).get();
    final missing = localRows
        .where((r) => !remoteUuids.contains(r.clientUuid))
        .toList();

    var pushed = 0;
    for (final row in missing) {
      final blob = SyncBlob(
        schemaVersion: SyncBlob.currentSchemaVersion,
        deviceId: deviceId,
        syncVersion: 1,
        updatedAt: row.completedAt,
        payload: _encodeRow(row),
      );
      await transport.write(keyFor(row.clientUuid), blob.encode());
      pushed++;
    }
    return NamespaceSyncOutcome(pushed: pushed);
  }

  @override
  Future<NamespaceSyncOutcome> pull(SyncTransport transport) async {
    final remoteKeys = await transport.list(namespace.prefix);
    if (remoteKeys.isEmpty) return NamespaceSyncOutcome.zero;

    final localUuids = (await (db.selectOnly(db.puzzleCompletionsTable)
              ..addColumns([db.puzzleCompletionsTable.clientUuid]))
            .map((r) => r.read(db.puzzleCompletionsTable.clientUuid))
            .get())
        .whereType<String>()
        .toSet();

    final localPuzzleIds = (await (db.selectOnly(db.puzzlesTable)
              ..addColumns([db.puzzlesTable.id]))
            .map((r) => r.read(db.puzzlesTable.id))
            .get())
        .whereType<String>()
        .toSet();

    var pulled = 0;
    for (final key in remoteKeys) {
      final uuid = idFromKey(key);
      if (uuid == null || localUuids.contains(uuid)) continue;

      final bytes = await transport.read(key);
      if (bytes == null) continue;
      final blob = SyncBlob.decode(bytes);
      if (blob == null) continue;

      final companion = _decodeRow(uuid, blob);
      if (companion == null) continue;

      // Skip if the parent puzzle isn't on this device yet — the next sync
      // pass (after the puzzles adapter pulls) will pick it up. Avoids FK
      // violations under partial-sync conditions.
      if (!localPuzzleIds.contains(companion.puzzleId.value)) continue;

      await db.into(db.puzzleCompletionsTable).insert(companion);
      pulled++;
    }
    return NamespaceSyncOutcome(pulled: pulled);
  }

  Map<String, Object?> _encodeRow(PuzzleCompletionRow r) => <String, Object?>{
        'puzzleId': r.puzzleId,
        'completionType': r.completionType,
        'completedAt': r.completedAt.toUtc().toIso8601String(),
        'solvedDateLocal': r.solvedDateLocal,
        'solvedTimezone': r.solvedTimezone,
        'elapsedMs': r.elapsedMs,
        'checkCount': r.checkCount,
        'revealCount': r.revealCount,
        'clientUuid': r.clientUuid,
        'deviceId': r.deviceId,
      };

  PuzzleCompletionsTableCompanion? _decodeRow(String uuid, SyncBlob blob) {
    final p = blob.payload;
    final puzzleId = p['puzzleId'];
    final completionType = p['completionType'];
    final completedAtStr = p['completedAt'];
    final solvedDateLocal = p['solvedDateLocal'];
    final elapsedMs = p['elapsedMs'];

    if (puzzleId is! String ||
        completionType is! String ||
        completedAtStr is! String ||
        solvedDateLocal is! String ||
        elapsedMs is! int) {
      return null;
    }
    final completedAt = DateTime.tryParse(completedAtStr);
    if (completedAt == null) return null;

    return PuzzleCompletionsTableCompanion.insert(
      puzzleId: puzzleId,
      completionType: completionType,
      completedAt: completedAt,
      solvedDateLocal: solvedDateLocal,
      solvedTimezone: Value(p['solvedTimezone'] as String?),
      elapsedMs: elapsedMs,
      checkCount: Value((p['checkCount'] as int?) ?? 0),
      revealCount: Value((p['revealCount'] as int?) ?? 0),
      clientUuid: uuid,
      deviceId: Value((p['deviceId'] as String?) ?? blob.deviceId),
    );
  }
}
