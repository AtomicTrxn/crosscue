import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/challenge_boards/data/services/avatar_photo_cache.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/providers/challenge_board_providers.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/player_avatar.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_secure_store.dart';

/// Dual-scheme avatar photos (#268, PR 1): `data:` URLs keep decoding to
/// in-memory bytes, `https:` URLs fetch through [AvatarPhotoCache], anything
/// else falls back to initials — same as a missing photo.

/// Smallest valid PNG (1×1 transparent) so Image.memory can really decode.
final _png = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const _photoUrl = 'https://api.crosscue.test/avatars/player-1/abc123.png';

void main() {
  group('ChallengeBoardApi avatar mapping', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<PlayerAvatar> mapAvatar(Object? photoUrl) async {
      final dio = Dio()..httpClientAdapter = _FakeBootstrapAdapter(photoUrl);
      final api = ChallengeBoardApi(
        dio: dio,
        identityStore: ChallengeIdentityStore(
          dao: db.appSettingsDao,
          secureStore: InMemorySecureKeyValueStore(),
        ),
        baseUrl: 'https://api.crosscue.test',
      );
      return (await api.bootstrap()).avatar;
    }

    test('data URL decodes to in-memory bytes (legacy scheme, kept forever)',
        () async {
      final avatar =
          await mapAvatar('data:image/png;base64,${base64Encode(_png)}');

      expect(avatar.kind, AvatarKind.photo);
      expect(avatar.photoBytes, _png);
      expect(avatar.photoUrl, isNull);
    });

    test('https URL passes through for lazy fetch', () async {
      final avatar = await mapAvatar(_photoUrl);

      expect(avatar.kind, AvatarKind.photo);
      expect(avatar.photoUrl, _photoUrl);
      expect(avatar.photoBytes, isNull);
    });

    test('non-https, non-data schemes are treated as no photo', () async {
      for (final url in [
        'http://api.crosscue.test/avatar.png',
        'file:///etc/passwd',
        'javascript:alert(1)',
        '',
        null,
      ]) {
        final avatar = await mapAvatar(url);
        expect(avatar.kind, AvatarKind.initials, reason: 'for $url');
      }
    });
  });

  group('AvatarPhotoCache', () {
    test('fetches once and serves repeats from cache', () async {
      final adapter = _FakePhotoAdapter(_png);
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      expect(await cache.load(_photoUrl), _png);
      expect(await cache.load(_photoUrl), _png);
      expect(cache.cached(_photoUrl), _png);
      expect(adapter.fetchCount, 1);
    });

    test('concurrent loads share one in-flight request', () async {
      final adapter = _FakePhotoAdapter(_png);
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      final results =
          await Future.wait([cache.load(_photoUrl), cache.load(_photoUrl)]);

      expect(results, everyElement(_png));
      expect(adapter.fetchCount, 1);
    });

    test('failure resolves null, is not cached, and recovers on retry',
        () async {
      final adapter = _FakePhotoAdapter(_png)..failNext = true;
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      expect(await cache.load(_photoUrl), isNull);
      expect(cache.cached(_photoUrl), isNull);
      // The failed fetch must not poison the cache: next load refetches.
      expect(await cache.load(_photoUrl), _png);
      expect(adapter.fetchCount, 2);
    });

    test('rejects non-https URLs without touching the network', () async {
      final adapter = _FakePhotoAdapter(_png);
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      expect(await cache.load('http://api.crosscue.test/a.png'), isNull);
      expect(await cache.load('file:///etc/passwd'), isNull);
      expect(adapter.fetchCount, 0);
    });

    test('evicts least-recently-used entries beyond maxEntries', () async {
      final adapter = _FakePhotoAdapter(_png);
      final cache = AvatarPhotoCache(
        dio: Dio()..httpClientAdapter = adapter,
        maxEntries: 2,
      );

      await cache.load('https://cdn.test/1.png');
      await cache.load('https://cdn.test/2.png');
      cache.cached('https://cdn.test/1.png'); // 1 is now most recently used.
      await cache.load('https://cdn.test/3.png'); // Evicts 2.

      expect(cache.cached('https://cdn.test/1.png'), isNotNull);
      expect(cache.cached('https://cdn.test/2.png'), isNull);
      expect(cache.cached('https://cdn.test/3.png'), isNotNull);
    });
  });

  group('PlayerAvatarView', () {
    Widget harness(PlayerAvatar avatar, AvatarPhotoCache cache) {
      return ProviderScope(
        overrides: [avatarPhotoCacheProvider.overrideWithValue(cache)],
        child: MaterialApp(
          home: PlayerAvatarView(avatar: avatar, name: 'Maya Chen'),
        ),
      );
    }

    Finder photoImage() => find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is MemoryImage,
        );

    testWidgets('data-URL photo bytes still render as an image',
        (tester) async {
      final cache = AvatarPhotoCache(dio: Dio());

      await tester.pumpWidget(harness(PlayerAvatar.photoBytes(_png), cache));

      expect(photoImage(), findsOneWidget);
      expect(find.text('MC'), findsNothing);
    });

    testWidgets('https photo fetches via Dio and pops in over initials',
        (tester) async {
      final adapter = _FakePhotoAdapter(_png);
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      await tester
          .pumpWidget(harness(const PlayerAvatar.photo(_photoUrl), cache));
      // Quiet placeholder while the fetch is in flight — initials, no spinner.
      expect(find.text('MC'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpAndSettle();
      expect(photoImage(), findsOneWidget);
      expect(find.text('MC'), findsNothing);
      expect(adapter.fetchCount, 1);
    });

    testWidgets('fetch failure falls back to initials, never crashes',
        (tester) async {
      final adapter = _FakePhotoAdapter(_png)..failNext = true;
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      await tester
          .pumpWidget(harness(const PlayerAvatar.photo(_photoUrl), cache));
      await tester.pumpAndSettle();

      expect(find.text('MC'), findsOneWidget);
      expect(photoImage(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('second render of the same URL hits the cache — no refetch',
        (tester) async {
      final adapter = _FakePhotoAdapter(_png);
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      await tester
          .pumpWidget(harness(const PlayerAvatar.photo(_photoUrl), cache));
      await tester.pumpAndSettle();
      expect(adapter.fetchCount, 1);

      // Tear the avatar down and render it again from scratch.
      await tester.pumpWidget(const SizedBox());
      await tester
          .pumpWidget(harness(const PlayerAvatar.photo(_photoUrl), cache));

      // Cached bytes render synchronously — no placeholder frame, no fetch.
      expect(photoImage(), findsOneWidget);
      expect(adapter.fetchCount, 1);
    });

    testWidgets('non-https URL renders initials without a network attempt',
        (tester) async {
      final adapter = _FakePhotoAdapter(_png);
      final cache = AvatarPhotoCache(dio: Dio()..httpClientAdapter = adapter);

      await tester.pumpWidget(
        harness(const PlayerAvatar.photo('file:///etc/passwd'), cache),
      );
      await tester.pumpAndSettle();

      expect(find.text('MC'), findsOneWidget);
      expect(adapter.fetchCount, 0);
    });
  });
}

/// Serves only `/players/bootstrap`, echoing a photo avatar with the
/// configured `photoUrl` so mapping can be asserted per scheme.
class _FakeBootstrapAdapter implements HttpClientAdapter {
  _FakeBootstrapAdapter(this.photoUrl);

  final Object? photoUrl;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path != '/players/bootstrap') {
      return ResponseBody.fromString('{"error":"not found"}', 404);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'player': {
          'id': 'player-1',
          'displayName': 'Maya',
          'isMe': true,
          'avatar': {'kind': 'photo', 'photoUrl': photoUrl},
        },
        'authToken': 'token-1',
        'recoverySecret': 'recovery-1',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Serves [bytes] as a PNG for any GET; counts fetches and can fail once.
class _FakePhotoAdapter implements HttpClientAdapter {
  _FakePhotoAdapter(this.bytes);

  final Uint8List bytes;
  int fetchCount = 0;
  bool failNext = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount++;
    if (failNext) {
      failNext = false;
      return ResponseBody.fromString('gone', 404);
    }
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['image/png'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
