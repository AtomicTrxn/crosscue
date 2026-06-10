// Widget test for the "Clear all data" → sync teardown wiring on the Privacy
// screen. Drives the real SyncController/SyncOrchestrator over an in-memory DB
// + FakeSyncTransport (no device / OAuth needed). Verifies the cloud copy is
// kept by default and only wiped on the explicit second confirm.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/presentation/providers/challenge_board_providers.dart';
import 'package:crosscue/features/settings/domain/models/boot_settings.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/settings/presentation/screens/privacy_screen.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase db;
  late Map<String, String> cloud;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cloud = <String, String>{};
  });
  tearDown(() => db.close());

  Future<void> insertPuzzle(String id) async {
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

  Future<int> puzzleCount() async =>
      (await db.select(db.puzzlesTable).get()).length;

  Future<ProviderContainer> pumpPrivacy(
    WidgetTester tester, {
    ChallengeBoardApi? challengeApi,
  }) async {
    final router = GoRouter(
      initialLocation: Routes.privacySettings,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: Routes.privacySettings,
          builder: (_, __) => const PrivacyScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          bootSettingsProvider.overrideWithValue(BootSettings.defaults),
          syncTransportProvider
              .overrideWithValue(FakeSyncTransport(store: cloud)),
          if (challengeApi != null)
            challengeBoardApiProvider.overrideWithValue(challengeApi),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(PrivacyScreen)),
    );
  }

  Future<void> tapClearThenDeleteEverything(WidgetTester tester) async {
    await tester.tap(find.text('Clear all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
  }

  testWidgets('sync on + "Keep cloud copy": local wiped, cloud kept',
      (tester) async {
    final container = await pumpPrivacy(tester);
    await container.read(appSettingsProvider).setSyncEnabled(true);
    await insertPuzzle('p1');
    cloud['puzzles/p1.json'] = '{"blob":1}';

    await tapClearThenDeleteEverything(tester);
    // Second dialog appears because sync is enabled.
    expect(find.textContaining('Also delete'), findsOneWidget);
    await tester.tap(find.text('Keep cloud copy'));
    await tester.pumpAndSettle();

    expect(await puzzleCount(), 0, reason: 'local data wiped');
    expect(
      cloud,
      contains('puzzles/p1.json'),
      reason: 'cloud copy kept by default',
    );
    expect(
      await container.read(appSettingsProvider).getSyncEnabled(),
      isFalse,
      reason: 'sync turned off so the device does not re-pull the cloud',
    );
  });

  testWidgets('sync on + "Delete cloud copy": local AND cloud wiped',
      (tester) async {
    final container = await pumpPrivacy(tester);
    await container.read(appSettingsProvider).setSyncEnabled(true);
    await insertPuzzle('p1');
    cloud['puzzles/p1.json'] = '{"blob":1}';
    cloud['sessions/p1.json'] = '{"blob":2}';

    await tapClearThenDeleteEverything(tester);
    await tester.tap(find.text('Delete cloud copy'));
    await tester.pumpAndSettle();

    expect(await puzzleCount(), 0);
    expect(cloud, isEmpty, reason: 'cloud copy wiped on explicit confirm');
  });

  testWidgets('sync off: no cloud prompt, local wiped', (tester) async {
    await pumpPrivacy(tester);
    await insertPuzzle('p1');

    await tapClearThenDeleteEverything(tester);

    // No second dialog when sync was never enabled.
    expect(find.textContaining('Also delete'), findsNothing);
    expect(await puzzleCount(), 0);
  });

  testWidgets('cancelling the cloud prompt aborts the whole clear',
      (tester) async {
    final container = await pumpPrivacy(tester);
    await container.read(appSettingsProvider).setSyncEnabled(true);
    await insertPuzzle('p1');

    await tapClearThenDeleteEverything(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await puzzleCount(), 1, reason: 'nothing deleted on cancel');
    expect(
      await container.read(appSettingsProvider).getSyncEnabled(),
      isTrue,
      reason: 'sync left untouched',
    );
  });

  testWidgets('clear all data also deletes the Challenge Boards account',
      (tester) async {
    final adapter = _RecordingChallengeAdapter();
    final api = ChallengeBoardApi(
      dio: Dio()..httpClientAdapter = adapter,
      identityStore: ChallengeIdentityStore(dao: db.appSettingsDao),
      baseUrl: 'https://api.crosscue.test',
    );
    // Seed a challenge identity so deletion has something to delete.
    await db.appSettingsDao.setValue('challenge_player_id', 'player-1');
    await db.appSettingsDao.setValue('challenge_auth_token', 'token-1');

    await pumpPrivacy(tester, challengeApi: api);
    await insertPuzzle('p1');

    await tapClearThenDeleteEverything(tester);

    expect(adapter.deleteCalls, 1, reason: 'server player deleted');
    expect(adapter.seenAuthHeader, 'Bearer token-1');
    expect(await puzzleCount(), 0, reason: 'local data wiped after deletion');
    expect(
      await db.appSettingsDao.getValue('challenge_player_id'),
      isNull,
      reason: 'local challenge identity cleared',
    );
  });
}

class _RecordingChallengeAdapter implements HttpClientAdapter {
  int deleteCalls = 0;
  String? seenAuthHeader;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path == '/players/me' && options.method == 'DELETE') {
      deleteCalls++;
      seenAuthHeader = options.headers['authorization'] as String?;
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
