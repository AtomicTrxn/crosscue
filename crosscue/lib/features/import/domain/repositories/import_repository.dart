import 'dart:typed_data';

import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';

/// Abstract contract for the import data layer.
abstract class ImportRepository {
  /// Parses [bytes] (a `.puz` or `.ipuz` file) and persists the puzzle.
  /// Returns an [ImportJobResult] describing success or failure.
  ///
  /// [sourceId] is stored on the puzzle's metadata so queries can filter by
  /// origin. Defaults to `'local_import'` for user-supplied files.
  ///
  /// [sourcePuzzleId] is the source's stable ID for this puzzle (e.g. a
  /// Crosshare puzzle ID). When non-null, it is used for a fast pre-flight
  /// duplicate check ahead of the more expensive checksum-based one.
  ///
  /// [publishDate] overrides the puzzle's publish date when the source knows
  /// it (e.g. Crosshare daily-mini downloads always carry a date) but the
  /// parsed file format does not (e.g. `.puz`, which has no date field).
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
    DateTime? publishDate,
  });

  /// Returns metadata for every puzzle currently stored in the database.
  Future<List<PuzzleMetadata>> getAllMetadata();

  /// Watches metadata for every puzzle currently stored in the database.
  Stream<List<PuzzleMetadata>> watchAllMetadata();

  /// Returns the full [Puzzle] for [id], or `null` if not found.
  Future<Puzzle?> getPuzzle(String id);

  /// Emits `true` while [id] exists and `false` once it is deleted. Lets an
  /// open solve screen react when its puzzle is removed out from under it.
  Stream<bool> watchPuzzleExists(String id);

  /// Permanently deletes [id] and all dependent rows.
  Future<void> deletePuzzle(String id);
}
