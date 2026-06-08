import 'dart:async';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/challenge_boards/domain/services/challenge_solve_submission_mapper.dart';
import 'package:crosscue/features/challenge_boards/presentation/providers/challenge_board_providers.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/models/solve_errors.dart';
import 'package:crosscue/features/solve/domain/repositories/solve_repository.dart';
import 'package:crosscue/features/solve/domain/services/grid_progress_mutator.dart';
import 'package:crosscue/features/solve/domain/services/solve_focus_navigator.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_elapsed_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/providers/solve_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'solve_notifier.g.dart';

@riverpod
class SolveNotifier extends _$SolveNotifier {
  // Compiled once; reused on every keystroke / rebus entry.
  static final _singleLetterRe = RegExp(r'^[A-Z]$');
  // Rebus entries accept A-Z plus "/" for bidirectional rebuses
  // (e.g. "PB/AU" — see SolutionCellAccepts).
  static final _nonRebusRe = RegExp(r'[^A-Z/]');

  /// Maximum length of a rebus answer. Real-world rebuses top out at 5
  /// characters; one buffer character covers exotic cases without
  /// breaking the cell autoshrink budget in the painter.
  static const int rebusMaxLength = 6;

  Timer? _saveDebounce;

  /// Set once the backing puzzle is deleted out from under an open screen.
  /// Stops further saves and short-circuits the [flushOnDispose] backstop so we
  /// never try to persist a session whose parent row is already gone.
  bool _puzzleRemoved = false;

  /// Captured once in [build] so the teardown flush can persist without
  /// touching `ref` (unsafe inside `onDispose`). The repo provider is
  /// keepAlive, so this reference stays valid for the notifier's lifetime.
  late SolveRepository _solveRepo;

  /// Mirror of the live [SolveElapsedSeconds] value, kept current by the
  /// listener wired in [build]. Lets [flushOnDispose] read the clock without
  /// `ref`, and serves as the canonical elapsed source elsewhere.
  int _liveElapsedSeconds = 0;

  /// Safely read the current SolveState from AsyncValue.
  SolveState? get _s => switch (state) {
        AsyncData(:final value) => value,
        _ => null,
      };

  /// Plain mirror of the latest data state, kept current by the [state] setter
  /// and the initial [build] return. Read by [flushOnDispose], which runs
  /// inside `onDispose` where touching `state`/`ref` throws.
  SolveState? _latestState;

  @override
  set state(AsyncValue<SolveState> value) {
    super.state = value;
    if (value case AsyncData(value: final data)) {
      _latestState = data;
    }
  }

  /// Live elapsed-second counter for this puzzle. Owned by
  /// [SolveElapsedSeconds] so that per-second ticks don't broadcast through
  /// the SolveNotifier and rebuild the entire solve screen each second.
  ///
  /// SolveNotifier still treats this as the canonical source of elapsed time
  /// when it saves to the DB or persists a completion — the snapshot kept on
  /// [SolveState.elapsedSeconds] is refreshed from here at save/pause/
  /// completion boundaries so [CompletionSheet] (which reads from state) sees
  /// the right value. Backed by [_liveElapsedSeconds], which the [build]
  /// listener keeps in lockstep with the provider.
  int get _elapsedSeconds => _liveElapsedSeconds;

