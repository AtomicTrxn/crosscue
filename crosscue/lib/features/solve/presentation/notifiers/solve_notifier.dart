import 'dart:async';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/models/solve_errors.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:crosscue/features/solve/domain/services/grid_progress_mutator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/providers/solve_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'solve_notifier.g.dart';

@riverpod
class SolveNotifier extends _$SolveNotifier {
  // Compiled once; reused on every keystroke / rebus entry.
  static final _singleLetterRe = RegExp(r'^[A-Z]$');
  static final _nonLetterRe = RegExp(r'[^A-Z]');

  StreamSubscription<int>? _timerSub;
  Timer? _saveDebounce;

  /// Safely read the current SolveState from AsyncValue.
  SolveState? get _s => switch (state) {
        AsyncData(:final value) => value,
        _ => null,
      };

  @override
  Future<SolveState> build(String puzzleId) async {
    ref.onDispose(() {
      _timerSub?.cancel();
      _saveDebounce?.cancel();
    });

    final importRepo = ref.read(importRepositoryProvider);
    final solveRepo = ref.read(solveRepositoryProvider);

    final puzzle = await importRepo.getPuzzle(Uri.decodeComponent(puzzleId));
    if (puzzle == null) throw PuzzleNotFoundError(puzzleId);

    final session = await solveRepo.createOrResumeSession(puzzle);
    final stats = await ref.read(statsRepositoryProvider).getStats();

    _startTimer();

    return SolveState(
      puzzle: puzzle,
      progress: session.progress,
      focus: session.focus,
      status: session.status,
      elapsedSeconds: session.elapsedMs ~/ 1000,
      isPaused: session.isPaused,
      sessionId: session.sessionId,
      checkCount: session.checkCount,
      revealCount: session.revealCount,
      usedCheck: session.usedCheck,
      usedReveal: session.usedReveal,
      cleanSolveEligible: session.cleanSolveEligible,
      previousPersonalBestMs: _personalBestForSize(
        width: puzzle.width,
        height: puzzle.height,
        personalBestMiniMs: stats.personalBestMiniMs,
        personalBest15x15Ms: stats.personalBest15x15Ms,
        personalBest21x21Ms: stats.personalBest21x21Ms,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timerSub?.cancel();
    _timerSub =
        Stream<int>.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
      final s = _s;
      if (s == null || s.isPaused) return;
      if (_isTerminal(s.status)) return;
      state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1));
    });
  }

  void pause() {
    final s = _s;
    if (s == null || s.isPaused) return;
    state = AsyncData(s.copyWith(isPaused: true));
    _saveNow();
  }

  void resume() {
    final s = _s;
    if (s == null || !s.isPaused) return;
    state = AsyncData(s.copyWith(isPaused: false));
  }

  // ---------------------------------------------------------------------------
  // Cell tap / direction toggle
  // ---------------------------------------------------------------------------

  /// Toggles the solve direction (across ↔ down) at the current focus cell.
  void toggleDirection() {
    final s = _s;
    if (s == null) return;
    final newDir = _otherDirection(s.focus.direction);
    final clue = _clueFor(s, s.focus.row, s.focus.col, newDir);
    if (clue != null) {
      final focus = _focusForTappedCell(s, clue, s.focus.row, s.focus.col);
      state = AsyncData(s.copyWith(focus: focus));
    }
  }

  FocusPosition? tapCell(int row, int col) {
    final s = _s;
    if (s == null) return null;
    if (s.puzzle.grid.cell(row, col).isBlack) return null;

    if (s.focus.row == row && s.focus.col == col) {
      final newDir = _otherDirection(s.focus.direction);
      final clue = _clueFor(s, row, col, newDir);
      if (clue != null) {
        final focus = _focusForTappedCell(s, clue, row, col);
        state = AsyncData(s.copyWith(focus: focus));
        return focus;
      }
      return s.focus;
    } else {
      final dir = _preferredDirectionForTap(s, row, col);
      if (dir == null) return null;
      final clue = _clueFor(s, row, col, dir);
      if (clue == null) return null;
      final focus = _focusForTappedCell(s, clue, row, col);
      state = AsyncData(s.copyWith(focus: focus));
      return focus;
    }
  }

  /// Moves focus to a clue, preferring the first empty cell in that answer.
  FocusPosition? focusClue(Clue clue) {
    final s = _s;
    if (s == null) return null;

    var targetRow = clue.startRow;
    var targetCol = clue.startCol;
    for (final (row, col) in ClueProgressCalculator.cellsFor(clue)) {
      if (s.progress.cell(row, col).letter.isEmpty) {
        targetRow = row;
        targetCol = col;
        break;
      }
    }

    final focus = FocusPosition(
      row: targetRow,
      col: targetCol,
      direction: clue.direction,
    );
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
    final effectiveDirection = _hasWord(s, row, col, direction)
        ? direction
        : _preferredDirectionForTap(s, row, col);
    if (effectiveDirection == null) return null;
    final clue = _clueFor(s, row, col, effectiveDirection);
    if (clue == null) return null;
    final focus = _focusForTappedCell(s, clue, row, col);
    state = AsyncData(s.copyWith(focus: focus));
    return focus;
  }

  // ---------------------------------------------------------------------------
  // Keyboard input
  // ---------------------------------------------------------------------------

  bool inputLetter(String letter) {
    final s = _s;
    if (s == null || s.isPaused || _isTerminal(s.status)) return false;

    final upper = letter.toUpperCase();
    if (!_singleLetterRe.hasMatch(upper)) return false;

    final r = s.focus.row;
    final c = s.focus.col;

    if (_isCellLocked(s, r, c)) return false;
    final clue = _clueFor(s, r, c, s.focus.direction);
    final wasWordComplete = clue != null && _isWordComplete(s, clue);

    // Any typed letter resets the cell to plain filled — clears checkedIncorrect,
    // checkedCorrect, and pencil marks alike.
    final newProgress = s.progress.withCell(
      r,
      c,
      s.progress.cell(r, c).copyWith(letter: upper, state: CellState.filled),
    );
    final updatedProgressState = s.copyWith(progress: newProgress);
    final nextFocus = _advanceFocus(
      updatedProgressState,
      r,
      c,
      skipFilledCells: _skipFilledCellsEnabled(),
    );
    final updated = updatedProgressState.copyWith(focus: nextFocus);
    state = AsyncData(updated);
    _scheduleSave();
    _checkCompletion();
    return clue != null && !wasWordComplete && _isWordComplete(updated, clue);
  }

  bool inputRebus(String value) {
    final s = _s;
    if (s == null || s.isPaused || _isTerminal(s.status)) return false;

    final upper = value.toUpperCase().replaceAll(_nonLetterRe, '');
    if (upper.length < 2) return false;

    final r = s.focus.row;
    final c = s.focus.col;
    if (_isCellLocked(s, r, c)) return false;

    final clue = _clueFor(s, r, c, s.focus.direction);
    final wasWordComplete = clue != null && _isWordComplete(s, clue);
    final newProgress = s.progress.withCell(
      r,
      c,
      s.progress.cell(r, c).copyWith(letter: upper, state: CellState.filled),
    );
    final updatedProgressState = s.copyWith(progress: newProgress);
    final nextFocus = _advanceFocus(
      updatedProgressState,
      r,
      c,
      skipFilledCells: _skipFilledCellsEnabled(),
    );
    final updated = updatedProgressState.copyWith(focus: nextFocus);
    state = AsyncData(updated);
    _scheduleSave();
    _checkCompletion();
    return clue != null && !wasWordComplete && _isWordComplete(updated, clue);
  }

  /// Checks the focused cell. Empty cells are skipped silently.
  CheckResult checkCell() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return CheckResult.noop;

    final mutation = GridProgressMutator.checkCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: [(s.focus.row, s.focus.col)],
    );
    return _applyCheckMutation(s, mutation);
  }

  CheckResult _applyCheckMutation(SolveState s, CheckMutation mutation) {
    if (mutation.result == CheckResult.noop) return CheckResult.noop;

    state = AsyncData(
      s.copyWith(
        progress: mutation.progress,
        checkCount: s.checkCount + 1,
        usedCheck: true,
      ),
    );
    _scheduleSave();
    _checkCompletion();
    return mutation.result;
  }

  /// Checks all filled cells in the active word.
  CheckResult checkWord() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return CheckResult.noop;

    final clue = _clueFor(s, s.focus.row, s.focus.col, s.focus.direction);
    if (clue == null) return CheckResult.noop;

    final mutation = GridProgressMutator.checkCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: GridProgressMutator.clueCells(clue),
    );
    return _applyCheckMutation(s, mutation);
  }

  /// Checks all filled cells in the puzzle.
  CheckResult checkGrid() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return CheckResult.noop;

    final mutation = GridProgressMutator.checkCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: GridProgressMutator.puzzleCells(s.puzzle),
    );
    return _applyCheckMutation(s, mutation);
  }

  // ---------------------------------------------------------------------------
  // Reveal actions
  // --------------------------------------------------------------------

  /// Fills the focused cell with the solution and marks it revealed.
  void revealCell() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return;

    final progress = GridProgressMutator.revealCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: [(s.focus.row, s.focus.col)],
    );

    _applyRevealProgress(s, progress);
  }

  /// Fills all cells in the active word with their solutions.
  void revealWord() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return;

    final clue = _clueFor(s, s.focus.row, s.focus.col, s.focus.direction);
    if (clue == null) return;

    final progress = GridProgressMutator.revealCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: GridProgressMutator.clueCells(clue),
    );

    _applyRevealProgress(s, progress);
  }

  void _applyRevealProgress(SolveState s, Grid<CellProgress> progress) {
    final updated = s.copyWith(
      progress: progress,
      revealCount: s.revealCount + 1,
      usedReveal: true,
      cleanSolveEligible: false,
    );
    state = AsyncData(updated);
    _scheduleSave();
    _checkCompletion();
  }

  /// Fills the entire puzzle — sets status to [PuzzleStatus.revealed]
  /// (does NOT count as a solve).
  void revealPuzzle() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return;

    final progress = GridProgressMutator.revealCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: GridProgressMutator.puzzleCells(s.puzzle),
    );

    _timerSub?.cancel();
    _saveDebounce?.cancel();

    final completed = s.copyWith(
      progress: progress,
      status: PuzzleStatus.revealed,
      revealCount: s.revealCount + 1,
      usedReveal: true,
      cleanSolveEligible: false,
    );
    state = AsyncData(completed);

    if (s.sessionId != null) {
      _persistCompletion(completed);
    }
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Clears all progress, counters, and the timer back to a fresh state.
  /// Reuses the existing session row (overwrites it) rather than creating a new one.
  void resetPuzzle() {
    final s = _s;
    if (s == null) return;

    FocusPosition focus = const FocusPosition(
      row: 0,
      col: 0,
      direction: Direction.across,
    );
    outer:
    for (var r = 0; r < s.puzzle.height; r++) {
      for (var c = 0; c < s.puzzle.width; c++) {
        if (!s.puzzle.grid.cell(r, c).isBlack) {
          focus = FocusPosition(row: r, col: c, direction: Direction.across);
          break outer;
        }
      }
    }

    final blank = Grid<CellProgress>.generate(
      s.puzzle.width,
      s.puzzle.height,
      (_, __) => CellProgress.blank,
    );

    // Restart timer
    _timerSub?.cancel();
    _startTimer();

    state = AsyncData(
      s.copyWith(
        progress: blank,
        focus: focus,
        status: PuzzleStatus.inProgress,
        elapsedSeconds: 0,
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      ),
    );

    _saveNow(); // Persist the reset immediately
  }

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------

  /// Handles the backspace keypress.
  void backspace() {
    final s = _s;
    if (s == null || s.isPaused || _isTerminal(s.status)) return;

    final r = s.focus.row;
    final c = s.focus.col;
    final current = s.progress.cell(r, c);

    if (_isCellLocked(s, r, c)) return;

    // Erase the current cell if it has content, or retreat to the previous cell
    if (current.letter.isNotEmpty) {
      final newProgress = s.progress.withCell(r, c, CellProgress.blank);
      state = AsyncData(s.copyWith(progress: newProgress));
    } else {
      final prevFocus = _retreatFocus(s, r, c);
      if (prevFocus == s.focus) return;
      if (_isCellLocked(s, prevFocus.row, prevFocus.col)) {
        state = AsyncData(s.copyWith(focus: prevFocus));
      } else {
        final newProgress = s.progress
            .withCell(prevFocus.row, prevFocus.col, CellProgress.blank);
        state = AsyncData(s.copyWith(progress: newProgress, focus: prevFocus));
      }
    }
    _scheduleSave();
  }

  // ---------------------------------------------------------------------------
  // Autosave
  // ---------------------------------------------------------------------------

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  Future<void> _saveNow() async {
    final s = _s;
    if (s == null || s.sessionId == null) return;
    final repo = ref.read(solveRepositoryProvider);
    await repo.saveProgress(
      sessionId: s.sessionId!,
      puzzleWidth: s.puzzle.width,
      puzzleHeight: s.puzzle.height,
      progress: s.progress,
      focus: s.focus,
      elapsedMs: s.elapsedSeconds * 1000,
      status: s.status,
      isPaused: s.isPaused,
      checkCount: s.checkCount,
      revealCount: s.revealCount,
      usedCheck: s.usedCheck,
      usedReveal: s.usedReveal,
      cleanSolveEligible: s.cleanSolveEligible,
    );
  }

  Future<void> flushPendingSave() async {
    _saveDebounce?.cancel();
    await _saveNow();
  }

  // ---------------------------------------------------------------------------
  // Focus movement
  // ---------------------------------------------------------------------------

  FocusPosition _advanceFocus(
    SolveState s,
    int row,
    int col, {
    required bool skipFilledCells,
  }) {
    final clue = _clueFor(s, row, col, s.focus.direction);
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
      if (_isCellLocked(s, nr, nc)) continue;
      if (skipFilledCells && s.progress.cell(nr, nc).letter.isNotEmpty) {
        continue;
      }
      return FocusPosition(row: nr, col: nc, direction: s.focus.direction);
    }

    if (_isWordComplete(s, clue)) {
      return _nextIncompleteClueFocus(s, clue) ?? s.focus;
    }
    return s.focus;
  }

  FocusPosition? _nextIncompleteClueFocus(SolveState s, Clue currentClue) {
    final clues = s.sortedClues;
    final currentIndex = clues.indexWhere(
      (clue) =>
          clue.number == currentClue.number &&
          clue.direction == currentClue.direction,
    );
    if (currentIndex == -1 || clues.isEmpty) return null;

    for (var offset = 1; offset < clues.length; offset++) {
      final clue = clues[(currentIndex + offset) % clues.length];
      if (_isWordComplete(s, clue)) continue;
      final cells = ClueProgressCalculator.cellsFor(clue);
      for (final (r, c) in cells) {
        if (_isOpenCell(s, r, c)) {
          return FocusPosition(row: r, col: c, direction: clue.direction);
        }
      }
      for (final (r, c) in cells) {
        if (!_isCellLocked(s, r, c)) {
          return FocusPosition(row: r, col: c, direction: clue.direction);
        }
      }
    }
    return null;
  }

  bool _skipFilledCellsEnabled() {
    return ref.read(skipFilledCellsProvider).when(
          data: (value) => value,
          loading: () => false,
          error: (_, __) => false,
        );
  }

  FocusPosition _retreatFocus(SolveState s, int row, int col) {
    final clue = _clueFor(s, row, col, s.focus.direction);
    if (clue == null) return s.focus;
    final cells = ClueProgressCalculator.cellsFor(clue);
    final idx = cells.indexWhere((p) => p.$1 == row && p.$2 == col);
    if (idx <= 0) return s.focus;
    for (var i = idx - 1; i >= 0; i--) {
      final (pr, pc) = cells[i];
      if (!_isCellLocked(s, pr, pc)) {
        return FocusPosition(row: pr, col: pc, direction: s.focus.direction);
      }
    }
    final (pr, pc) = cells[idx - 1];
    return FocusPosition(row: pr, col: pc, direction: s.focus.direction);
  }

  Direction? _preferredDirectionForTap(SolveState s, int row, int col) {
    final currentClue = _clueFor(s, row, col, s.focus.direction);
    final otherDir = _otherDirection(s.focus.direction);
    final otherClue = _clueFor(s, row, col, otherDir);

    if (currentClue != null &&
        !_isWordComplete(s, currentClue) &&
        !_isCellLocked(s, row, col)) {
      return s.focus.direction;
    }
    if (otherClue != null && !_isWordComplete(s, otherClue)) {
      return otherDir;
    }
    if (currentClue != null) return s.focus.direction;
    if (otherClue != null) return otherDir;
    return null;
  }

  Direction _otherDirection(Direction direction) =>
      direction == Direction.across ? Direction.down : Direction.across;

  FocusPosition _focusForClue(
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
      if (_isOpenCell(s, r, c)) {
        return FocusPosition(row: r, col: c, direction: clue.direction);
      }
    }
    for (var i = 0; i < start; i++) {
      final (r, c) = cells[i];
      if (_isOpenCell(s, r, c)) {
        return FocusPosition(row: r, col: c, direction: clue.direction);
      }
    }
    return FocusPosition(row: row, col: col, direction: clue.direction);
  }

  FocusPosition _focusForTappedCell(
    SolveState s,
    Clue clue,
    int row,
    int col,
  ) {
    if (!_isCellLocked(s, row, col)) {
      return FocusPosition(row: row, col: col, direction: clue.direction);
    }
    return _focusForClue(s, clue, row, col);
  }

  bool _isOpenCell(SolveState s, int row, int col) {
    return !_isCellLocked(s, row, col) &&
        s.progress.cell(row, col).letter.isEmpty;
  }

  bool _isCellLocked(SolveState s, int row, int col) {
    final cell = s.progress.cell(row, col);
    return cell.state == CellState.checkedCorrect ||
        cell.state == CellState.revealed;
  }

  bool _hasWord(SolveState s, int row, int col, Direction dir) {
    for (final clue in s.puzzle.clues) {
      if (clue.direction == dir && SolveState.cellInClue(row, col, clue)) {
        return true;
      }
    }
    return false;
  }

  Clue? _clueFor(SolveState s, int row, int col, Direction dir) {
    for (final clue in s.puzzle.clues) {
      if (clue.direction == dir && SolveState.cellInClue(row, col, clue)) {
        return clue;
      }
    }
    return null;
  }

  bool _isWordComplete(SolveState s, Clue clue) =>
      ClueProgressCalculator.isClueCorrect(
        puzzle: s.puzzle,
        progress: s.progress,
        clue: clue,
      );

  // ---------------------------------------------------------------------------
  // Completion check
  // ---------------------------------------------------------------------------

  void _checkCompletion() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return;

    for (var r = 0; r < s.puzzle.height; r++) {
      for (var c = 0; c < s.puzzle.width; c++) {
        final cell = s.puzzle.grid.cell(r, c);
        if (cell.isBlack) continue;
        final prog = s.progress.cell(r, c);
        if (prog.letter.isEmpty ||
            prog.letter.toUpperCase() != cell.solution.toUpperCase()) {
          return;
        }
      }
    }

    _timerSub?.cancel();
    _saveDebounce?.cancel();

    // Distinguish reveal-assisted from check-only from clean
    final finalStatus = s.usedReveal
        ? PuzzleStatus.solvedWithReveal
        : s.usedCheck
            ? PuzzleStatus.solvedWithHelp
            : PuzzleStatus.solved;
    final completed = s.copyWith(status: finalStatus);
    state = AsyncData(completed);

    if (s.sessionId != null) {
      _persistCompletion(completed);
    }
  }

  void _persistCompletion(SolveState s) {
    final repo = ref.read(solveRepositoryProvider);
    unawaited(
      repo
          .markComplete(
        sessionId: s.sessionId!,
        puzzleId: s.puzzle.id,
        puzzleWidth: s.puzzle.width,
        puzzleHeight: s.puzzle.height,
        progress: s.progress,
        focus: s.focus,
        elapsedMs: s.elapsedSeconds * 1000,
        status: s.status,
        completionType: _deriveCompletionType(s),
        checkCount: s.checkCount,
        revealCount: s.revealCount,
        usedCheck: s.usedCheck,
        usedReveal: s.usedReveal,
        cleanSolveEligible: s.cleanSolveEligible,
      )
          .then((_) {
        ref.invalidate(statsDataProvider);
      }),
    );
  }

  /// Derives [CompletionType] from the solve flags.
  CompletionType _deriveCompletionType(SolveState s) {
    if (s.status == PuzzleStatus.revealed) return CompletionType.revealed;
    if (s.usedReveal) return CompletionType.hinted;
    if (s.usedCheck) return CompletionType.checked;
    return CompletionType.clean;
  }

  bool _isTerminal(PuzzleStatus status) =>
      status == PuzzleStatus.solved ||
      status == PuzzleStatus.solvedWithHelp ||
      status == PuzzleStatus.solvedWithReveal ||
      status == PuzzleStatus.revealed;

  int? _personalBestForSize({
    required int width,
    required int height,
    required int? personalBestMiniMs,
    required int? personalBest15x15Ms,
    required int? personalBest21x21Ms,
  }) {
    if (width <= 7 && height <= 7) return personalBestMiniMs;
    if (width == 15 && height == 15) return personalBest15x15Ms;
    if (width == 21 && height == 21) return personalBest21x21Ms;
    return null;
  }
}
