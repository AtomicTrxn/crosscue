import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';

/// Pure focus-movement helpers for the solve screen.
///
/// All methods are stateless and return a new [FocusPosition] (or null) given
/// a [SolveState] snapshot. Extracted from `SolveNotifier` so the notifier
/// only owns state transitions, not navigation algorithms.
class SolveFocusNavigator {
  const SolveFocusNavigator._();

  /// Returns the next focus after typing a letter at ([row], [col]).
  ///
  /// When [skipFilledCells] is true, advancement wraps within the active word
  /// to find the next empty editable cell; otherwise it walks forward only.
  /// Falls back to the next incomplete clue once the active word is finished.
  static FocusPosition advanceFocus(
    SolveState s,
    int row,
    int col, {
    required bool skipFilledCells,
  }) {
    final clue = s.clueFor(row, col, s.focus.direction);
    if (clue == null) return s.focus;
    final cells = ClueProgressCalculator.cellsFor(clue);
    final idx = cells.indexWhere((p) => p.$1 == row && p.$2 == col);
    if (idx == -1) return s.focus;

    final searchCount =
        skipFilledCells ? cells.length - 1 : cells.length - idx - 1;
    for (var offset = 1; offset <= searchCount; offset++) {
      final nextIndex =
          skipFilledCells ? (idx + offset) % cells.length : idx + offset;
      if (nextIndex >= cells.length) break;
      final (nr, nc) = cells[nextIndex];
      if (s.isCellLocked(nr, nc)) continue;
      if (skipFilledCells && s.progress.cell(nr, nc).letter.isNotEmpty) {
        continue;
      }
      return FocusPosition(row: nr, col: nc, direction: s.focus.direction);
    }

    if (s.isWordComplete(clue)) {
      return nextIncompleteClueFocus(s, clue) ?? s.focus;
    }
    return s.focus;
  }

  /// Returns the focus to retreat to after a backspace at ([row], [col]).
  static FocusPosition retreatFocus(SolveState s, int row, int col) {
    final clue = s.clueFor(row, col, s.focus.direction);
    if (clue == null) return s.focus;
    final cells = ClueProgressCalculator.cellsFor(clue);
    final idx = cells.indexWhere((p) => p.$1 == row && p.$2 == col);
    if (idx <= 0) return s.focus;
    for (var i = idx - 1; i >= 0; i--) {
      final (pr, pc) = cells[i];
      if (!s.isCellLocked(pr, pc)) {
        return FocusPosition(row: pr, col: pc, direction: s.focus.direction);
      }
    }
    final (pr, pc) = cells[idx - 1];
    return FocusPosition(row: pr, col: pc, direction: s.focus.direction);
  }

  /// Picks the direction to use when tapping ([row], [col]).
  ///
  /// Prefers the current direction's clue if it's still editable and
  /// incomplete; otherwise tries the perpendicular direction.
  static Direction? preferredDirectionForTap(SolveState s, int row, int col) {
    final currentClue = s.clueFor(row, col, s.focus.direction);
    final otherDir = s.focus.direction.other;
    final otherClue = s.clueFor(row, col, otherDir);

    if (currentClue != null &&
        !s.isWordComplete(currentClue) &&
        !s.isCellLocked(row, col)) {
      return s.focus.direction;
    }
    if (otherClue != null && !s.isWordComplete(otherClue)) {
      return otherDir;
    }
    if (currentClue != null) return s.focus.direction;
    if (otherClue != null) return otherDir;
    return null;
  }

  /// Finds the next incomplete clue after [currentClue] (wraps around).
  ///
  /// Returns a focus on the first open cell, or the first non-locked cell
  /// if every cell is filled but the word still isn't complete.
  static FocusPosition? nextIncompleteClueFocus(
    SolveState s,
    Clue currentClue,
  ) {
    final clues = s.sortedClues;
    final currentIndex = clues.indexWhere(
      (clue) =>
          clue.number == currentClue.number &&
          clue.direction == currentClue.direction,
    );
    if (currentIndex == -1 || clues.isEmpty) return null;

    for (var offset = 1; offset < clues.length; offset++) {
      final clue = clues[(currentIndex + offset) % clues.length];
      if (s.isWordComplete(clue)) continue;
      final cells = ClueProgressCalculator.cellsFor(clue);
      for (final (r, c) in cells) {
        if (s.isOpenCell(r, c)) {
          return FocusPosition(row: r, col: c, direction: clue.direction);
        }
      }
      for (final (r, c) in cells) {
        if (!s.isCellLocked(r, c)) {
          return FocusPosition(row: r, col: c, direction: clue.direction);
        }
      }
    }
    return null;
  }

  /// Returns a focus inside [clue] that prefers the first open cell at or
  /// after ([row], [col]). Falls back to scanning from the start of the clue.
  static FocusPosition focusForClue(
    SolveState s,
    Clue clue,
    int row,
    int col,
  ) {
    final cells = ClueProgressCalculator.cellsFor(clue);
    final idx = cells.indexWhere((p) => p.$1 == row && p.$2 == col);
    final start = idx < 0 ? 0 : idx;

    for (var i = start; i < cells.length; i++) {
      final (r, c) = cells[i];
      if (s.isOpenCell(r, c)) {
        return FocusPosition(row: r, col: c, direction: clue.direction);
      }
    }
    for (var i = 0; i < start; i++) {
      final (r, c) = cells[i];
      if (s.isOpenCell(r, c)) {
        return FocusPosition(row: r, col: c, direction: clue.direction);
      }
    }
    return FocusPosition(row: row, col: col, direction: clue.direction);
  }

  /// Returns the focus to use when the user taps ([row], [col]) while [clue]
  /// is the active word: stays on the tapped cell unless it's locked.
  static FocusPosition focusForTappedCell(
    SolveState s,
    Clue clue,
    int row,
    int col,
  ) {
    if (!s.isCellLocked(row, col)) {
      return FocusPosition(row: row, col: col, direction: clue.direction);
    }
    return focusForClue(s, clue, row, col);
  }
}