  @override
  Future<SolveState> build(String puzzleId) async {
    ref.onDispose(() {
      _saveDebounce?.cancel();
      // Teardown backstop: persist the live clock for an in-progress puzzle on
      // the way out so it isn't lost — see [flushOnDispose].
      unawaited(flushOnDispose());
    });

    // Mirror the per-second elapsed provider into [_liveElapsedSeconds] for the
    // whole solve session. Two jobs:
    //   1. Keep-alive — the provider is auto-dispose and only SolveAppBar
    //      *watches* it, but the AppBar doesn't mount until this build resolves
    //      (after `start()` below). Without a listener here the timer would be
    //      torn down in that gap and the clock would freeze at 0.
    //   2. Caching — `onDispose` (and `_elapsedSeconds`) can read the value
    //      without `ref`, which is unsafe during disposal.
    // The callback does not rebuild SolveNotifier, so per-tick broadcasts stay
    // off the solve-screen rebuild path — the whole point of #130.
    ref.listen(
      solveElapsedSecondsProvider(puzzleId),
      (_, next) => _liveElapsedSeconds = next,
      fireImmediately: true,
    );

    final importRepo = ref.read(importRepositoryProvider);
    final solveRepo = ref.read(solveRepositoryProvider);
    _solveRepo = solveRepo;

    final puzzle = await importRepo.getPuzzle(Uri.decodeComponent(puzzleId));
    if (puzzle == null) throw PuzzleNotFoundError(puzzleId);

    // React if the puzzle is deleted while this screen is open (Archive
    // removal, "Clear all data", or a re-import). The cascade tears down the
    // session + cell rows, so keep autosaving would be a no-op at best (guarded
    // in SolveSessionDao) and the user would be editing a session that can
    // never persist. Surface the same not-found state a cold load shows.
    final existsSub = importRepo.watchPuzzleExists(puzzle.id).listen((exists) {
      if (!exists) _handlePuzzleRemoved();
    });
    ref.onDispose(existsSub.cancel);

    final session = await solveRepo.createOrResumeSession(puzzle);
    final stats = await ref.read(statsRepositoryProvider).getStats();

    final elapsedSec = session.elapsedMs ~/ 1000;
    final elapsedNotifier = ref
        .read(solveElapsedSecondsProvider(puzzleId).notifier)
      ..seed(elapsedSec);
    // Don't tick while paused or after a terminal completion is resumed.
    if (!session.isPaused && !session.status.isTerminal) {
      elapsedNotifier.start();
    }

    return _latestState = SolveState(
      puzzle: puzzle,
      progress: session.progress,
      focus: session.focus,
      status: session.status,
      elapsedSeconds: elapsedSec,
      isPaused: session.isPaused,
      sessionId: session.sessionId,
      checkCount: session.checkCount,
      revealCount: session.revealCount,
      usedCheck: session.usedCheck,
      usedReveal: session.usedReveal,
      cleanSolveEligible: session.cleanSolveEligible,
      previousPersonalBestMs: stats.personalBestMsFor(puzzle.sizeBucket),
    );
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void pause() {
    final s = _s;
    if (s == null || s.isPaused) return;
    ref.read(solveElapsedSecondsProvider(puzzleId).notifier).stop();
    // Snapshot elapsed into the state so the autosave below persists the
    // exact second the user paused on.
    state =
        AsyncData(s.copyWith(isPaused: true, elapsedSeconds: _elapsedSeconds));
    _saveNow();
  }

  void resume() {
    final s = _s;
    if (s == null || !s.isPaused) return;
    state = AsyncData(s.copyWith(isPaused: false));
    if (!s.status.isTerminal) {
      ref.read(solveElapsedSecondsProvider(puzzleId).notifier).start();
    }
  }

  /// Records that the completion celebration sheet has been shown for this
  /// solve, so it isn't re-triggered on widget recreation (backgrounding,
  /// hot reload). Idempotent. Cleared by [resetPuzzle].
  void markCompletionSheetShown() {
    final s = _s;
    if (s == null || s.completionSheetShown) return;
    state = AsyncData(s.copyWith(completionSheetShown: true));
  }

  // ---------------------------------------------------------------------------
  // Cell tap / direction toggle
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Keyboard input
  // ---------------------------------------------------------------------------

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
  ///   - Anything longer than [rebusMaxLength] is truncated.
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
    if (upper.length > rebusMaxLength) {
      upper = upper.substring(0, rebusMaxLength);
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
  // --------------------------------------------------------------------

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
    _saveDebounce?.cancel();

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
    ref.read(solveElapsedSecondsProvider(puzzleId).notifier)
      ..reset()
      ..start();

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
        completionSheetShown: false,
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
    // Pull the latest elapsed value from the live notifier so the persisted
    // row reflects the second the user actually saw, not the snapshot from
    // the last state mutation. Terminal paths (pause/completion/reveal/reset)
    // already snapshotted into state.elapsedSeconds — use whichever is fresher.
    final elapsedSec =
        s.status.isTerminal || s.isPaused ? s.elapsedSeconds : _elapsedSeconds;
    await _save(s, elapsedSec);
  }

  Future<void> _save(SolveState s, int elapsedSec) async {
    await _solveRepo.saveProgress(
      sessionId: s.sessionId!,
      puzzleWidth: s.puzzle.width,
      puzzleHeight: s.puzzle.height,
      progress: s.progress,
      focus: s.focus,
      elapsedMs: elapsedSec * 1000,
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

  /// Invoked when the backing puzzle is deleted while this screen is open.
  /// Stops the autosave + timer and flips to the same [PuzzleNotFoundError]
  /// state a cold load surfaces, so SolveScreen shows "this puzzle no longer
  /// exists" instead of letting the user edit a session that can never persist.
  /// Idempotent — the existence stream can emit more than once.
  void _handlePuzzleRemoved() {
    if (_puzzleRemoved) return;
    _puzzleRemoved = true;
    _saveDebounce?.cancel();
    ref.read(solveElapsedSecondsProvider(puzzleId).notifier).stop();
    state = AsyncError(PuzzleNotFoundError(puzzleId), StackTrace.current);
  }

  /// Teardown backstop, invoked from [build]'s `onDispose`. Owning this on the
  /// notifier (not the widget) means the guarantee survives any disposal path,
  /// and it reads only captured fields (`_latestState`, `_solveRepo`,
  /// `_liveElapsedSeconds`) — never `state` or `ref`, which throw inside
  /// `onDispose`.
  ///
  /// Persists the live clock for an in-progress puzzle so leaving one you never
  /// typed into doesn't reset the timer on re-entry (the debounced autosave
  /// only fires on edits; `pause()` only on backgrounding).
  ///
  /// No-op for paused sessions ([pause] already saved them) and for terminal
  /// sessions: [_persistCompletion]'s `markComplete` already persisted those
  /// authoritatively across both tables, and re-saving via `saveProgress` here
  /// would null the cached `completionType` (locked by
  /// `solve_completion_roundtrip_test`). Force-quit of a terminal session is
  /// covered by the `detached` lifecycle handler in SolveScreen.
  Future<void> flushOnDispose() async {
    if (_puzzleRemoved) return; // parent is gone — nothing to persist.
    final s = _latestState;
    if (s == null || s.sessionId == null) return;
    if (s.status.isTerminal || s.isPaused) return;
    await _save(s, _liveElapsedSeconds);
  }

  // ---------------------------------------------------------------------------
  // Settings reads
  // ---------------------------------------------------------------------------

  bool _skipFilledCellsEnabled() => ref.read(skipFilledCellsProvider);

  // ---------------------------------------------------------------------------
  // Completion check
  // ---------------------------------------------------------------------------

  void _checkCompletion() {
    final s = _s;
    if (s == null || s.status.isTerminal) return;

    for (var r = 0; r < s.puzzle.height; r++) {
      for (var c = 0; c < s.puzzle.width; c++) {
        final cell = s.puzzle.grid.cell(r, c);
        if (cell.isBlack) continue;
        final prog = s.progress.cell(r, c);
        // Acceptance (incl. first-letter on rebus, bidirectional rebus)
        // is centralized on SolutionCell — see SolutionCellAccepts.
        if (!cell.accepts(prog.letter)) {
          return;
        }
      }
    }

    ref.read(solveElapsedSecondsProvider(puzzleId).notifier).stop();
    _saveDebounce?.cancel();

    // Distinguish reveal-assisted from check-only from clean
    final finalStatus = s.usedReveal
        ? PuzzleStatus.solvedWithReveal
        : s.usedCheck
            ? PuzzleStatus.solvedWithHelp
            : PuzzleStatus.solved;
    // Snapshot the live counter so the persisted completion + the
    // CompletionSheet read the same elapsed value.
    final completed =
        s.copyWith(status: finalStatus, elapsedSeconds: _elapsedSeconds);
    state = AsyncData(completed);

    if (s.sessionId != null) {
      _persistCompletion(completed);
    }
  }

  void _persistCompletion(SolveState s) {
    final repo = ref.read(solveRepositoryProvider);
    final completionType = _deriveCompletionType(s);
    final completedAtUtc = DateTime.now().toUtc();
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
        completionType: completionType,
        checkCount: s.checkCount,
        revealCount: s.revealCount,
        usedCheck: s.usedCheck,
        usedReveal: s.usedReveal,
        cleanSolveEligible: s.cleanSolveEligible,
      )
          .then((_) {
        ref.invalidate(statsDataProvider);
        final submission = challengeSubmissionFromCompletion(
          puzzle: s.puzzle,
          elapsedMs: s.elapsedSeconds * 1000,
          completionType: completionType,
          cleanSolveEligible: s.cleanSolveEligible,
          completedAtUtc: completedAtUtc,
        );
        if (submission != null) {
          unawaited(
            ref
                .read(challengeResultSubmitterProvider)
                .submitOrQueue(submission),
          );
        }
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
}
