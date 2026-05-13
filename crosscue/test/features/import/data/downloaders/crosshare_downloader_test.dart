import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake Dio adapter — returns canned responses without network
// ---------------------------------------------------------------------------

typedef _ResponseFn = ResponseBody Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final _ResponseFn _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Adapter whose [fetch] never completes — used to verify the hard timeout.
class _HangingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(const Duration(days: 1));
    throw StateError('should never reach here');
  }

  @override
  void close({bool force = false}) {}
}

/// Creates a [CrosshareDownloader] backed by a fake adapter.
CrosshareDownloader _downloaderWith(_ResponseFn handler) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter(handler);
  return CrosshareDownloader(dio: dio);
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Minimal valid __NEXT_DATA__ HTML containing day [day] with puzzle id [id].
String _htmlWithPuzzle(int day, String id) {
  final json = jsonEncode({
    'props': {
      'pageProps': {
        'puzzles': [
          [
            day,
            {'id': id, 'title': 'Test Puzzle'},
          ],
        ],
      },
    },
  });
  return '<html><script id="__NEXT_DATA__" type="application/json">$json</script></html>';
}

/// Valid .puz bytes (just needs to be non-empty bytes for these tests).
final Uint8List _fakePuzBytes = Uint8List.fromList([0x41, 0x43, 0x52, 0x4F]);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CrosshareDownloader', () {
    // ── Happy path ──────────────────────────────────────────────────────────

    test('returns Ok with puz bytes when both requests succeed', () async {
      final today = DateTime.now().day;
      const puzzleId = 'abc123';

      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString(
            _htmlWithPuzzle(today, puzzleId),
            200,
          );
        }
        // puz endpoint
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadToday();
      expect(result.isOk, isTrue);
      expect(result.value, equals(_fakePuzBytes));
    });

    test('sets User-Agent header on page request', () async {
      final today = DateTime.now().day;
      String? capturedAgent;

      final downloader = _downloaderWith((options) {
        capturedAgent = options.headers['User-Agent'] as String?;
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString(
            _htmlWithPuzzle(today, 'x'),
            200,
          );
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      await downloader.downloadToday();
      expect(capturedAgent, contains('Crosscue'));
    });

    // ── notFound ────────────────────────────────────────────────────────────

    test('returns notFound when today is absent from puzzle list', () async {
      // Use a day that won't match today's day
      final wrongDay = (DateTime.now().day % 28) + 1 == DateTime.now().day
          ? (DateTime.now().day % 28) + 2
          : (DateTime.now().day % 28) + 1;

      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString(
            _htmlWithPuzzle(wrongDay, 'xyz'),
            200,
          );
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.notFound);
    });

    test('returns networkError when page returns HTTP 404', () async {
      // A 404 from the server causes Dio to throw DioException → networkError.
      // notFound is reserved for HTTP-200 responses where today is absent from the list.
      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString('Not Found', 404);
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.networkError);
    });

    // ── malformedPage ───────────────────────────────────────────────────────

    test('returns malformedPage when __NEXT_DATA__ block is missing', () async {
      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString('<html>no data here</html>', 200);
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.malformedPage);
    });

    test('returns malformedPage when JSON is invalid', () async {
      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString(
            '<html><script id="__NEXT_DATA__" type="application/json">'
            'not-valid-json'
            '</script></html>',
            200,
          );
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.malformedPage);
    });

    test('returns malformedPage when puzzles array is absent from JSON',
        () async {
      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          final json = jsonEncode({
            'props': {'pageProps': {}},
          });
          return ResponseBody.fromString(
            '<html><script id="__NEXT_DATA__" type="application/json">'
            '$json</script></html>',
            200,
          );
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.malformedPage);
    });

    // ── networkError ────────────────────────────────────────────────────────

    test('returns networkError when Dio throws DioException', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });
      final downloader = CrosshareDownloader(dio: dio);

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.networkError);
    });

    // ── Hard timeout ────────────────────────────────────────────────────────

    test(
      'returns networkError when download hangs past hard timeout',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _HangingAdapter();
        final downloader = CrosshareDownloader(dio: dio);

        final result = await downloader.downloadToday();
        expect(result.isErr, isTrue);
        expect(result.error, CrosshareDownloadError.networkError);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // ── Request options ─────────────────────────────────────────────────────

    test(
        'sets connectTimeout and disables persistentConnection on page request',
        () async {
      final today = DateTime.now().day;
      Duration? capturedConnectTimeout;
      bool? capturedPersistentConnection;

      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          capturedConnectTimeout = options.connectTimeout;
          capturedPersistentConnection = options.persistentConnection;
          return ResponseBody.fromString(
            _htmlWithPuzzle(today, 'opt-test'),
            200,
          );
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      await downloader.downloadToday();
      expect(capturedConnectTimeout, isNotNull);
      expect(capturedConnectTimeout!.inSeconds, greaterThan(0));
      expect(capturedPersistentConnection, isFalse);
    });

    test('sets connectTimeout and disables persistentConnection on puz request',
        () async {
      final today = DateTime.now().day;
      Duration? capturedConnectTimeout;
      bool? capturedPersistentConnection;

      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString(
            _htmlWithPuzzle(today, 'opt-test2'),
            200,
          );
        }
        // puz endpoint
        capturedConnectTimeout = options.connectTimeout;
        capturedPersistentConnection = options.persistentConnection;
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      await downloader.downloadToday();
      expect(capturedConnectTimeout, isNotNull);
      expect(capturedConnectTimeout!.inSeconds, greaterThan(0));
      expect(capturedPersistentConnection, isFalse);
    });
  });
}
