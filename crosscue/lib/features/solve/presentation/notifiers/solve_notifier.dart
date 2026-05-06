import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/presentation/providers/solve_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/clue.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/models/grid.dart';
import 'solve_state.dart';

part 'solve_notifier.g.dart';

@riverpod
class SolveNotifier extends _$SolveNotifier {
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
    if (puzzle == null) throw Exception('Puzzle not found: $puzzleId');

    final session = await solveRepo.createOrResumeSession(puzzle);
    final stats = await ref.read(statsRepositoryProvider).getStats();

    _startTimer();

    return SolveState(
      puzzle: puzzle,
      progress: session.progress,
      focus: session.focus,
      status: PuzzleStatus.inProgress,
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
  /// Used by the ClueBar tap gesture (Sprint 10).
  void toggleDirection() {
    final s = _s;
    if (s == null) return;
    final newDir = s.focus.direction == Direction.across
        ? Direction.down
        : Direction.across;
    if (_hasWord(s, s.focus.row, s.focus.col, newDir)) {
      state = AsyncData(s.copyWith(focus: s.focus.copyWith(direction: newDir)));
    }
  }

  void tapCell(int row, int col) {
    final s = _s;
    if (s == null) return;
    if (s.puzzle.grid.cell(row, col).isBlack) return;

    if (s.focus.row == row && s.focus.col == col) {
      final newDir = s.focus.direction == Direction.across
          ? Direction.down
          : Direction.across;
      if (_hasWord(s, row, col, newDir)) {
        state =
            AsyncData(s.copyWith(focus: s.focus.copyWith(direction: newDir)));
      }
    } else {
      Direction dir = s.focus.direction;
      if (!_hasWord(s, row, col, dir)) {
        dir = dir == Direction.across ? Direction.down : Direction.across;
      }
      state = AsyncData(
          s.copyWith(focus: FocusPosition(row: row, col: col, direction: dir)));
    }
  }

  // ---------------------------------------------------------------------------
  // Keyboard input
  // ---------------------------------------------------------------------------

  bool inputLetter(String letter) {
    final s = _s;
    if (s == null || s.isPaused) return false;

    final upper = letter.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(upper)) return false;

    final r = s.focus.row;
    final c = s.focus.col;

    // Do not overwrite a revealed cell (topic-11)
    if (s.progress.cell(r, c).state == CellState.revealed) return false;
    final clue = _clueFor(s, r, c, s.focus.direction);
    final wasWordComplete = clue != null && _isWordComplete(s, clue);

    // Any typed letter resets the cell to plain filled — clears checkedIncorrect,
    // checkedCorrect, and pencil marks alike (topic-11).
    final newProgress = s.progress.withCell(
      r,
      c,
      s.progress.cell(r, c).copyWith(letter: upper, state: CellState.filled),
    );
    final nextFocus = _advanceFocus(
      s,
      r,
      c,
      skipFilledCells: _skipFilledCellsEnabled(),
    );
    final updated = s.copyWith(progress: newProgress, focus: nextFocus);
    state = AsyncData(updated);
    _scheduleSave();
    _checkCompletion();
    return clue != null && !wasWordComplete && _isWordComplete(updated, clue);
  }

