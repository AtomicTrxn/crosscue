import 'dart:typed_data';

import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/import/data/daos/puzzle_dao.dart';
import 'package:crosscue/features/import/data/parsers/ipuz_parser.dart';
import 'package:crosscue/features/import/data/parsers/puz_parser.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_parser.dart';

/// Orchestrates parsing + persistence for puzzle imports.
class ImportRepositoryImpl implements ImportRepository {
  ImportRepositoryImpl({required PuzzleDao dao})
      : _dao = dao,
        _parsers = const [PuzParser(), IpuzParser()];

  final PuzzleDao _dao;
  final List<PuzzleParser> _parsers;

  /// Import [bytes] of an unknown format.
  ///
  /// Returns [ImportJobResult] discriminating success / duplicate / failure.
  @override
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
  }) async {
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
    final result = parser.parse(bytes, sourceId: sourceId);
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

  @override
  Future<List<PuzzleMetadata>> getAllMetadata() => _dao.getAllMetadata();

  @override
  Future<Puzzle?> getPuzzle(String id) => _dao.getPuzzle(id);

  @override
  Future<void> deletePuzzle(String id) => _dao.deletePuzzle(id);
}
