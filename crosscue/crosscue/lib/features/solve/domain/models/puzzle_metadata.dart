import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'puzzle_metadata.freezed.dart';

/// Lightweight metadata about a puzzle (no grid / clue data).
/// Stored in the DB puzzles table; displayed in list views.
@freezed
abstract class PuzzleMetadata with _$PuzzleMetadata {
  const factory PuzzleMetadata({
    required String id,
    required String sourceId,
    required String title,
    required String author,
    required String copyright,
    required PuzzleFormat format,
    required int width,
    required int height,
    required int totalClues,
    required DateTime importedAt,
    String? notes,
    String? checksum,
  }) = _PuzzleMetadata;
}
