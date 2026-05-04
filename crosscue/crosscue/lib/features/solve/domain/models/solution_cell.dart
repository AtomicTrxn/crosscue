import 'package:freezed_annotation/freezed_annotation.dart';

part 'solution_cell.freezed.dart';

/// A single cell in the solution grid.
///
/// [isBlack]  – true for black (block) cells.
/// [solution] – the correct letter(s); empty string for black cells.
///              Multi-character for rebus squares (e.g. "EST").
/// [number]   – the clue number printed in the cell corner, or null.
/// [circled]  – whether the cell has a circle annotation (GEXT flag 0x80).
@freezed
abstract class SolutionCell with _$SolutionCell {
  const factory SolutionCell({
    @Default(false) bool isBlack,
    @Default('') String solution,
    int? number,
    @Default(false) bool circled,
  }) = _SolutionCell;

  /// Convenience: a black (block) cell.
  static const SolutionCell black = SolutionCell(isBlack: true);
}
