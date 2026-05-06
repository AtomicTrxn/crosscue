import 'dart:typed_data';

import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/solve/domain/models/puzzle.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';

/// Interface implemented by each puzzle-format parser.
abstract interface class PuzzleParser {
  /// Returns true if this parser can handle the given raw bytes.
  bool canParse(Uint8List bytes);

  /// Parse [bytes] into a [Puzzle], or return a [ParseError].
  Result<Puzzle, ParseError> parse(Uint8List bytes);
}
