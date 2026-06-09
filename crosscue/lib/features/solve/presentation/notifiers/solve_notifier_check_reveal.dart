part of 'solve_notifier.dart';

/// Check and reveal assists. Check actions mark filled cells correct/incorrect
/// and bump [SolveState.checkCount]; reveal actions fill cells from the
/// solution, bump [SolveState.revealCount], and forfeit clean-solve
/// eligibility. The whole-puzzle [revealPuzzle] is terminal — it stops the
/// clock and persists a `revealed` completion.
///
/// Applied to [SolveNotifier], which implements the shared members re-declared
/// abstract here ([_s], [_elapsedSeconds], [_scheduleSave], [_checkCompletion],
/// [_persistCompletion], [_cancelPendingSave]).
mixin _SolveCheckReveal on _$SolveNotifier {
  // --- Shared orchestration surface (implemented by SolveNotifier) ---
  SolveState? get _s;
  int get _elapsedSeconds;
  void _scheduleSave();
  void _checkCompletion();
  void _cancelPendingSave();
  void _persistCompletion(SolveState s);

  // ---------------------------------------------------------------------------
  // Check actions
  // ---------------------------------------------------------------------------

  /// Checks the focused cell. Empty cells are skipped silently.
  CheckResult checkCell() {
    final s = _s;
    if (s == null || s.status.isTerminal) return CheckResult.noop;

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
    if (s == null || s.status.isTerminal) return CheckResult.noop;

    final clue = s.clueFor(s.focus.row, s.focus.col, s.focus.direction);
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
    if (s == null || s.status.isTerminal) return CheckResult.noop;

    final mutation = GridProgressMutator.checkCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: GridProgressMutator.puzzleCells(s.puzzle),
    );
    return _applyCheckMutation(s, mutation);
  }

  // ---------------------------------------------------------------------------
  // Reveal actions
  // ---------------------------------------------------------------------------

  /// Fills the focused cell with the solution and marks it revealed.
  void revealCell() {
    final s = _s;
    if (s == null || s.status.isTerminal) return;

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
    if (s == null || s.status.isTerminal) return;

    final clue = s.clueFor(s.focus.row, s.focus.col, s.focus.direction);
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
    if (s == null || s.status.isTerminal) return;

    final progress = GridProgressMutator.revealCells(
      puzzle: s.puzzle,
      progress: s.progress,
      cells: GridProgressMutator.puzzleCells(s.puzzle),
    );

    ref.read(solveElapsedSecondsProvider(puzzleId).notifier).stop();
    _cancelPendingSave();

    final completed = s.copyWith(
      progress: progress,
      status: PuzzleStatus.revealed,
      revealCount: s.revealCount + 1,
      usedReveal: true,
      cleanSolveEligible: false,
      // Snapshot the live counter so the persisted completion + the
      // CompletionSheet read the same elapsed value.
      elapsedSeconds: _elapsedSeconds,
    );
    state = AsyncData(completed);

    if (s.sessionId != null) {
      _persistCompletion(completed);
    }
  }
}
