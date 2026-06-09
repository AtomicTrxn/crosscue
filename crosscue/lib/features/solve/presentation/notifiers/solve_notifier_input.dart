part of 'solve_notifier.dart';

/// Keyboard-driven cell entry: single-letter input, multi-character rebus
/// entry, and backspace. Each edit writes progress, schedules an autosave, and
/// asks the orchestrator to re-check completion.
///
/// Applied to [SolveNotifier], which implements the shared members re-declared
/// abstract here ([_s], [_scheduleSave], [_checkCompletion],
/// [_skipFilledCellsEnabled]).
mixin _SolveInput on _$SolveNotifier {
  // Compiled once; reused on every keystroke / rebus entry.
  static final _singleLetterRe = RegExp(r'^[A-Z]$');
  // Rebus entries accept A-Z plus "/" for bidirectional rebuses
  // (e.g. "PB/AU" — see SolutionCellAccepts).
  static final _nonRebusRe = RegExp(r'[^A-Z/]');

  // --- Shared orchestration surface (implemented by SolveNotifier) ---
  SolveState? get _s;
  void _scheduleSave();
  void _checkCompletion();
  bool _skipFilledCellsEnabled();

  bool inputLetter(String letter) {
    final s = _s;
    if (s == null || s.isPaused || s.status.isTerminal) return false;

    final upper = letter.toUpperCase();
    if (!_singleLetterRe.hasMatch(upper)) return false;

    final r = s.focus.row;
    final c = s.focus.col;

    if (s.isCellLocked(r, c)) return false;
    final clue = s.clueFor(r, c, s.focus.direction);
    final wasWordComplete = clue != null && s.isWordComplete(clue);

    // Any typed letter resets the cell to plain filled — clears checkedIncorrect,
    // checkedCorrect, and pencil marks alike.
    final newProgress = s.progress.withCell(
      r,
      c,
      s.progress.cell(r, c).copyWith(letter: upper, state: CellState.filled),
    );
    final updatedProgressState = s.copyWith(progress: newProgress);
    final nextFocus = SolveFocusNavigator.advanceFocus(
      updatedProgressState,
      r,
      c,
      skipFilledCells: _skipFilledCellsEnabled(),
    );
    final updated = updatedProgressState.copyWith(focus: nextFocus);
    state = AsyncData(updated);
    _scheduleSave();
    _checkCompletion();
    return clue != null && !wasWordComplete && updated.isWordComplete(clue);
  }

  /// Writes a rebus answer to the currently focused cell.
  ///
  /// Normalization:
  ///   - Upper-cased; non-`[A-Z/]` stripped (the "/" is permitted for
  ///     bidirectional rebuses such as `"PB/AU"`).
  ///   - Empty input → no-op (returns `false`).
  ///   - Single-character input → delegates to [inputLetter] so the dialog
  ///     can round-trip back to normal entry.
  ///   - Anything longer than [SolveNotifier.rebusMaxLength] is truncated.
  bool inputRebus(String value) {
    final s = _s;
    if (s == null || s.isPaused || s.status.isTerminal) return false;

    var upper = value.toUpperCase().replaceAll(_nonRebusRe, '');
    if (upper.isEmpty) return false;
    if (upper.length == 1) {
      // Round-trip safety: a 1-char rebus submission is identical to
      // typing that letter on the keyboard.
      return inputLetter(upper);
    }
    if (upper.length > SolveNotifier.rebusMaxLength) {
      upper = upper.substring(0, SolveNotifier.rebusMaxLength);
    }

    final r = s.focus.row;
    final c = s.focus.col;
    if (s.isCellLocked(r, c)) return false;

    final clue = s.clueFor(r, c, s.focus.direction);
    final wasWordComplete = clue != null && s.isWordComplete(clue);
    final newProgress = s.progress.withCell(
      r,
      c,
      s.progress.cell(r, c).copyWith(letter: upper, state: CellState.filled),
    );
    final updatedProgressState = s.copyWith(progress: newProgress);
    final nextFocus = SolveFocusNavigator.advanceFocus(
      updatedProgressState,
      r,
      c,
      skipFilledCells: _skipFilledCellsEnabled(),
    );
    final updated = updatedProgressState.copyWith(focus: nextFocus);
    state = AsyncData(updated);
    _scheduleSave();
    _checkCompletion();
    return clue != null && !wasWordComplete && updated.isWordComplete(clue);
  }

  /// Handles the backspace keypress.
  void backspace() {
    final s = _s;
    if (s == null || s.isPaused || s.status.isTerminal) return;

    final r = s.focus.row;
    final c = s.focus.col;
    final current = s.progress.cell(r, c);

    if (s.isCellLocked(r, c)) return;

    // Erase the current cell if it has content, or retreat to the previous cell
    if (current.letter.isNotEmpty) {
      final newProgress = s.progress.withCell(r, c, CellProgress.blank);
      state = AsyncData(s.copyWith(progress: newProgress));
    } else {
      final prevFocus = SolveFocusNavigator.retreatFocus(s, r, c);
      if (prevFocus == s.focus) return;
      if (s.isCellLocked(prevFocus.row, prevFocus.col)) {
        state = AsyncData(s.copyWith(focus: prevFocus));
      } else {
        final newProgress = s.progress
            .withCell(prevFocus.row, prevFocus.col, CellProgress.blank);
        state = AsyncData(s.copyWith(progress: newProgress, focus: prevFocus));
      }
    }
    _scheduleSave();
  }
}
