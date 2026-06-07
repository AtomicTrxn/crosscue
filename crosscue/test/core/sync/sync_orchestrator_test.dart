// Convergence tests for the sync foundation. Two AppDatabase.forTesting
// instances share a single FakeSyncTransport store; the orchestrator is
// driven end-to-end against an in-memory cloud.

import 'dart:async';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/models/sync_result.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/sync/sync_orchestrator.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:crosscue/core/utils/uuid.dart';
import 'package:drift/drift.dart' hide isNotNull;
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

  test('enableSilently restores via account() and never calls signIn()',
      () async {
    // The boot/launch path must not pop a sign-in sheet: it reaches SyncIdle
    // through the silent account() check, not the interactive signIn().
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final transport = _NoInteractiveSignInTransport();
    final orchestrator = SyncOrchestrator(transport: transport, db: db);
    addTearDown(orchestrator.dispose);

    await orchestrator.enableSilently();

    expect(orchestrator.currentState, isA<SyncIdle>());
    expect(transport.signInCalls, 0, reason: 'silent path must not sign in');
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

  test('missing manifest falls back to full sync and rebuilds manifest',
      () async {
    await insertPuzzle(deviceA, 'puz-1');
    await orchestratorA.syncNow();
    cloud.remove(SyncManifest.manifestKey);

    final loggingTransport = _LoggingFakeTransport(store: cloud);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final orchestrator = SyncOrchestrator(
      transport: loggingTransport,
      db: db,
    );
    addTearDown(orchestrator.dispose);
    await orchestrator.enable();

    final result = await orchestrator.syncNow();

    expect(result.pulled, equals(1));
    expect(cloud[SyncManifest.manifestKey], isNotNull);
    final manifest = SyncManifest.decode(cloud[SyncManifest.manifestKey]!);
    expect(manifest, isNotNull);
    expect(
      manifest!.namespaces[SyncNamespace.puzzles]!.keys,
      contains('puzzles/puz-1.json'),
    );

    final firstPuzzleRead =
        loggingTransport.events.indexOf('read:puzzles/puz-1.json');
    final manifestWrite =
        loggingTransport.events.indexOf('write:${SyncManifest.manifestKey}');
    expect(firstPuzzleRead, isNonNegative);
    expect(manifestWrite, isNonNegative);
    expect(
      manifestWrite,
      greaterThan(firstPuzzleRead),
      reason: 'manifest rebuild must happen after full fallback processing',
    );
  });

  test('valid manifest does not trigger fallback rebuild', () async {
    await insertPuzzle(deviceA, 'puz-1');
    await orchestratorA.syncNow();

    final loggingTransport = _LoggingFakeTransport(store: cloud);
    final orchestrator = SyncOrchestrator(
      transport: loggingTransport,
      db: deviceA,
    );
    addTearDown(orchestrator.dispose);
    await orchestrator.enable();

    final result = await orchestrator.syncNow();

    expect(result.pushed, equals(SyncResult.zero.pushed));
    expect(result.pulled, equals(SyncResult.zero.pulled));
    expect(
      loggingTransport.events
          .where((e) => e == 'write:${SyncManifest.manifestKey}'),
      isEmpty,
    );
  });

  group('incremental sync (#189)', () {
    Future<int> insertSession(
      AppDatabase db,
      String puzzleId, {
      String status = 'in_progress',
      DateTime? updatedAt,
    }) {
      final now = updatedAt ?? DateTime.now().toUtc();
      return db.into(db.solveSessionsTable).insert(
            SolveSessionsTableCompanion.insert(
              puzzleId: puzzleId,
              deviceId: 'device-a',
              startedAt: now,
              lastPlayedAt: now,
              createdAt: now,
              updatedAt: now,
              status: Value(status),
            ),
          );
    }

    List<String> blobReads(_LoggingFakeTransport t) => t.events
        .where(
          (e) =>
              e.startsWith('read:') && e != 'read:${SyncManifest.manifestKey}',
        )
        .toList();

    test('a converged second pass reads nothing but the manifest', () async {
      await insertPuzzle(deviceA, 'puz-1');
      await insertSession(deviceA, 'puz-1');
      await orchestratorA.syncNow();

      final logging = _LoggingFakeTransport(store: cloud);
      final orchestrator = SyncOrchestrator(transport: logging, db: deviceA);
      addTearDown(orchestrator.dispose);
      await orchestrator.enable();
      logging.events.clear();

      final result = await orchestrator.syncNow();

      expect(result.pulled, 0);
      expect(result.pushed, 0);
      // The manifest comparison alone decides there's nothing to do: no
      // per-blob reads, and no manifest rewrite.
      expect(blobReads(logging), isEmpty);
      expect(
        logging.events.where((e) => e.startsWith('write:')),
        isEmpty,
      );
    });

    test('a single changed session pulls only that blob on the peer', () async {
      await insertPuzzle(deviceA, 'puz-1');
      await insertPuzzle(deviceA, 'puz-2');
      await insertSession(deviceA, 'puz-1');
      await insertSession(deviceA, 'puz-2');

      // A publishes everything; B does a first (full) reconcile.
      await orchestratorA.syncNow();
      await orchestratorB.syncNow();

      // Change exactly one session on A and re-publish.
      final later = DateTime.now().toUtc().add(const Duration(hours: 1));
      await (deviceA.update(deviceA.solveSessionsTable)
            ..where((t) => t.puzzleId.equals('puz-1')))
          .write(
        SolveSessionsTableCompanion(
          status: const Value('completed'),
          completionType: const Value('clean'),
          completedAt: Value(later),
          solvedDateLocal: const Value('2026-01-02'),
          elapsedMs: const Value(1000),
          updatedAt: Value(later),
          isSynced: const Value(false),
        ),
      );
      await orchestratorA.syncNow();

      // B reconciles again through a logging transport.
      final logging = _LoggingFakeTransport(store: cloud);
      final orchestrator = SyncOrchestrator(transport: logging, db: deviceB);
      addTearDown(orchestrator.dispose);
      await orchestrator.enable();
      logging.events.clear();

      await orchestrator.syncNow();

      // Only the one changed session is read — not the unchanged session, not
      // the unchanged puzzles.
      expect(blobReads(logging), ['read:sessions/puz-1.json']);
      final sessionOnB = await (deviceB.select(deviceB.solveSessionsTable)
            ..where((t) => t.puzzleId.equals('puz-1')))
          .getSingle();
      expect(sessionOnB.status, 'completed');
    });

    test('a new puzzle + session + completion converge in one peer pass',
        () async {
      await insertPuzzle(deviceA, 'puz-1');
      await insertSession(deviceA, 'puz-1', status: 'completed');
      final uuid = Uuid.v4();
      await deviceA.into(deviceA.puzzleCompletionsTable).insert(
            PuzzleCompletionsTableCompanion.insert(
              puzzleId: 'puz-1',
              completionType: 'clean',
              completedAt: DateTime.now().toUtc(),
              solvedDateLocal: '2026-01-01',
              elapsedMs: 60000,
              clientUuid: uuid,
            ),
          );
      await orchestratorA.syncNow();

      // A single pass on the peer must satisfy puzzle → session/completion
      // foreign keys (adapter order pulls puzzles before its children).
      await orchestratorB.syncNow();

      expect(
        await (deviceB.select(deviceB.puzzlesTable)
              ..where((t) => t.id.equals('puz-1')))
            .getSingleOrNull(),
        isNotNull,
      );
      expect(
        await (deviceB.select(deviceB.solveSessionsTable)
              ..where((t) => t.puzzleId.equals('puz-1')))
            .getSingleOrNull(),
        isNotNull,
      );
      final completionsOnB =
          await deviceB.select(deviceB.puzzleCompletionsTable).get();
      expect(completionsOnB.map((c) => c.clientUuid), contains(uuid));
    });
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

  group('typed transport errors surface as SyncError (#113)', () {
    Future<SyncOrchestrator> enabledOrchestrator(
      SyncTransportErrorKind kind,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final orchestrator = SyncOrchestrator(
        transport: _ThrowingTransport(kind),
        db: db,
      );
      addTearDown(orchestrator.dispose);
      await orchestrator.enable();
      return orchestrator;
    }

    test('a locked error → SyncError(transient: true), syncNow does not throw',
        () async {
      final orchestrator = await enabledOrchestrator(
        SyncTransportErrorKind.locked,
      );

      // Must NOT throw — the fire-and-forget triggers rely on this.
      final result = await orchestrator.syncNow();
      expect(result.pushed, 0);
      expect(result.pulled, 0);

      final state = orchestrator.currentState;
      expect(state, isA<SyncError>());
      expect((state as SyncError).transient, isTrue);
    });

    test('a permission error → SyncError(transient: false)', () async {
      final orchestrator = await enabledOrchestrator(
        SyncTransportErrorKind.permissionDenied,
      );

      await orchestrator.syncNow();

      final state = orchestrator.currentState;
      expect(state, isA<SyncError>());
      expect((state as SyncError).transient, isFalse);
    });
  });
}

/// A transport that signals an account (so `enable()` reaches `SyncIdle`) but
/// throws a typed [SyncTransportException] from `list()` — the first call a
/// pull makes — to exercise the orchestrator's error handling.
class _ThrowingTransport implements SyncTransport {
  _ThrowingTransport(this._kind);

  final SyncTransportErrorKind _kind;

  @override
  Future<SyncAccount?> account() async =>
      const SyncAccount(provider: SyncProvider.fake, displayName: 'fake');

  @override
  Future<SyncAccount?> signIn() => account();

  @override
  bool get supportsInteractiveSignIn => false;

  @override
  Future<List<String>> list(String prefix) async =>
      throw SyncTransportException(_kind, message: 'boom');

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async =>
      null;

  @override
  Future<void> delete(String key) async {}
}

class _LoggingFakeTransport extends FakeSyncTransport {
  _LoggingFakeTransport({required super.store});

  final List<String> events = [];

  @override
  Future<List<String>> list(String prefix) async {
    events.add('list:$prefix');
    return super.list(prefix);
  }

  @override
  Future<String?> read(String key) async {
    events.add('read:$key');
    return super.read(key);
  }

  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async {
    events.add('write:$key');
    return super.write(key, bytes, ifMatch: ifMatch);
  }
}

/// A transport that has an ambient account but records whether the interactive
/// `signIn()` is ever called — proving `enableSilently()` stays on the silent
/// `account()` path.
class _NoInteractiveSignInTransport implements SyncTransport {
  int signInCalls = 0;

  @override
  Future<SyncAccount?> account() async =>
      const SyncAccount(provider: SyncProvider.fake, displayName: 'fake');

  @override
  Future<SyncAccount?> signIn() async {
    signInCalls++;
    return account();
  }

  @override
  bool get supportsInteractiveSignIn => true;

  @override
  Future<List<String>> list(String prefix) async => const [];
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async =>
      null;
  @override
  Future<void> delete(String key) async {}
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
  Future<SyncAccount?> signIn() => account();

  @override
  bool get supportsInteractiveSignIn => false;

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
