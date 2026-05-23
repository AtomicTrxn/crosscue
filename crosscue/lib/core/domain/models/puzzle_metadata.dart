import 'package:crosscue/core/domain/models/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    required DateTime importedAt,
    String? sourcePuzzleId,
    DateTime? publishDate,
    String? notes,
    String? checksum,
    String? difficulty,

    /// Number of non-black (fillable) cells in the grid. Denormalized from
    /// the canonical JSON at import time so list-view consumers (Archive
    /// completion-fraction pie, Stats, future projections) can compute
    /// progress without paying the full JSON-decode cost. See issue #122.
    ///
    /// Defaults to 0 for rows migrated from schema versions ≤ 5 that
    /// failed to parse during the v5 → v6 backfill — callers that treat
    /// the value as an authoritative cell count must guard against the
    /// 0 sentinel (in practice, freshly inserted rows are always > 0).
    @Default(0) int fillableCellCount,
  }) = _PuzzleMetadata;
}
