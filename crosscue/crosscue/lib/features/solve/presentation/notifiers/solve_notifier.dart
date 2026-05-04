import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/import/presentation/providers/import_providers.dart';
import '../../domain/models/cell_progress.dart';
import '../../domain/models/clue.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/focus_position.dart';
import '../../domain/models/grid.dart';
import 'solve_state.dart';

part 'solve_notifier.g.dart';

@riverpod
class SolveNotifier extends _$SolveNotifier {
  StreamSubscription<int>? _timerSub;

  /// Safely read the current SolveState from AsyncValue.
  SolveState? get _s => switch (state) {
        AsyncData(:final value) => value,
        _ => null,
      };

  @override
  Future<SolveState> build(String puzzleId) async {
    ref.onDispose(() {
      _timerSub?.cancel();
    });

    final repo = ref.read(importRepositoryProvider);
    final puzzle = await repo.getPuzzle(Uri.decodeComponent(puzzleId));
    if (puzzle == null) throw Exception('Puzzle not found: $puzzleId');

    // Blank progress grid
    final progress = Grid<CellProgress>.generate(
      puzzle.width,
      puzzle.height,
      (r, c) => CellProgress.blank,
    );

    // Find first non-black cell
    FocusPosition focus = const FocusPosition(
      row: 0,
      col: 0,
      direction: Direction.across,
    );
    outer:
    for (var r = 0; r < puzzle.height; r++) {
      for (var c = 0; c < puzzle.width; c++) {
        if (!puzzle.grid.cell(r, c).isBlack) {
          focus = FocusPosition(row: r, col: c, direction: Direction.across);
          break outer;
        }
      }
    }

    _startTimer();
    return SolveState(
      puzzle: puzzle,
      progress: progress,
      focus: focus,
      status: PuzzleStatus.unsolved,
      elapsedSeconds: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timerSub?.cancel();
    _timerSub = Stream<int>.periodic(const Duration(seconds: 1), (i) => i).listen((_) {
      final s = _s;
      if (s == null || s.isPaused) return;
      if (s.status == PuzzleStatus.solved ||
          s.status == PuzzleStatus.solvedWithHelp ||
          s.status == PuzzleStatus.revealed) {
        return;
      }
      state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1));
    });
  }

  void pause() {
    final s = _s;
    if (s == null || s.isPaused) return;
    state = AsyncData(s.copyWith(isPaused: true));
  }

  void resume() {
    final s = _s;
    if (s == null || !s.isPaused) return;
    state = AsyncData(s.copyWith(isPaused: false));
  }

  // ---------------------------------------------------------------------------
  // Cell tap / direction toggle
  // ---------------------------------------------------------------------------

  void tapCell(int row, int col) {
    final s = _s;
    if (s == null) return;

    if (s.puzzle.grid.cell(row, col).isBlack) return;

    if (s.focus.row == row && s.focus.col == col) {
      final newDir = s.focus.direction == Direction.across
          ? Direction.down
          : Direction.across;
      if (_hasWord(s, row, col, newDir)) {
        state = AsyncData(s.copyWith(focus: s.focus.copyWith(direction: newDir)));
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

  void inputLetter(String letter) {
    final s = _s;
    if (s == null || s.isPaused) return;

    final upper = letter.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(upper)) return;

    final r = s.focus.row;
    final c = s.focus.col;
    final newProgress = s.progress.withCell(
      r,
      c,
      s.progress.cell(r, c).copyWith(letter: upper, state: CellState.filled),
    );
    final nextFocus = _advanceFocus(s, r, c);
    state = AsyncData(s.copyWith(progress: newProgress, focus: nextFocus));
    _checkCompletion();
  }

  void backspace() {
    final s = _s;
    if (s == null || s.isPaused) return;

    final r = s.focus.row;
    final c = s.focus.col;
    final current = s.progress.cell(r, c);

    if (current.letter.isNotEmpty) {
      final newProgress = s.progress.withCell(r, c, CellProgress.blank);
      state = AsyncData(s.copyWith(progress: newProgress));
    } else {
      final prevFocus = _retreatFocus(s, r, c);
      final newProgress =
          s.progress.withCell(prevFocus.row, prevFocus.col, CellProgress.blank);
      state = AsyncData(s.copyWith(progress: newProgress, focus: prevFocus));
    }
  }

  // ---------------------------------------------------------------------------
  // Focus movement
  // ---------------------------------------------------------------------------

  FocusPosition _advanceFocus(SolveState s, int row, int col) {
    final clue = _clueFor(s, row, col, s.focus.direction);
    if (clue == null) return s.focus;
    final cells = _clueCells(clue);
    final idx = cells.indexWhere((p) => p.$1 == row && p.$2 == col);
    if (idx == -1 || idx >= cells.length - 1) return s.focus;
    for (var i = idx + 1; i < cells.length; i++) {
      final (nr, nc) = cells[i];
      if (s.progress.cell(nr, nc).letter.isEmpty) {
        return FocusPosition(row: nr, col: nc, direction: s.focus.direction);
      }
    }
    final (nr, nc) = cells[idx + 1];
    return FocusPosition(row: nr, col: nc, direction: s.focus.direction);
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

  // ---------------------------------------------------------------------------
  // Completion check
  // ---------------------------------------------------------------------------

  void _checkCompletion() {
    final s = _s;
    if (s == null) return;
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
    state = AsyncData(s.copyWith(status: PuzzleStatus.solved));
    _timerSub?.cancel();
  }
}
