// Dart consumer of the shared API contract fixtures (#260).
//
// Fixtures live in backend/challenge_boards/contract-fixtures/ and are the
// single source of truth for the wire shapes, also consumed by the Worker's
// contract.test.mjs. Here the REAL ChallengeBoardApi parses each fixture
// response (via a fake Dio adapter) into typed models, and the request bodies
// it builds are matched back against the fixtures. A field renamed in a
// fixture — or drift on either side — fails this suite and the Worker's.
//
// Placeholder tokens (<string>/<int>/<iso>/<url>) are matched structurally;
// see the fixtures README.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_secure_store.dart';

const _fixtureDir = 'backend/challenge_boards/contract-fixtures';

Map<String, Object?> _fixture(String name) {
  final file = File('$_fixtureDir/$name.json');
  if (!file.existsSync()) {
    fail('Missing fixture $name.json — run from the crosscue/ package root.');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

Object? _responseBody(String name) =>
    (_fixture(name)['response'] as Map<String, Object?>)['body'];
int _responseStatus(String name) =>
    (_fixture(name)['response'] as Map<String, Object?>)['status'] as int;
Map<String, Object?>? _requestBody(String name) =>
    (_fixture(name)['request'] as Map<String, Object?>)['body']
        as Map<String, Object?>?;

/// Structural match against a fixture value: `<string>`/`<int>`/`<iso>`/`<url>`
/// tokens match by type; maps must have the exact same key set; everything
/// else matches exactly.
void expectMatchesFixture(
  Object? actual,
  Object? expected, [
  String path = r'$',
]) {
  if (expected is String &&
      expected.startsWith('<') &&
      expected.endsWith('>')) {
    switch (expected) {
      case '<string>':
        expect(actual, isA<String>(), reason: path);
        return;
      case '<int>':
        expect(actual, isA<int>(), reason: path);
        return;
      case '<iso>':
        expect(actual, isA<String>(), reason: path);
        expect(
          () => DateTime.parse(actual! as String),
          returnsNormally,
          reason: '$path is not an ISO datetime',
        );
        return;
      case '<url>':
        expect(actual, isA<String>(), reason: path);
        expect((actual! as String).startsWith('http'), isTrue, reason: path);
        return;
    }
  }
  if (expected is Map) {
    expect(actual, isA<Map>(), reason: path);
    final a = (actual! as Map).cast<String, Object?>();
    expect(
      a.keys.toSet(),
      expected.keys.cast<String>().toSet(),
      reason: '$path key set differs',
    );
    for (final key in expected.keys) {
      expectMatchesFixture(a[key], expected[key], '$path.$key');
    }
    return;
  }
  if (expected is List) {
    expect(actual, isA<List>(), reason: path);
    final a = actual! as List;
    expect(a.length, expected.length, reason: '$path length differs');
    for (var i = 0; i < expected.length; i++) {
      expectMatchesFixture(a[i], expected[i], '$path[$i]');
    }
    return;
  }
  expect(actual, expected, reason: path);
}

/// Serves [name]'s fixture response and captures the request body the client
/// builds, so a single fixture exercises both parse and serialize directions.
class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.name);

  final String name;
  Object? capturedRequestData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedRequestData = options.data;
    return ResponseBody.fromString(
      jsonEncode(_responseBody(name)),
      _responseStatus(name),
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late ChallengeIdentityStore store;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = ChallengeIdentityStore(
      dao: db.appSettingsDao,
      secureStore: InMemorySecureKeyValueStore(),
    );
    // Seed an identity so authenticated calls don't auto-bootstrap (which
    // would hit the adapter expecting a different fixture).
    await store.write(
      const ChallengeIdentity(playerId: 'player-1', authToken: 'token-1'),
    );
  });

  tearDown(() => db.close());

  ({ChallengeBoardApi api, _FixtureAdapter adapter}) apiFor(String fixture) {
    final adapter = _FixtureAdapter(fixture);
    final api = ChallengeBoardApi(
      dio: Dio()..httpClientAdapter = adapter,
      identityStore: store,
      baseUrl: 'https://api.crosscue.test',
    );
    return (api: api, adapter: adapter);
  }

  // ── Response parsing: the real client maps each fixture without loss ──

  test('players_bootstrap parses + sends the documented request', () async {
    final f = apiFor('players_bootstrap');
    final player = await f.api.bootstrap(displayName: 'Maya');
    expect(player.displayName, 'Maya');
    expect(player.isMe, isTrue);
    expectMatchesFixture(
      f.adapter.capturedRequestData,
      _requestBody('players_bootstrap'),
    );
  });

  test('players_me_get parses', () async {
    final player = await apiFor('players_me_get').api.getProfile();
    expect(player.displayName, 'Maya');
  });

  test('players_me_patch parses + sends the documented request', () async {
    final f = apiFor('players_me_patch');
    final player = await f.api.updateDisplayName('Maya');
    expect(player.displayName, 'Maya');
    expectMatchesFixture(
      f.adapter.capturedRequestData,
      _requestBody('players_me_patch'),
    );
  });

  test('players_recovery_rotate parses', () async {
    await apiFor('players_recovery_rotate').api.rotateRecovery();
    // Completes without throwing; the new secret is persisted.
    expect((await store.read())?.recoverySecret, isNotNull);
  });

  test('boards_create parses + sends the documented request', () async {
    final f = apiFor('boards_create');
    final created = await f.api.createBoard(
      const CreateBoardDraft(
        name: 'Friday Crew',
        rankingMode: ChallengeRankingMode.averageTime,
      ),
    );
    expect(created.board.name, 'Friday Crew');
    expect(created.inviteLink, isA<String>()); // fixture token, parsed as-is
    expectMatchesFixture(
      f.adapter.capturedRequestData,
      _requestBody('boards_create'),
    );
  });

  test('boards_list parses', () async {
    final summary = await apiFor('boards_list').api.listBoards();
    expect(summary.boards.single.name, 'Friday Crew');
    expect(summary.lifetime.cleanSolves, 0);
  });

  test('boards_detail parses', () async {
    final detail = await apiFor('boards_detail').api.getBoardDetail('board-1');
    expect(detail.board.playerCount, 1);
    expect(detail.weekly.single.rank, 1);
    expect(detail.weekly.single.player.isMe, isTrue);
    expect(detail.lifetime.single.rank, 1);
  });

  test('boards_invite_regenerate parses', () async {
    final link =
        await apiFor('boards_invite_regenerate').api.regenerateInvite('b');
    expect(link, isA<String>()); // fixture token, parsed as-is
  });

  test('invites_preview_valid parses', () async {
    final preview =
        await apiFor('invites_preview_valid').api.previewInvite('u');
    expect(preview.result, InviteResult.valid);
    expect(preview.boardName, 'Friday Crew');
    expect(preview.daysUntilExpiry, 30);
  });

  test('invites_preview_invalid parses', () async {
    final preview =
        await apiFor('invites_preview_invalid').api.previewInvite('u');
    expect(preview.result, InviteResult.invalidOrExpired);
  });

  test('invites_join parses', () async {
    final board = await apiFor('invites_join').api.joinInvite('u');
    expect(board?.playerCount, 2);
  });

  // ── Request serialization: every results fixture's body matches toJson ──

  test('results fixtures match the submission the client builds', () async {
    final submission = ChallengeSolveSubmission(
      sourceId: 'crosshare_daily_mini',
      sourcePuzzleId: '2026-06-05',
      completedAtUtc: DateTime.utc(2026, 6, 5, 12, 34, 56),
      elapsedMs: 91000,
      completionType: ChallengeCompletionType.clean,
      cleanSolveEligible: true,
      puzzleTitle: 'Daily Mini',
      publishedOn: DateTime.utc(2026, 6, 5),
    );
    final f = apiFor('results_accepted');
    await f.api.submitSolveResult(submission);
    expectMatchesFixture(
      f.adapter.capturedRequestData,
      _requestBody('results_accepted'),
    );
  });

  test('every fixture file is valid and shaped', () {
    final dir = Directory(_fixtureDir);
    final files =
        dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
    expect(files, isNotEmpty, reason: 'fixtures directory should be populated');
    for (final file in files) {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      expect(json['request'], isA<Map>(), reason: '${file.path} request');
      expect(json['response'], isA<Map>(), reason: '${file.path} response');
      final response = json['response'] as Map<String, Object?>;
      expect(response['status'], isA<int>(), reason: '${file.path} status');
      expect(response.containsKey('body'), isTrue, reason: '${file.path} body');
    }
  });
}
