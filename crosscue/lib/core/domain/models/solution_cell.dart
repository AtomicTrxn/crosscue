import 'package:freezed_annotation/freezed_annotation.dart';

part 'solution_cell.freezed.dart';

/// A single cell in the solution grid.
///
/// [isBlack]  – true for black (block) cells.
/// [solution] – the correct letter(s); empty string for black cells.
///              Multi-character for rebus squares (e.g. "EST").
///              May contain "/" for bidirectional rebuses where the
///              Across and Down answers differ in the same square
///              (e.g. "PB/AU" — PB across, AU down).
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

/// Acceptance rules for solver-entered values.
///
/// Mirrors the NYT Games conventions documented in
/// `docs/architecture/rebus-entry.md` (§4.6):
///
///   - Exact case-insensitive match always wins.
///   - For a rebus cell (`solution.length > 1`), the **first letter alone**
///     also counts. A solver who never finds the Rebus key can still
///     complete the puzzle by typing the most natural single-letter guess.
///   - For a bidirectional rebus ("/" delimiter, e.g. "PB/AU"), the
///     accepted forms are: the full canonical string, the reversed
///     canonical (e.g. "AU/PB"), either half alone ("PB" or "AU"), or
///     the first letter of either half ("P" or "A").
extension SolutionCellAccepts on SolutionCell {
  /// Returns true if [entered] should count as a correct answer for this
  /// cell. Empty / black cells always return false.
  bool accepts(String entered) {
    if (isBlack) return false;
    if (entered.isEmpty) return false;
    final e = entered.toUpperCase();
    final s = solution.toUpperCase();
    if (s.isEmpty) return false;
    if (e == s) return true;
    // First-letter shortcut for single (non-bidirectional) rebus answers.
    if (!s.contains('/') && s.length > 1 && e.length == 1 && e == s[0]) {
      return true;
    }
    // Bidirectional rebus: accept either half, reversed canonical,
    // or first letter of either half.
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 2) {
        final reversed = '${parts[1]}/${parts[0]}';
        if (e == reversed) return true;
      }
      for (final part in parts) {
        if (part.isEmpty) continue;
        if (e == part) return true;
        if (part.length > 1 && e.length == 1 && e == part[0]) return true;
      }
    }
    return false;
  }
}
