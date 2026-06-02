// Convergence tests for the sync foundation. Two AppDatabase.forTesting
// instances share a single FakeSyncTransport store; the orchestrator is
// driven end-to-end against an in-memory cloud.

import 'dart:async';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/sync/sync_orchestrator.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:crosscue/core/utils/uuid.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> cloud;
  late AppDatabase deviceA;
  late AppDatabase deviceB;
  late SyncOrchestrator orchestratorA;
  late SyncOrchestrator orchestratorB;

  setUp(() async {
    cloud = <String, String>{};
    deviceA = AppDatabase.forTesting(NativeDatabase.memory());
    deviceB = AppDatabase.forTesting(NativeDatabase.memory());
    orchestratorA = SyncOrchestrator(
      transport: FakeSyncTransport(store: cloud),
      db: deviceA,
    );
    orchestratorB = SyncOrchestrator(
      transport: FakeSyncTransport(store: cloud),
      db: deviceB,
    );
    await orchestratorA.enable();
    await orchestratorB.enable();
  });

  tearDown(() async {
    await orchestratorA.dispose();
    await orchestratorB.dispose();
    await deviceA.close();
    await deviceB.close();
  });

  Future<void> insertPuzzle(AppDatabase db, String id) async {
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
  }

  test('orchestrator starts in SyncSignedOut for an account-less transport',
      () async {
    // FakeSyncTransport defaults to having an account, so we expect SyncIdle.
    expect(orchestratorA.currentState, isA<SyncIdle>());
  });

  test('puzzles converge across devices in one sync round trip', () async {
    await insertPuzzle(deviceA, 'puz-1');
    await insertPuzzle(deviceA, 'puz-2');

    await orchestratorA.syncNow();
    final pulled = await orchestratorB.syncNow();
    expect(pulled.pulled, equals(2));

    final puzzlesOnB = await deviceB.select(deviceB.puzzlesTable).get();
    expect(puzzlesOnB.map((p) => p.id), containsAll(['puz-1', 'puz-2']));
    expect(puzzlesOnB.map((p) => p.isSynced), everyElement(isTrue));
  });

  test('completions converge by client_uuid set union', () async {
    await insertPuzzle(deviceA, 'puz-1');
    await insertPuzzle(deviceB, 'puz-1');

    final uuid1 = Uuid.v4();
    final uuid2 = Uuid.v4();
    final now = DateTime.now().toUtc();

    await deviceA.into(deviceA.puzzleCompletionsTable).insert(
          PuzzleCompletionsTableCompanion.insert(
            puzzleId: 'puz-1',
            completionType: 'clean',
            completedAt: now,
            solvedDateLocal: '2026-01-01',
            elapsedMs: 60000,
            clientUuid: uuid1,
          ),
        );
    await deviceB.into(deviceB.puzzleCompletionsTable).insert(
          PuzzleCompletionsTableCompanion.insert(
            puzzleId: 'puz-1',
            completionType: 'checked',
            completedAt: now,
            solvedDateLocal: '2026-01-02',
            elapsedMs: 45000,
            clientUuid: uuid2,
          ),
        );

    // A pushes; B pushes; both pull.
    await orchestratorA.syncNow();
    await orchestratorB.syncNow();
    await orchestratorA.syncNow();

    final completionsOnA =
        await deviceA.select(deviceA.puzzleCompletionsTable).get();
    final completionsOnB =
        await deviceB.select(deviceB.puzzleCompletionsTable).get();
    expect(
      completionsOnA.map((c) => c.clientUuid),
      containsAll([uuid1, uuid2]),
    );
    expect(
      completionsOnB.map((c) => c.clientUuid),
      containsAll([uuid1, uuid2]),
    );
  });

  test('a remote completed session overrides a local in-progress session',
      () async {
    await insertPuzzle(deviceA, 'puz-1');
    await insertPuzzle(deviceB, 'puz-1');

    // Device B has a fresh in-progress session.
    final now = DateTime.now().toUtc();
    await deviceB.into(deviceB.solveSessionsTable).insert(
          SolveSessionsTableCompanion.insert(
            puzzleId: 'puz-1',
            deviceId: 'device-b',
            startedAt: now,
            lastPlayedAt: now,
            createdAt: now,
            updatedAt: now,
            status: const Value('in_progress'),
          ),
        );

    // Device A has a *completed* session for the same puzzle, but with an
    // EARLIER updatedAt — without best-progress override, LWW would let the
    // local in-progress win on B.
    final earlier = now.subtract(const Duration(hours: 1));
    await deviceA.into(deviceA.solveSessionsTable).insert(
          SolveSessionsTableCompanion.insert(
            puzzleId: 'puz-1',
            deviceId: 'device-a',
            startedAt: earlier,
            lastPlayedAt: earlier,
            createdAt: earlier,
            updatedAt: earlier,
            status: const Value('completed'),
            completionType: const Value('clean'),
            completedAt: Value(earlier),
            solvedDateLocal: const Value('2026-01-01'),
            elapsedMs: const Value(60000),
          ),
        );

    final pushA = await orchestratorA.syncNow();
    expect(pushA.pushed, greaterThanOrEqualTo(1));

    final pullB = await orchestratorB.syncNow();
    expect(pullB.conflicts, equals(1));

    final sessionOnB = await (deviceB.select(deviceB.solveSessionsTable)
          ..where((t) => t.puzzleId.equals('puz-1')))
        .getSingle();
    expect(sessionOnB.status, equals('completed'));
    expect(sessionOnB.completionType, equals('clean'));
  });

  test('syncing twice is idempotent — second pass writes nothing', () async {
    await insertPuzzle(deviceA, 'puz-1');

    final first = await orchestratorA.syncNow();
    expect(first.pushed, greaterThan(0));

    final second = await orchestratorA.syncNow();
    expect(second.pushed, equals(0));
    expect(second.pulled, equals(0));
  });

  test('disable(wipeRemote: true) clears the cloud bucket', () async {
    await insertPuzzle(deviceA, 'puz-1');
    await orchestratorA.syncNow();
    expect(cloud, isNotEmpty);

    // Re-enable to bypass the early-return in syncNow before disabling.
    await orchestratorA.disable(wipeRemote: true);
    expect(cloud, isEmpty);
  });

  test('syncNow coalesces overlapping passes while one is running', () async {
    final gate = Completer<void>();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final orchestrator = SyncOrchestrator(
      transport: _GatedListTransport(gate),
      db: db,
    );
    addTearDown(orchestrator.dispose);
    await orchestrator.enable();

    // Start a pass; it parks inside the first adapter's gated list() call.
    final first = orchestrator.syncNow();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(orchestrator.currentState, isA<SyncRunning>());

    // A second trigger while running is a no-op (returns zero immediately).
    final second = await orchestrator.syncNow();
    expect(second.pushed, equals(0));
    expect(second.pulled, equals(0));

    gate.complete();
    await first;
    expect(orchestrator.currentState, isA<SyncIdle>());
  });
}

/// A transport whose `list()` blocks until [gate] completes — lets a test park
/// a sync pass in [SyncRunning] to exercise the overlap guard.
class _GatedListTransport implements SyncTransport {
  _GatedListTransport(this._gate);

  final Completer<void> _gate;

  @override
  Future<SyncAccount?> account() async =>
      const SyncAccount(provider: SyncProvider.fake, displayName: 'fake');

  @override
  Future<List<String>> list(String prefix) async {
    await _gate.future;
    return const [];
  }

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async =>
      null;

  @override
  Future<void> delete(String key) async {}
}
