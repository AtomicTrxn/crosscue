import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('identity store persists player id and auth token', () async {
    final store = ChallengeIdentityStore(dao: db.appSettingsDao);

    await store.write(
      const ChallengeIdentity(playerId: 'player-1', authToken: 'token-1'),
    );

    final identity = await store.read();
    expect(identity?.playerId, 'player-1');
    expect(identity?.authToken, 'token-1');
  });

  test('API client bootstraps before authenticated board list', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: ChallengeIdentityStore(dao: db.appSettingsDao),
      baseUrl: 'https://api.crosscue.test',
    );

    final summary = await api.listBoards();

    expect(summary.boards.single.name, 'Friday Crew');
    expect(summary.lifetime.cleanSolves, 0);
    expect(adapter.seenAuthHeader, 'Bearer token-1');

    final identity =
        await ChallengeIdentityStore(dao: db.appSettingsDao).read();
    expect(identity?.playerId, 'player-1');
    expect(identity?.authToken, 'token-1');
  });

  test('API client submits challenge results with auth', () async {
    final adapter = _FakeChallengeAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ChallengeBoardApi(
      dio: dio,
      identityStore: ChallengeIdentityStore(dao: db.appSettingsDao),
      baseUrl: 'https://api.crosscue.test',
    );

    await ChallengeIdentityStore(dao: db.appSettingsDao).write(
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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path == '/players/bootstrap') {
      return _json({
        'player': {
          'id': 'player-1',
          'displayName': 'Maya',
          'isMe': true,
          'avatar': {
            'kind': 'silhouette',
            'silhouetteLook': 1,
            'photoUrl': null,
          },
        },
        'authToken': 'token-1',
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
