import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'clue.freezed.dart';

/// A single clue entry.
@freezed
abstract class Clue with _$Clue {
  const factory Clue({
    required int number,
    required Direction direction,
    required String text,
    /// Starting row/col of the answer in the grid.
    required int startRow,
    required int startCol,
    /// Number of letters in the answer.
    required int length,
  }) = _Clue;
}
