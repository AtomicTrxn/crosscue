import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_secure_store.dart';

void main() {
  late AppDatabase db;
  late InMemorySecureKeyValueStore secureStore;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    secureStore = InMemorySecureKeyValueStore();
  });

  tearDown(() => db.close());

  test('identity store persists player id and auth token', () async {
    final store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    );

    await store.write(
      const ChallengeIdentity(playerId: 'player-1', authToken: 'token-1'),
    );

    final identity = await store.read();
    expect(identity?.playerId, 'player-1');
    expect(identity?.authToken, 'token-1');
  });

  test('auth token lives in secure storage, never in app settings', () async {
    final store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    );

    await store.write(
      const ChallengeIdentity(
        playerId: 'player-1',
        authToken: 'token-1',
        recoverySecret: 'recovery-1',
      ),
    );

    expect(secureStore.values[ChallengeIdentityStore.authTokenKey], 'token-1');
    expect(
      await db.appSettingsDao.getValue(ChallengeIdentityStore.authTokenKey),
      isNull,
    );
    // The recovery bundle stays in app settings so it survives OS backup
    // and syncs to the user's own cloud (docs/privacy.md).
    expect(
      await db.appSettingsDao
          .getValue(ChallengeIdentityStore.recoverySecretKey),
      isNotNull,
    );

    await store.clear();
    expect(secureStore.values, isEmpty);
    expect(await store.read(), isNull);
  });

  test('legacy plain-text token rows migrate to secure storage', () async {
    await db.appSettingsDao
        .setValue(ChallengeIdentityStore.playerIdKey, 'player-1');
    await db.appSettingsDao
        .setValue(ChallengeIdentityStore.authTokenKey, 'legacy-token');
    final store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    );

    final identity = await store.read();

    expect(identity?.authToken, 'legacy-token');
    expect(
      secureStore.values[ChallengeIdentityStore.authTokenKey],
      'legacy-token',
    );
    expect(
      await db.appSettingsDao.getValue(ChallengeIdentityStore.authTokenKey),
      isNull,
      reason: 'the plain-text row must not outlive the migration',
    );
  });

  test('API client bootstraps before authenticated board list', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: ChallengeIdentityStore(
        dao: db.appSettingsDao,
        secureStore: secureStore,
      ),
      baseUrl: 'https://api.crosscue.test',
    );

    final summary = await api.listBoards();

    expect(summary.boards.single.name, 'Friday Crew');
    expect(summary.lifetime.cleanSolves, 0);
    expect(adapter.seenAuthHeader, 'Bearer token-1');

    final identity = await ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    ).read();
    expect(identity?.playerId, 'player-1');
    expect(identity?.authToken, 'token-1');
  });

  test('bootstrap persists the recovery secret', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    );
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: store,
      baseUrl: 'https://api.crosscue.test',
    );

    await api.bootstrap();

    final bundle = await store.readRecoveryBundle();
    expect(bundle?.playerId, 'player-1');
    expect(bundle?.recoverySecret, 'recovery-1');
  });

  test('restores from the recovery bundle instead of bootstrapping', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    );
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: store,
      baseUrl: 'https://api.crosscue.test',
    );

    // A recovery bundle exists (e.g. synced after a device restore) but there
    // is no auth token locally.
    await db.appSettingsDao.setValue('challenge_player_id', 'player-1');
    await db.appSettingsDao.setValue('challenge_recovery_secret', 'recovery-1');

    await api.listBoards();

    expect(adapter.bootstrapCalls, 0, reason: 'should restore, not bootstrap');
    expect(adapter.restoreCalls, 1);
    expect(adapter.lastRestoreBody?['playerId'], 'player-1');
    expect(adapter.seenAuthHeader, 'Bearer token-restored');
    expect((await store.read())?.authToken, 'token-restored');
  });

  test('rotateRecovery stores the new secret', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    );
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: store,
      baseUrl: 'https://api.crosscue.test',
    );
    await store.write(
      const ChallengeIdentity(
        playerId: 'player-1',
        authToken: 'token-1',
        recoverySecret: 'recovery-1',
      ),
    );

    await api.rotateRecovery();

    expect((await store.readRecoveryBundle())?.recoverySecret, 'recovery-2');
  });

  test('deleteAccount deletes the server player and clears identity', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    );
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: store,
      baseUrl: 'https://api.crosscue.test',
    );
    await store.write(
      const ChallengeIdentity(
        playerId: 'player-1',
        authToken: 'token-1',
        recoverySecret: 'recovery-1',
      ),
    );

    await api.deleteAccount();

    expect(adapter.deleteCalls, 1);
    expect(adapter.seenAuthHeader, 'Bearer token-1');
    expect(await store.read(), isNull);
    expect(await store.readRecoveryBundle(), isNull);
  });

  test('deleteAccount is a no-op without an identity', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: ChallengeIdentityStore(
        dao: db.appSettingsDao,
        secureStore: secureStore,
      ),
      baseUrl: 'https://api.crosscue.test',
    );

    await api.deleteAccount();

    expect(adapter.deleteCalls, 0);
    expect(adapter.bootstrapCalls, 0, reason: 'must not bootstrap to delete');
  });

  test('board list carries the owner id; removeMember issues DELETE', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: ChallengeIdentityStore(
        dao: db.appSettingsDao,
        secureStore: secureStore,
      ),
      baseUrl: 'https://api.crosscue.test',
    );

    final summary = await api.listBoards();
    expect(summary.boards.single.ownerPlayerId, 'player-1');

    await api.removeMember('board-1', 'player-2');
    expect(adapter.removedMemberPath, '/boards/board-1/members/player-2');
    expect(adapter.seenAuthHeader, 'Bearer token-1');
  });

  test('API client submits challenge results with auth', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: ChallengeIdentityStore(
        dao: db.appSettingsDao,
        secureStore: secureStore,
      ),
      baseUrl: 'https://api.crosscue.test',
    );

    await ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: secureStore,
    ).write(
      const ChallengeIdentity(playerId: 'player-1', authToken: 'token-1'),
    );

    await api.submitSolveResult(
      ChallengeSolveSubmission(
        sourceId: 'crosshare_daily_mini',
        sourcePuzzleId: '2026-06-05',
        completedAtUtc: DateTime.utc(2026, 6, 5, 12),
        elapsedMs: 91000,
        completionType: ChallengeCompletionType.clean,
        cleanSolveEligible: true,
        puzzleTitle: 'Daily Mini',
        publishedOn: DateTime.utc(2026, 6, 5),
      ),
    );

    expect(adapter.seenAuthHeader, 'Bearer token-1');
    expect(adapter.lastResultBody?['sourceId'], 'crosshare_daily_mini');
    expect(adapter.lastResultBody?['sourcePuzzleId'], '2026-06-05');
    expect(adapter.lastResultBody?['completionType'], 'clean');
    expect(adapter.lastResultBody?['cleanSolveEligible'], isTrue);
  });
}

