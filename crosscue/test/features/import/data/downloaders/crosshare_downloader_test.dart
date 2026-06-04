import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/services/crosshare_daily_date.dart';
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
      final today = crosshareUtcDate().day;
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
      final today = crosshareUtcDate().day;
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
      final today = crosshareUtcDate().day;
      final wrongDay =
          (today % 28) + 1 == today ? (today % 28) + 2 : (today % 28) + 1;

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

    test('returns notFound when page returns HTTP 404', () async {
      // HTTP 404 on the month page means the requested month is before the
      // Crosshare archive start (April 2020). For downloadToday() this is
      // surfaced as notFound; for fetchMonth() it is beforeArchiveStart.
      final downloader = _downloaderWith((options) {
        if (options.path.contains('dailyminis')) {
          return ResponseBody.fromString('Not Found', 404);
        }
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.notFound);
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

    test('returns networkError when download hangs past hard timeout',
        () async {
      final dio = Dio();
      dio.httpClientAdapter = _HangingAdapter();
      // Inject a tiny hard timeout so this is fast and deterministic — the
      // real 35s default would make the test slow and race its own deadline
      // under load (the source of an intermittent flake).
      final downloader = CrosshareDownloader(
        dio: dio,
        hardTimeout: const Duration(milliseconds: 50),
      );

      final result = await downloader.downloadToday();
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.networkError);
    });

    // ── Request options ─────────────────────────────────────────────────────

    test(
        'sets connectTimeout and disables persistentConnection on page request',
        () async {
      final today = crosshareUtcDate().day;
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
      final today = crosshareUtcDate().day;
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

  // ---------------------------------------------------------------------------
  // fetchMonth — used by the Recently-missed listing
  // ---------------------------------------------------------------------------

  group('fetchMonth', () {
    /// Builds a month-archive HTML body with [entries] of (day, id, title).
    String monthHtml(List<(int day, String id, String title)> entries) {
      final puzzles = entries
          .map(
            (e) => [
              e.$1,
              {
                'id': e.$2,
                'title': e.$3,
                'authorName': 'A. Author',
                'size': {'cols': 5, 'rows': 5},
              },
            ],
          )
          .toList();
      final json = jsonEncode({
        'props': {
          'pageProps': {'puzzles': puzzles},
        },
      });
      return '<html><script id="__NEXT_DATA__" type="application/json">$json</script></html>';
    }

    test('parses every entry in the month into CrosshareEntry rows', () async {
      final downloader = _downloaderWith((options) {
        return ResponseBody.fromString(
          monthHtml(const [
            (10, 'id10', 'Puzzle Ten'),
            (5, 'id05', 'Puzzle Five'),
            (1, 'id01', 'Puzzle One'),
          ]),
          200,
        );
      });

      final result = await downloader.fetchMonth(2024, 3);
      expect(result.isOk, isTrue);
      final entries = result.value;
      expect(entries.length, 3);
      expect(entries.map((e) => e.id), ['id10', 'id05', 'id01']);
      expect(entries[0].title, 'Puzzle Ten');
      expect(entries[0].authorName, 'A. Author');
      expect(entries[0].width, 5);
      expect(entries[0].height, 5);
      expect(entries[0].date, DateTime.utc(2024, 3, 10));
      expect(entries[1].date, DateTime.utc(2024, 3, 5));
      expect(entries[2].date, DateTime.utc(2024, 3, 1));
    });

    test('downloadToday uses Crosshare UTC day and archive month', () async {
      final paths = <String>[];
      final utcEveningInUs = DateTime.parse('2026-06-03T20:05:00-04:00');
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          paths.add(options.path);
          if (options.path.contains('dailyminis')) {
            return ResponseBody.fromString(
              monthHtml(const [(4, 'utc-day', 'UTC Day')]),
              200,
            );
          }
          return ResponseBody.fromBytes(_fakePuzBytes, 200);
        });
      final withClock = CrosshareDownloader(
        dio: dio,
        now: () => utcEveningInUs,
      );

      final result = await withClock.downloadTodayWithMetadata();

      expect(result.isOk, isTrue);
      expect(result.value.entry.id, 'utc-day');
      expect(result.value.entry.date, DateTime.utc(2026, 6, 4));
      expect(paths.first, contains('/dailyminis/2026/6'));
    });

    test('returns beforeArchiveStart when the server returns HTTP 404',
        () async {
      final downloader = _downloaderWith((options) {
        return ResponseBody.fromString('Not Found', 404);
      });

      final result = await downloader.fetchMonth(2019, 12);
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareFetchMonthError.beforeArchiveStart);
    });

    test('returns networkError when Dio throws', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        });
      final downloader = CrosshareDownloader(dio: dio);

      final result = await downloader.fetchMonth(2024, 3);
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareFetchMonthError.networkError);
    });

    test('returns malformedPage when __NEXT_DATA__ is missing', () async {
      final downloader = _downloaderWith((options) {
        return ResponseBody.fromString('<html>no data here</html>', 200);
      });

      final result = await downloader.fetchMonth(2024, 3);
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareFetchMonthError.malformedPage);
    });

    test('skips entries with missing id or title', () async {
      final downloader = _downloaderWith((options) {
        final json = jsonEncode({
          'props': {
            'pageProps': {
              'puzzles': [
                [
                  1,
                  {'id': 'good', 'title': 'Good'},
                ],
                [
                  2,
                  {'title': 'No ID'},
                ],
                [
                  3,
                  {'id': 'no-title'},
                ],
              ],
            },
          },
        });
        return ResponseBody.fromString(
          '<html><script id="__NEXT_DATA__" type="application/json">$json</script></html>',
          200,
        );
      });

      final result = await downloader.fetchMonth(2024, 3);
      expect(result.isOk, isTrue);
      expect(result.value.map((e) => e.id), ['good']);
    });

    test('hits /dailyminis/{year}/{month} URL', () async {
      String? capturedPath;
      final downloader = _downloaderWith((options) {
        capturedPath = options.path;
        return ResponseBody.fromString(monthHtml(const []), 200);
      });

      await downloader.fetchMonth(2023, 7);
      expect(capturedPath, contains('/dailyminis/2023/7'));
    });
  });

  // ---------------------------------------------------------------------------
  // downloadById — direct .puz fetch by Crosshare ID
  // ---------------------------------------------------------------------------

  group('downloadById', () {
    test('returns the .puz bytes for the given id', () async {
      final downloader = _downloaderWith((options) {
        return ResponseBody.fromBytes(_fakePuzBytes, 200);
      });

      final result = await downloader.downloadById('abc123');
      expect(result.isOk, isTrue);
      expect(result.value, _fakePuzBytes);
    });

    test('returns networkError when the request fails', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        });
      final downloader = CrosshareDownloader(dio: dio);

      final result = await downloader.downloadById('abc123');
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.networkError);
    });

    test('returns networkError when status is non-200', () async {
      final downloader = _downloaderWith((options) {
        return ResponseBody.fromString('Server Error', 500);
      });

      final result = await downloader.downloadById('abc123');
      expect(result.isErr, isTrue);
      expect(result.error, CrosshareDownloadError.networkError);
    });
  });
}
