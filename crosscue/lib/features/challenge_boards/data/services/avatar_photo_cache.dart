import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// In-memory cache for `https:` avatar photos (#268).
///
/// Avatar URLs served by the Worker are immutable/content-hashed, so entries
/// are cached aggressively by URL for the app lifetime (bounded by
/// [maxEntries], evicting least-recently-used). Fetch failures resolve to
/// `null` — callers fall back to initials/silhouette exactly like a missing
/// photo — and are not cached, so a transient failure recovers on the next
/// rebuild.
class AvatarPhotoCache {
  AvatarPhotoCache({required Dio dio, this.maxEntries = 64}) : _dio = dio;

  final Dio _dio;

  /// Upper bound on cached photos (~375 KB worst case each, see the Worker's
  /// upload cap in `backend/challenge_boards/src/validation.ts`).
  final int maxEntries;

  /// Insertion-ordered (LRU: hits re-insert at the end, eviction pops first).
  final _bytes = <String, Uint8List>{};
  final _inFlight = <String, Future<Uint8List?>>{};

  /// Synchronously returns cached bytes for [url], or `null` on a miss.
  /// Lets the UI render a cached photo without a placeholder frame.
  Uint8List? cached(String url) {
    final hit = _bytes.remove(url);
    if (hit == null) return null;
    _bytes[url] = hit; // Re-insert as most recently used.
    return hit;
  }

  /// Returns the photo bytes for [url], fetching once on a cache miss.
  /// Concurrent callers share one in-flight request. Resolves to `null` for
  /// non-https URLs and on any fetch failure — never throws.
  Future<Uint8List?> load(String url) {
    final hit = cached(url);
    if (hit != null) return Future<Uint8List?>.value(hit);
    if (!url.startsWith('https://')) return Future<Uint8List?>.value(null);
    return _inFlight[url] ??= _fetch(url);
  }

  Future<Uint8List?> _fetch(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      final bytes = data is Uint8List ? data : Uint8List.fromList(data);
      _bytes[url] = bytes;
      if (_bytes.length > maxEntries) {
        _bytes.remove(_bytes.keys.first);
      }
      return bytes;
    } on Object {
      // Missing photo fallback (initials/silhouette) is the contract; a
      // failed avatar fetch must never surface as an error.
      return null;
    } finally {
      // Map.remove returns the stored future; discard it — it's this very
      // future, already being awaited by every caller.
      unawaited(_inFlight.remove(url));
    }
  }
}
