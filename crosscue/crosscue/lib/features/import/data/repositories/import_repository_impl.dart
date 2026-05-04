import 'dart:typed_data';

import '../../../solve/domain/models/puzzle.dart';
import '../../../solve/domain/models/puzzle_metadata.dart';
import '../../domain/models/parse_error.dart';
import '../../domain/repositories/puzzle_parser.dart';
import '../daos/puzzle_dao.dart';
import '../parsers/ipuz_parser.dart';
import '../parsers/puz_parser.dart';

/// Orchestrates parsing + persistence for puzzle imports.
class ImportRepositoryImpl {
  ImportRepositoryImpl({required PuzzleDao dao})
      : _dao = dao,
        _parsers = const [PuzParser(), IpuzParser()];

  final PuzzleDao _dao;
  final List<PuzzleParser> _parsers;

  /// Import [bytes] of an unknown format.
  ///
  /// Returns [ImportJobResult] discriminating success / duplicate / failure.
  Future<ImportJobResult> importBytes(Uint8List bytes) async {
    // Find a capable parser
    PuzzleParser? parser;
    for (final p in _parsers) {
      if (p.canParse(bytes)) {
        parser = p;
        break;
      }
    }
    if (parser == null) {
      return const ImportJobResult.failure(ParseError.invalidFormat);
    }

    // Parse
    final result = parser.parse(bytes);
    if (result.isErr) return ImportJobResult.failure(result.error);

    final puzzle = result.value;

    // Duplicate detection
    final checksum = puzzle.metadata.checksum ?? '';
    if (checksum.isNotEmpty && await _dao.existsByChecksum(checksum)) {
      return const ImportJobResult.duplicate();
    }

    // Persist
    await _dao.insertPuzzle(puzzle);
    return ImportJobResult.success(puzzle);
  }

  Future<List<PuzzleMetadata>> getAllMetadata() => _dao.getAllMetadata();

  Future<Puzzle?> getPuzzle(String id) => _dao.getPuzzle(id);

  Future<void> deletePuzzle(String id) => _dao.deletePuzzle(id);
}

// ---------------------------------------------------------------------------
// Result type (prefixed "Job" to avoid name clash with UI state classes)
// ---------------------------------------------------------------------------

sealed class ImportJobResult {
  const ImportJobResult();

  const factory ImportJobResult.success(Puzzle puzzle) = JobSuccess;
  const factory ImportJobResult.duplicate() = JobDuplicate;
  const factory ImportJobResult.failure(ParseError error) = JobFailure;
}

final class JobSuccess extends ImportJobResult {
  const JobSuccess(this.puzzle);
  final Puzzle puzzle;
}

final class JobDuplicate extends ImportJobResult {
  const JobDuplicate();
}

final class JobFailure extends ImportJobResult {
  const JobFailure(this.error);
  final ParseError error;
}
