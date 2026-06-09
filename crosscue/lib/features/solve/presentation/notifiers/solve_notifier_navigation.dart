part of 'solve_notifier.dart';

/// Focus + direction movement for the solve grid: cell taps, the across↔down
/// toggle, jumping to a clue, and programmatic focus moves. Pure focus
/// mutations — no progress writes, no autosave, no completion checks.
///
/// Applied to [SolveNotifier]; depends only on the shared [_s] snapshot getter,
/// which that class implements.
mixin _SolveNavigation on _$SolveNotifier {
  /// Latest data state, or null while loading/errored. Implemented by
  /// [SolveNotifier].
  SolveState? get _s;

  /// Toggles the solve direction (across ↔ down) at the current focus cell.
  void toggleDirection() {
    final s = _s;
    if (s == null) return;
    final newDir = s.focus.direction.other;
    final clue = s.clueFor(s.focus.row, s.focus.col, newDir);
    if (clue != null) {
      final focus = SolveFocusNavigator.focusForTappedCell(
        s,
        clue,
        s.focus.row,
        s.focus.col,
      );
      state = AsyncData(s.copyWith(focus: focus));
    }
  }

  FocusPosition? tapCell(int row, int col) {
    final s = _s;
    if (s == null) return null;
    if (s.puzzle.grid.cell(row, col).isBlack) return null;

    if (s.focus.row == row && s.focus.col == col) {
      final newDir = s.focus.direction.other;
      final clue = s.clueFor(row, col, newDir);
      if (clue != null) {
        final focus = SolveFocusNavigator.focusForTappedCell(s, clue, row, col);
        state = AsyncData(s.copyWith(focus: focus));
        return focus;
      }
      return s.focus;
    } else {
      final dir = SolveFocusNavigator.preferredDirectionForTap(s, row, col);
      if (dir == null) return null;
      final clue = s.clueFor(row, col, dir);
      if (clue == null) return null;
      final focus = SolveFocusNavigator.focusForTappedCell(s, clue, row, col);
      state = AsyncData(s.copyWith(focus: focus));
      return focus;
    }
  }

  /// Moves focus to a clue, preferring the first empty cell in that answer.
  FocusPosition? focusClue(Clue clue) {
    final s = _s;
    if (s == null) return null;
    final focus = SolveFocusNavigator.focusForClue(s, clue);
    state = AsyncData(s.copyWith(focus: focus));
    return focus;
  }

  /// Moves focus to a non-black cell and updates direction when supported.
  FocusPosition? moveFocusTo(int row, int col, Direction direction) {
    final s = _s;
    if (s == null) return null;
    if (!s.puzzle.grid.inBounds(row, col) ||
        s.puzzle.grid.cell(row, col).isBlack) {
      return null;
    }
    final effectiveDirection = s.hasWord(row, col, direction)
        ? direction
        : SolveFocusNavigator.preferredDirectionForTap(s, row, col);
    if (effectiveDirection == null) return null;
    final clue = s.clueFor(row, col, effectiveDirection);
    if (clue == null) return null;
    final focus = SolveFocusNavigator.focusForTappedCell(s, clue, row, col);
    state = AsyncData(s.copyWith(focus: focus));
    return focus;
  }
}
