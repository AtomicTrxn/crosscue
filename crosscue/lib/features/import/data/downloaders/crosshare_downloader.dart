import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:crosscue/core/utils/result.dart';

/// Errors that can occur when downloading a Crosshare puzzle.
enum CrosshareDownloadError {
  /// No puzzle entry matching today's date was found on the dailyminis page.
  notFound,

  /// A network request failed (timeout, HTTP error, no connection).
  networkError,
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
/// No fallback. If either step fails, returns [CrosshareDownloadError].
class CrosshareDownloader {
  CrosshareDownloader({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _dailyMinisBase = 'https://crosshare.org/dailyminis';
  static const _puzApiBase = 'https://crosshare.org/api/puz';

  Future<Result<Uint8List, CrosshareDownloadError>> downloadToday() async {
    try {
      final id = await _findTodayPuzzleId();
      if (id == null) return const Err(CrosshareDownloadError.notFound);

      final response = await _dio.get<List<int>>(
        '$_puzApiBase/$id',
        options: Options(responseType: ResponseType.bytes),
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

  /// Fetches the month page and extracts today's puzzle ID from the embedded
  /// Next.js data blob.
  Future<String?> _findTodayPuzzleId() async {
    try {
      final today = DateTime.now();
      final url = '$_dailyMinisBase/${today.year}/${today.month}';

      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode != 200 || response.data == null) return null;

      final html = response.data!;

      // Locate the __NEXT_DATA__ script block (avoids greedy regex on large HTML).
      const marker = '<script id="__NEXT_DATA__" type="application/json">';
      final start = html.indexOf(marker);
      if (start == -1) return null;
      final jsonStart = start + marker.length;
      final jsonEnd = html.indexOf('</script>', jsonStart);
      if (jsonEnd == -1) return null;

      final data = jsonDecode(html.substring(jsonStart, jsonEnd));

      // Navigate: props → pageProps → puzzles → [[day, {id, …}, …], …]
      final puzzles = data['props']?['pageProps']?['puzzles'] as List<dynamic>?;
      if (puzzles == null) return null;

      for (final entry in puzzles) {
        if (entry is! List || entry.length < 2) continue;
        if (entry[0] == today.day) {
          final puzzleData = entry[1];
          if (puzzleData is Map) {
            return puzzleData['id'] as String?;
          }
        }
      }
      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