class _FakeChallengeAdapter implements HttpClientAdapter {
  String? seenAuthHeader;
  Map<String, Object?>? lastResultBody;
  Map<String, Object?>? lastRestoreBody;
  int bootstrapCalls = 0;
  int restoreCalls = 0;
  int deleteCalls = 0;
  String? removedMemberPath;

  static const _player = {
    'id': 'player-1',
    'displayName': 'Maya',
    'isMe': true,
    'avatar': {'kind': 'silhouette', 'silhouetteLook': 1, 'photoUrl': null},
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path == '/players/bootstrap') {
      bootstrapCalls++;
      return _json({
        'player': _player,
        'authToken': 'token-1',
        'recoverySecret': 'recovery-1',
      });
    }

    if (path.contains('/members/') && options.method == 'DELETE') {
      removedMemberPath = path;
      seenAuthHeader = options.headers['authorization'] as String?;
      return _json({'ok': true});
    }

    if (path == '/players/me' && options.method == 'DELETE') {
      deleteCalls++;
      seenAuthHeader = options.headers['authorization'] as String?;
      return _json({'ok': true});
    }

    if (path == '/players/restore') {
      restoreCalls++;
      lastRestoreBody = options.data as Map<String, Object?>;
      return _json({'player': _player, 'authToken': 'token-restored'});
    }

    if (path == '/players/recovery/rotate') {
      seenAuthHeader = options.headers['authorization'] as String?;
      return _json({
        'recoverySecret': 'recovery-2',
        'rotatedAt': '2026-06-09T00:00:00.000Z',
      });
    }

    if (path == '/boards') {
      seenAuthHeader = options.headers['authorization'] as String?;
      return _json({
        'boards': [
          {
            'id': 'board-1',
            'name': 'Friday Crew',
            'playerCount': 1,
            'ownerPlayerId': 'player-1',
            'myWeekly': {
              'rank': 1,
              'outOf': 1,
              'cleanSolves': 0,
              'avgClean': '—',
            },
          },
        ],
        'lifetime': {
          'avgClean': '—',
          'cleanSolves': 0,
          'bestClean': '—',
          'rankingStatus': 'Solve 5 clean puzzles to unlock lifetime ranking',
          'weeksCounted': 0,
        },
      });
    }

    if (path == '/results') {
      seenAuthHeader = options.headers['authorization'] as String?;
      lastResultBody = options.data as Map<String, Object?>;
      return _json({'accepted': true}, statusCode: 202);
    }

    return _json({'error': 'not found'}, statusCode: 404);
  }

  ResponseBody _json(Object body, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
