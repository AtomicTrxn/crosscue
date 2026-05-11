import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/utils/result.dart';
import 'package:dio/dio.dart';

/// Errors that can occur when downloading a Crosshare puzzle.
enum CrosshareDownloadError {
  /// No puzzle entry matching today's date was found on the dailyminis page.
  notFound,

  /// A network request failed (timeout, HTTP error, no connection).
  networkError,

  /// The HTML page was fetched successfully but could not be parsed.
  /// The Crosshare page structure may have changed.
  malformedPage,
}

/// Downloads the Crosshare daily mini crossword as raw .puz bytes.
///
/// Two-step process:
///   1. GET https://crosshare.org/dailyminis/{year}/{month} — parse the
///      embedded __NEXT_DATA__ JSON to find today's puzzle ID.
///   2. GET https://crosshare.org/api/puz/{id} — fetch the .puz file.
///
/// The __NEXT_DATA__ blob has the shape:
///   { props: { pageProps: { puzzles: [[dayOfMonth, {id, title, …}, …], …] } } }
///
/// Downloaded puzzle bytes are persisted to the local database via
/// [ImportRepository]. No raw bytes are retained beyond the import call.
class CrosshareDownloader {
  CrosshareDownloader({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _dailyMinisBase = 'https://crosshare.org/dailyminis';
  static const _puzApiBase = 'https://crosshare.org/api/puz';
  static const _userAgent = 'Crosscue/1.2 (Android; crosscue app)';

  // Per-request timeouts (connect + receive each).
  static const _connectTimeout = Duration(seconds: 10);
  static const _pageReceiveTimeout = Duration(seconds: 15);
  static const _puzReceiveTimeout = Duration(seconds: 10);

  // Hard wall-clock cap for the entire two-step download.
  // Dio's receiveTimeout only resets between chunks; if the server stalls
  // mid-stream (or a middlebox drops packets silently after the TCP handshake),
  // Dio can hang indefinitely. This guard guarantees we always return.
  static const _hardTimeout = Duration(seconds: 35);

  // Max HTML response body size.
  static const _maxHtmlBytes = 10 * 1024 * 1024; // 10 MB

  Future<Result<Uint8List, CrosshareDownloadError>> downloadToday() {
    return _doDownload().timeout(
      _hardTimeout,
      onTimeout: () => const Err(CrosshareDownloadError.networkError),
    );
  }

  Future<Result<Uint8List, CrosshareDownloadError>> _doDownload() async {
    try {
      final id = await _findTodayPuzzleId();
      if (id == null) return const Err(CrosshareDownloadError.notFound);

      final response = await _dio.get<List<int>>(
        '$_puzApiBase/$id',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'User-Agent': _userAgent},
          connectTimeout: _connectTimeout,
          receiveTimeout: _puzReceiveTimeout,
          // Disable keep-alive so a stale connection from a previous attempt
          // cannot be reused and cause a silent hang.
          persistentConnection: false,
        ),
      );
      if (response.statusCode != 200 || response.data == null) {
        return const Err(CrosshareDownloadError.networkError);
      }
      return Ok(Uint8List.fromList(response.data!));
    } on DioException {
      return const Err(CrosshareDownloadError.networkError);
    } on _MalformedPageException {
      return const Err(CrosshareDownloadError.malformedPage);
    } catch (_) {
      return const Err(CrosshareDownloadError.networkError);
    }
  }

  /// Fetches the month page and extracts today's puzzle ID from the embedded
  /// Next.js data blob.
  ///
  /// Returns `null` if today's puzzle is not listed.
  /// Throws [_MalformedPageException] if the page was fetched but could not be
  /// parsed — callers treat this as a distinct failure.
  Future<String?> _findTodayPuzzleId() async {
    final today = DateTime.now();
    final url = '$_dailyMinisBase/${today.year}/${today.month}';

    final Response<String> response;
    try {
      response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': _userAgent},
          connectTimeout: _connectTimeout,
          receiveTimeout: _pageReceiveTimeout,
          persistentConnection: false,
        ),
      );
    } on DioException {
      rethrow; // propagate as networkError in caller
    }

    if (response.statusCode != 200 || response.data == null) return null;

    final html = response.data!;
    if (html.length > _maxHtmlBytes) {
      throw const _MalformedPageException('HTML response too large');
    }

    // Extract the __NEXT_DATA__ JSON block via regex to avoid index arithmetic.
    final match = RegExp(
      r'<script[^>]+id="__NEXT_DATA__"[^>]*type="application/json"[^>]*>([\s\S]*?)</script>',
    ).firstMatch(html);
    if (match == null) {
      throw const _MalformedPageException(
        '__NEXT_DATA__ script block not found',
      );
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(match.group(1)!) as Map<String, dynamic>;
    } catch (e) {
      throw _MalformedPageException('Failed to decode __NEXT_DATA__ JSON: $e');
    }

    // Navigate: props → pageProps → puzzles → [[day, {id, …}, …], …]
    final props = data['props'] as Map<String, dynamic>?;
    final pageProps = props?['pageProps'] as Map<String, dynamic>?;
    final puzzles = pageProps?['puzzles'] as List<dynamic>?;
    if (puzzles == null) {
      throw const _MalformedPageException(
        'Expected puzzles array at props.pageProps.puzzles',
      );
    }

    for (final entry in puzzles) {
      if (entry is! List || entry.length < 2) continue;
      if (entry[0] == today.day) {
        final puzzleData = entry[1];
        if (puzzleData is Map) {
          return puzzleData['id'] as String?;
        }
      }
    }
    return null; // Today's puzzle not in list → notFound
  }
}

/// Internal sentinel thrown when HTML parsing fails; converted to
/// [CrosshareDownloadError.malformedPage] by [_doDownload].
class _MalformedPageException implements Exception {
  const _MalformedPageException(this.message);
  final String message;

  @override
  String toString() => '_MalformedPageException: $message';
}
