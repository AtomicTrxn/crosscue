import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/domain/models/crosshare_entry.dart';
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

/// Errors specific to fetching a Crosshare archive month listing.
enum CrosshareFetchMonthError {
  /// HTTP 404 — the month is before April 2020 (the archive floor).
  beforeArchiveStart,

  /// A network request failed (timeout, HTTP error, no connection).
  networkError,

  /// The HTML page was fetched successfully but could not be parsed.
  malformedPage,
}

/// Downloads Crosshare daily-mini crosswords as raw .puz bytes.
///
/// The Crosshare archive at `https://crosshare.org/dailyminis/{year}/{month}`
/// exposes a Next.js page whose `__NEXT_DATA__` JSON blob lists 28-31 entries
/// per month back to April 2020. Each entry carries the puzzle's stable ID
/// (used as `sourcePuzzleId` once imported), title, author, and grid size.
///
/// Two endpoints are involved:
///   1. `GET /dailyminis/{year}/{month}` — lists puzzles for a month.
///   2. `GET /api/puz/{id}` — returns the raw .puz bytes for one puzzle.
///
/// Downloaded puzzle bytes are persisted via the import repository. No raw
/// bytes are retained beyond the import call.
class CrosshareDownloader {
  CrosshareDownloader({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _dailyMinisBase = 'https://crosshare.org/dailyminis';
  static const _puzApiBase = 'https://crosshare.org/api/puz';
  static final _userAgent =
      'Crosscue/1.2 (${Platform.operatingSystem}; crosscue app)';

  // Per-request timeouts (connect + receive each).
  static const _connectTimeout = Duration(seconds: 10);
  static const _pageReceiveTimeout = Duration(seconds: 15);
  static const _puzReceiveTimeout = Duration(seconds: 10);

  // Hard wall-clock cap for the entire two-step downloadToday() call.
  // Dio's receiveTimeout only resets between chunks; if the server stalls
  // mid-stream (or a middlebox drops packets silently after the TCP handshake),
  // Dio can hang indefinitely. This guard guarantees we always return.
  static const _hardTimeout = Duration(seconds: 35);

  // Max HTML response body size.
  static const _maxHtmlBytes = 10 * 1024 * 1024; // 10 MB

  /// Downloads today's daily-mini .puz bytes. Convenience wrapper over
  /// [fetchMonth] + [downloadById] with a hard wall-clock timeout.
  Future<Result<Uint8List, CrosshareDownloadError>> downloadToday() {
    return _doDownloadToday().timeout(
      _hardTimeout,
      onTimeout: () => const Err(CrosshareDownloadError.networkError),
    );
  }

  Future<Result<Uint8List, CrosshareDownloadError>> _doDownloadToday() async {
    final today = DateTime.now();
    final fetch = await fetchMonth(today.year, today.month);
    if (fetch.isErr) {
      return Err(_fetchToDownloadError(fetch.error));
    }
    final entries = fetch.value;
    final entry = entries.where((e) => e.date.day == today.day).firstOrNull;
    if (entry == null) {
      return const Err(CrosshareDownloadError.notFound);
    }
    return downloadById(entry.id);
  }

  /// Lists daily-mini entries for the given [year]/[month] from the Crosshare
  /// archive. Returns the entries in publish-day order (most recent first, as
  /// served by Crosshare).
  ///
  /// Returns [CrosshareFetchMonthError.beforeArchiveStart] for months before
  /// April 2020 (Crosshare returns HTTP 404 there).
  Future<Result<List<CrosshareEntry>, CrosshareFetchMonthError>> fetchMonth(
    int year,
    int month,
  ) async {
    final url = '$_dailyMinisBase/$year/$month';

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
          // Treat 404 as a typed signal, not a thrown exception.
          validateStatus: (status) =>
              status != null && (status == 200 || status == 404),
        ),
      );
    } on DioException {
      return const Err(CrosshareFetchMonthError.networkError);
    }

    if (response.statusCode == 404) {
      return const Err(CrosshareFetchMonthError.beforeArchiveStart);
    }
    if (response.statusCode != 200 || response.data == null) {
      return const Err(CrosshareFetchMonthError.networkError);
    }

    final html = response.data!;
    if (html.length > _maxHtmlBytes) {
      return const Err(CrosshareFetchMonthError.malformedPage);
    }

    try {
      return Ok(_parseMonthHtml(html, year, month));
    } on _MalformedPageException {
      return const Err(CrosshareFetchMonthError.malformedPage);
    }
  }

  /// Downloads the raw .puz bytes for the puzzle with the given Crosshare [id].
  Future<Result<Uint8List, CrosshareDownloadError>> downloadById(
    String id,
  ) async {
    try {
      final response = await _dio.get<List<int>>(
        '$_puzApiBase/$id',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'User-Agent': _userAgent},
          connectTimeout: _connectTimeout,
          receiveTimeout: _puzReceiveTimeout,
          persistentConnection: false,
        ),
      );
      if (response.statusCode != 200 || response.data == null) {
        return const Err(CrosshareDownloadError.networkError);
      }
      return Ok(Uint8List.fromList(response.data!));
    } on DioException {
      return const Err(CrosshareDownloadError.networkError);
    } catch (_) {
      return const Err(CrosshareDownloadError.networkError);
    }
  }

  /// Maps a fetch-month error to the broader download-flow error. `notFound`
  /// is only emitted by [downloadToday] when today's day-of-month is absent
  /// from the current month page, never by [fetchMonth] itself.
  CrosshareDownloadError _fetchToDownloadError(CrosshareFetchMonthError e) {
    return switch (e) {
      CrosshareFetchMonthError.beforeArchiveStart =>
        CrosshareDownloadError.notFound,
      CrosshareFetchMonthError.networkError =>
        CrosshareDownloadError.networkError,
      CrosshareFetchMonthError.malformedPage =>
        CrosshareDownloadError.malformedPage,
    };
  }

  List<CrosshareEntry> _parseMonthHtml(String html, int year, int month) {
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

    final props = data['props'] as Map<String, dynamic>?;
    final pageProps = props?['pageProps'] as Map<String, dynamic>?;
    final puzzles = pageProps?['puzzles'] as List<dynamic>?;
    if (puzzles == null) {
      throw const _MalformedPageException(
        'Expected puzzles array at props.pageProps.puzzles',
      );
    }

    final entries = <CrosshareEntry>[];
    for (final raw in puzzles) {
      if (raw is! List || raw.length < 2) continue;
      final day = raw[0];
      final meta = raw[1];
      if (day is! int || meta is! Map) continue;
      final id = meta['id'];
      final title = meta['title'];
      if (id is! String || title is! String) continue;

      final author = meta['authorName'];
      final size = meta['size'];
      int width = 5;
      int height = 5;
      if (size is Map) {
        final c = size['cols'];
        final r = size['rows'];
        if (c is int) width = c;
        if (r is int) height = r;
      }

      entries.add(
        CrosshareEntry(
          id: id,
          date: DateTime(year, month, day),
          title: title,
          authorName: author is String ? author : '',
          width: width,
          height: height,
        ),
      );
    }
    return entries;
  }
}

/// Internal sentinel thrown when HTML parsing fails; converted to
/// [CrosshareFetchMonthError.malformedPage] by [CrosshareDownloader.fetchMonth].
class _MalformedPageException implements Exception {
  const _MalformedPageException(this.message);
  final String message;

  @override
  String toString() => '_MalformedPageException: $message';
}