  void backspace() {
    final s = _s;
    if (s == null || s.isPaused) return;

    final r = s.focus.row;
    final c = s.focus.col;
    final current = s.progress.cell(r, c);

    // Do not erase a revealed cell
    if (current.state == CellState.revealed) return;

    if (current.letter.isNotEmpty) {
      final newProgress = s.progress.withCell(r, c, CellProgress.blank);
      state = AsyncData(s.copyWith(progress: newProgress));
    } else {
      final prevFocus = _retreatFocus(s, r, c);
      final prev = s.progress.cell(prevFocus.row, prevFocus.col);
      // Do not erase a revealed cell when retreating
      if (prev.state == CellState.revealed) {
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
  // Reset
  // ---------------------------------------------------------------------------

  /// Clears all progress, counters, and the timer back to a fresh state.
  /// Reuses the existing session row (overwrites it) rather than creating a new one.
  void resetPuzzle() {
    final s = _s;
    if (s == null) return;

    // Find first non-black cell for focus
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

    state = AsyncData(s.copyWith(
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
    ));

    _saveNow(); // Persist the reset immediately
  }

  // ---------------------------------------------------------------------------
  // Check actions (topic-11)
  // ---------------------------------------------------------------------------

  /// Checks the focused cell. Empty cells are skipped silently.
  CheckResult checkCell() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return CheckResult.noop;

    final r = s.focus.row;
    final c = s.focus.col;
    final cell = s.progress.cell(r, c);
    if (cell.letter.isEmpty) return CheckResult.noop;

    final correct = cell.letter.toUpperCase() ==
        s.puzzle.grid.cell(r, c).solution.toUpperCase();
    final newState =
        correct ? CellState.checkedCorrect : CellState.checkedIncorrect;

    final newProgress = s.progress.withCell(
      r,
      c,
      cell.copyWith(state: newState),
    );

    state = AsyncData(s.copyWith(
      progress: newProgress,
      checkCount: s.checkCount + 1,
      usedCheck: true,
    ));
    _scheduleSave();
    return correct ? CheckResult.allCorrect : CheckResult.hasIncorrect;
  }

  /// Checks all filled cells in the active word.
  CheckResult checkWord() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return CheckResult.noop;

    final clue = _clueFor(s, s.focus.row, s.focus.col, s.focus.direction);
    if (clue == null) return CheckResult.noop;

    var progress = s.progress;
    var checkedAny = false;
    var hasIncorrect = false;
    for (final (r, c) in _clueCells(clue)) {
      final cell = progress.cell(r, c);
      if (cell.letter.isEmpty) continue;
      final correct = cell.letter.toUpperCase() ==
          s.puzzle.grid.cell(r, c).solution.toUpperCase();
      checkedAny = true;
      hasIncorrect = hasIncorrect || !correct;
      progress = progress.withCell(
        r,
        c,
        cell.copyWith(
            state: correct
                ? CellState.checkedCorrect
                : CellState.checkedIncorrect),
      );
    }
    if (!checkedAny) return CheckResult.noop;

    state = AsyncData(s.copyWith(
      progress: progress,
      checkCount: s.checkCount + 1,
      usedCheck: true,
    ));
    _scheduleSave();
    return hasIncorrect ? CheckResult.hasIncorrect : CheckResult.allCorrect;
  }

  /// Checks all filled cells in the puzzle.
  CheckResult checkGrid() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return CheckResult.noop;

    var progress = s.progress;
    var checkedAny = false;
    var hasIncorrect = false;
    for (var r = 0; r < s.puzzle.height; r++) {
      for (var c = 0; c < s.puzzle.width; c++) {
        if (s.puzzle.grid.cell(r, c).isBlack) continue;
        final cell = progress.cell(r, c);
        if (cell.letter.isEmpty) continue;
        final correct = cell.letter.toUpperCase() ==
            s.puzzle.grid.cell(r, c).solution.toUpperCase();
        checkedAny = true;
        hasIncorrect = hasIncorrect || !correct;
        progress = progress.withCell(
          r,
          c,
          cell.copyWith(
              state: correct
                  ? CellState.checkedCorrect
                  : CellState.checkedIncorrect),
        );
      }
    }
    if (!checkedAny) return CheckResult.noop;

    state = AsyncData(s.copyWith(
      progress: progress,
      checkCount: s.checkCount + 1,
      usedCheck: true,
    ));
    _scheduleSave();
    return hasIncorrect ? CheckResult.hasIncorrect : CheckResult.allCorrect;
  }

  // ---------------------------------------------------------------------------
  // Reveal actions (topic-11)
  // ---------------------------------------------------------------------------

