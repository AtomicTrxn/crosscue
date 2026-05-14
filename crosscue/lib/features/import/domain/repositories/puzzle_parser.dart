import 'dart:typed_data';

import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';

/// Interface implemented by each puzzle-format parser.
abstract interface class PuzzleParser {
  /// Returns true if this parser can handle the given raw bytes.
  bool canParse(Uint8List bytes);

  /// Parse [bytes] into a [Puzzle], or return a [ParseError].
  ///
  /// [sourceId] identifies which source produced the bytes and is stored on
  /// the resulting [PuzzleMetadata]. Defaults to `'local_import'`.
  ///
  /// [sourcePuzzleId] is the source's own ID for this puzzle (e.g. Crosshare's
  /// stable puzzle ID). Stored alongside [sourceId] so callers can later check
  /// whether a given source entry has already been imported.
  Result<Puzzle, ParseError> parse(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
  });
}
