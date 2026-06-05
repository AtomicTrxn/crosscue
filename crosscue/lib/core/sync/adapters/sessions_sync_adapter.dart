import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:drift/drift.dart';

/// Sessions are one-mutable-row-per-puzzle. Merge rule: last-writer-wins by
/// (updatedAt, deviceId) with a best-progress override — a remote completed
/// session always beats a local in-progress session, regardless of clock.
/// Avoids stale-clock data loss of real completions.
class SessionsSyncAdapter extends NamespaceSyncAdapter {
  SessionsSyncAdapter(this.db);

  final AppDatabase db;

  @override
  SyncNamespace get namespace => SyncNamespace.sessions;

  @override
  Future<NamespaceSyncOutcome> push(
    SyncTransport transport,
    String deviceId,
  ) async {
    final dirty = await (db.select(db.solveSessionsTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
    if (dirty.isEmpty) return NamespaceSyncOutcome.zero;

    var pushed = 0;
    for (final session in dirty) {
      final cells = await (db.select(db.cellProgressTable)
            ..where((t) => t.sessionId.equals(session.id)))
          .get();

      final newVersion = session.syncVersion + 1;
      final blob = SyncBlob(
        schemaVersion: SyncBlob.currentSchemaVersion,
        deviceId: deviceId,
        syncVersion: newVersion,
        updatedAt: session.updatedAt,
        payload: _encodeSession(session, cells),
      );
      await transport.write(keyFor(session.puzzleId), blob.encode());
      pushed++;

      await (db.update(db.solveSessionsTable)
            ..where((t) => t.id.equals(session.id)))
          .write(
        SolveSessionsTableCompanion(
          isSynced: const Value(true),
          syncVersion: Value(newVersion),
        ),
      );
    }
    return NamespaceSyncOutcome(pushed: pushed);
  }

  @override
  Future<NamespaceSyncOutcome> pull(SyncTransport transport) async {
    final remoteKeys = await transport.list(namespace.prefix);
    if (remoteKeys.isEmpty) return NamespaceSyncOutcome.zero;

    var pulled = 0;
    var conflicts = 0;
    for (final key in remoteKeys) {
      final puzzleId = idFromKey(key);
      if (puzzleId == null) continue;

      final bytes = await transport.read(key);
      if (bytes == null) continue;
      final blob = SyncBlob.decode(bytes);
      if (blob == null) continue;

      final local = await (db.select(db.solveSessionsTable)
            ..where((t) => t.puzzleId.equals(puzzleId))
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)])
            ..limit(1))
          .getSingleOrNull();

      final decision = _resolveConflict(local, blob);
      if (decision == _MergeDecision.keepLocal) continue;
      if (decision == _MergeDecision.bestProgressOverride) conflicts++;

      await _applyRemoteSession(puzzleId, blob, replacing: local);
      pulled++;
    }
    return NamespaceSyncOutcome(pulled: pulled, conflicts: conflicts);
  }

  _MergeDecision _resolveConflict(SolveSessionRow? local, SyncBlob remote) {
    if (local == null) return _MergeDecision.takeRemote;

    final remoteStatus = remote.payload['status'];
    final remoteCompleted =
        remoteStatus == 'completed' || remoteStatus == 'revealed';
    final localCompleted =
        local.status == 'completed' || local.status == 'revealed';
    final remoteInProgress =
        remoteStatus == 'in_progress' || remoteStatus == 'not_started';
    final localInProgress = local.status == 'in_progress';
    if (remoteCompleted && localInProgress) {
      return _MergeDecision.bestProgressOverride;
    }
    if (localCompleted && remoteInProgress) {
      return _MergeDecision.keepLocal;
    }

    if (remote.syncVersion > local.syncVersion) {
      return _MergeDecision.takeRemote;
    }
    if (remote.syncVersion < local.syncVersion) {
      return _MergeDecision.keepLocal;
    }
    // Equal version → fall back to wall-clock + deviceId tiebreak.
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      return _MergeDecision.takeRemote;
    }
    if (remote.updatedAt.isBefore(local.updatedAt)) {
      return _MergeDecision.keepLocal;
    }
    return remote.deviceId.compareTo(local.deviceId) > 0
        ? _MergeDecision.takeRemote
        : _MergeDecision.keepLocal;
  }

  Future<void> _applyRemoteSession(
    String puzzleId,
    SyncBlob blob, {
    SolveSessionRow? replacing,
  }) async {
    final p = blob.payload;
    final startedAt = _parseDate(p['startedAt']) ?? DateTime.now().toUtc();
    final lastPlayedAt = _parseDate(p['lastPlayedAt']) ?? blob.updatedAt;

    await db.transaction(() async {
      final int sessionId;
      if (replacing != null) {
        await (db.update(db.solveSessionsTable)
              ..where((t) => t.id.equals(replacing.id)))
            .write(_companionFromBlob(puzzleId, blob, startedAt, lastPlayedAt));
        sessionId = replacing.id;
        await (db.delete(db.cellProgressTable)
              ..where((t) => t.sessionId.equals(sessionId)))
            .go();
      } else {
        sessionId = await db.into(db.solveSessionsTable).insert(
              _companionFromBlob(
                puzzleId,
                blob,
                startedAt,
                lastPlayedAt,
              ),
            );
      }

      final cells = p['cells'];
      if (cells is List) {
        for (final cell in cells) {
          if (cell is! Map) continue;
          final row = cell['row'];
          final col = cell['col'];
          if (row is! int || col is! int) continue;
          await db.into(db.cellProgressTable).insert(
                CellProgressTableCompanion.insert(
                  sessionId: sessionId,
                  row: row,
                  col: col,
                  guess: Value(cell['guess'] as String?),
                  state: Value((cell['state'] as String?) ?? 'empty'),
                  wasChecked: Value((cell['wasChecked'] as bool?) ?? false),
                  wasRevealed: Value((cell['wasRevealed'] as bool?) ?? false),
                  lastWrongGuessHash:
                      Value(cell['lastWrongGuessHash'] as String?),
                  isPencil: Value((cell['isPencil'] as bool?) ?? false),
                  updatedAt: blob.updatedAt,
                ),
              );
        }
      }
    });
  }

  SolveSessionsTableCompanion _companionFromBlob(
    String puzzleId,
    SyncBlob blob,
    DateTime startedAt,
    DateTime lastPlayedAt,
  ) {
    final p = blob.payload;
    return SolveSessionsTableCompanion.insert(
      puzzleId: puzzleId,
      deviceId: blob.deviceId,
      status: Value((p['status'] as String?) ?? 'in_progress'),
      completionType: Value(p['completionType'] as String?),
      startedAt: startedAt,
      lastPlayedAt: lastPlayedAt,
      completedAt: Value(_parseDate(p['completedAt'])),
      solvedDateLocal: Value(p['solvedDateLocal'] as String?),
      solvedTimezone: Value(p['solvedTimezone'] as String?),
      elapsedMs: Value((p['elapsedMs'] as int?) ?? 0),
      isPaused: Value((p['isPaused'] as bool?) ?? false),
      pausedAt: Value(_parseDate(p['pausedAt'])),
      totalPausedMs: Value((p['totalPausedMs'] as int?) ?? 0),
      mistakeCount: Value((p['mistakeCount'] as int?) ?? 0),
      checkCount: Value((p['checkCount'] as int?) ?? 0),
      revealCount: Value((p['revealCount'] as int?) ?? 0),
      usedCheck: Value((p['usedCheck'] as bool?) ?? false),
      usedReveal: Value((p['usedReveal'] as bool?) ?? false),
      cleanSolveEligible: Value((p['cleanSolveEligible'] as bool?) ?? true),
      focusRow: Value((p['focusRow'] as int?) ?? 0),
      focusCol: Value((p['focusCol'] as int?) ?? 0),
      direction: Value((p['direction'] as String?) ?? 'across'),
      isSynced: const Value(true),
      syncVersion: Value(blob.syncVersion),
      createdAt: startedAt,
      updatedAt: blob.updatedAt,
    );
  }

  Map<String, Object?> _encodeSession(
    SolveSessionRow s,
    List<CellProgressRow> cells,
  ) =>
      <String, Object?>{
        'puzzleId': s.puzzleId,
        'status': s.status,
        'completionType': s.completionType,
        'startedAt': s.startedAt.toUtc().toIso8601String(),
        'lastPlayedAt': s.lastPlayedAt.toUtc().toIso8601String(),
        'completedAt': s.completedAt?.toUtc().toIso8601String(),
        'solvedDateLocal': s.solvedDateLocal,
        'solvedTimezone': s.solvedTimezone,
        'elapsedMs': s.elapsedMs,
        'isPaused': s.isPaused,
        'pausedAt': s.pausedAt?.toUtc().toIso8601String(),
        'totalPausedMs': s.totalPausedMs,
        'mistakeCount': s.mistakeCount,
        'checkCount': s.checkCount,
        'revealCount': s.revealCount,
        'usedCheck': s.usedCheck,
        'usedReveal': s.usedReveal,
        'cleanSolveEligible': s.cleanSolveEligible,
        'focusRow': s.focusRow,
        'focusCol': s.focusCol,
        'direction': s.direction,
        'cells': [
          for (final c in cells)
            <String, Object?>{
              'row': c.row,
              'col': c.col,
              'guess': c.guess,
              'state': c.state,
              'wasChecked': c.wasChecked,
              'wasRevealed': c.wasRevealed,
              'lastWrongGuessHash': c.lastWrongGuessHash,
              'isPencil': c.isPencil,
            },
        ],
      };

  DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

enum _MergeDecision { takeRemote, keepLocal, bestProgressOverride }