  /// Fills the focused cell with the solution and marks it revealed.
  void revealCell() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return;

    final r = s.focus.row;
    final c = s.focus.col;
    if (s.puzzle.grid.cell(r, c).isBlack) return;

    final solution = s.puzzle.grid.cell(r, c).solution;
    final newProgress = s.progress.withCell(
      r,
      c,
      s.progress.cell(r, c).copyWith(
            letter: solution,
            state: CellState.revealed,
          ),
    );

    final updated = s.copyWith(
      progress: newProgress,
      revealCount: s.revealCount + 1,
      usedReveal: true,
      cleanSolveEligible: false,
    );
    state = AsyncData(updated);
    _scheduleSave();
    _checkCompletion();
  }

  /// Fills all cells in the active word with their solutions.
  void revealWord() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return;

    final clue = _clueFor(s, s.focus.row, s.focus.col, s.focus.direction);
    if (clue == null) return;

    var progress = s.progress;
    for (final (r, c) in _clueCells(clue)) {
      final solution = s.puzzle.grid.cell(r, c).solution;
      progress = progress.withCell(
        r,
        c,
        progress.cell(r, c).copyWith(
              letter: solution,
              state: CellState.revealed,
            ),
      );
    }

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
  /// (does NOT count as a solve; topic-11).
  void revealPuzzle() {
    final s = _s;
    if (s == null || _isTerminal(s.status)) return;

    var progress = s.progress;
    for (var r = 0; r < s.puzzle.height; r++) {
      for (var c = 0; c < s.puzzle.width; c++) {
        if (s.puzzle.grid.cell(r, c).isBlack) continue;
        final solution = s.puzzle.grid.cell(r, c).solution;
        progress = progress.withCell(
          r,
          c,
          progress.cell(r, c).copyWith(
                letter: solution,
                state: CellState.revealed,
              ),
        );
      }
    }

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
    final cells = _clueCells(clue);
    final idx = cells.indexWhere((p) => p.$1 == row && p.$2 == col);
    if (idx == -1 || idx >= cells.length - 1) return s.focus;
    if (skipFilledCells) {
      for (var i = idx + 1; i < cells.length; i++) {
        final (nr, nc) = cells[i];
        if (s.progress.cell(nr, nc).letter.isEmpty) {
          return FocusPosition(row: nr, col: nc, direction: s.focus.direction);
        }
      }
    }
    final (nr, nc) = cells[idx + 1];
    return FocusPosition(row: nr, col: nc, direction: s.focus.direction);
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
    final cells = _clueCells(clue);
    final idx = cells.indexWhere((p) => p.$1 == row && p.$2 == col);
    if (idx <= 0) return s.focus;
    final (pr, pc) = cells[idx - 1];
    return FocusPosition(row: pr, col: pc, direction: s.focus.direction);
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

  List<(int, int)> _clueCells(Clue clue) => [
        for (var i = 0; i < clue.length; i++)
          clue.direction == Direction.across
              ? (clue.startRow, clue.startCol + i)
              : (clue.startRow + i, clue.startCol),
      ];

  bool _isWordComplete(SolveState s, Clue clue) {
    for (final (r, c) in _clueCells(clue)) {
      final progress = s.progress.cell(r, c);
      final solution = s.puzzle.grid.cell(r, c).solution;
      if (progress.letter.isEmpty ||
          progress.letter.toUpperCase() != solution.toUpperCase()) {
        return false;
      }
    }
    return true;
  }

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

    // Distinguish reveal-assisted from check-only from clean (spec §08)
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
          .then((_) => ref.invalidate(statsDataProvider)),
    );
  }

  /// Derives [CompletionType] from the solve flags (topic-15).
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

enum CheckResult {
  noop,
  allCorrect,
  hasIncorrect;

  bool get shouldVibrate => this == CheckResult.hasIncorrect;
}
