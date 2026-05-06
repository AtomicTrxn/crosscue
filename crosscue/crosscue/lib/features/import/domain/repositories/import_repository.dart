import 'dart:typed_data';

import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/solve/domain/models/puzzle.dart';
import 'package:crosscue/features/import/data/repositories/import_repository_impl.dart';

/// Abstract contract for the import data layer.
abstract class ImportRepository {
  /// Parses [bytes] (a `.puz` or `.ipuz` file) and persists the puzzle.
  /// Returns an [ImportJobResult] describing success or failure.
  Future<ImportJobResult> importBytes(Uint8List bytes);

  /// Returns metadata for every puzzle currently stored in the database.
  Future<List<PuzzleMetadata>> getAllMetadata();

  /// Returns the full [Puzzle] for [id], or `null` if not found.
  Future<Puzzle?> getPuzzle(String id);

  /// Permanently deletes [id] and all dependent rows.
  Future<void> deletePuzzle(String id);
}
