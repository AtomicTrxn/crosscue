part of 'crossword_grid.dart';

extension _CrosswordGridEffects on _CrosswordGridState {
  void _startCellEffects(SolveState previous, SolveState current) {
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (animationsDisabled) {
      _effects = const {};
      _previousSolveStateForEffect = null;
      return;
    }

    final effects = <(int, int), GridCellEffect>{};
    final isCompleting = !_isTerminal(previous.status) &&
        _isTerminal(current.status) &&
        current.status != PuzzleStatus.revealed;

    for (var r = 0; r < current.puzzle.height; r++) {
      for (var c = 0; c < current.puzzle.width; c++) {
        if (current.puzzle.grid.cell(r, c).isBlack) continue;

        if (isCompleting) {
          effects[(r, c)] =
              const GridCellEffect(GridCellEffectType.puzzleComplete);
          continue;
        }

        final oldCell = previous.progress.cell(r, c);
        final newCell = current.progress.cell(r, c);
        if (oldCell == newCell) continue;

        final stateEffect = _stateEffect(oldCell.state, newCell.state);
        if (stateEffect != null) {
          effects[(r, c)] = GridCellEffect(stateEffect);
          continue;
        }

        if (oldCell.letter != newCell.letter) {
          if (newCell.letter.isNotEmpty) {
            effects[(r, c)] = const GridCellEffect(GridCellEffectType.entry);
          } else if (oldCell.letter.isNotEmpty) {
            effects[(r, c)] = GridCellEffect(
              GridCellEffectType.backspace,
              oldLetter: oldCell.letter,
            );
          }
        }
      }
    }

    for (final clue in current.puzzle.clues) {
      if (!_isWordComplete(previous, clue) && _isWordComplete(current, clue)) {
        for (final cell in ClueProgressCalculator.cellsFor(clue)) {
          effects.putIfAbsent(
            cell,
            () => const GridCellEffect(GridCellEffectType.wordComplete),
          );
        }
      }
    }

    final highlightChanged = previous.focus != current.focus;
    if (effects.isEmpty && !highlightChanged) return;

    _effectController.stop();
    _effectController.duration = highlightChanged && effects.isEmpty
        ? _highlightDuration(previous, current)
        : _effectDuration(effects.values);
    _setCellEffects(effects, previous);
    _effectController.forward(from: 0).whenComplete(() {
      if (mounted) {
        _clearCellEffects();
      }
    });
  }

  GridCellEffectType? _stateEffect(CellState oldState, CellState newState) {
    if (oldState == newState) return null;
    return switch (newState) {
      CellState.checkedCorrect => GridCellEffectType.checkCorrect,
      CellState.checkedIncorrect => GridCellEffectType.checkIncorrect,
      CellState.revealed => GridCellEffectType.reveal,
      _ => null,
    };
  }

  Duration _effectDuration(Iterable<GridCellEffect> effects) {
    var millis = 0;
    for (final effect in effects) {
      millis = switch (effect.type) {
        GridCellEffectType.backspace => millis < 60 ? 60 : millis,
        GridCellEffectType.entry => millis < 80 ? 80 : millis,
        GridCellEffectType.checkIncorrect => millis < 200 ? 200 : millis,
        GridCellEffectType.wordComplete => millis < 300 ? 300 : millis,
        GridCellEffectType.puzzleComplete => millis < 500 ? 500 : millis,
        GridCellEffectType.checkCorrect ||
        GridCellEffectType.reveal =>
          millis < 400 ? 400 : millis,
      };
    }
    return Duration(milliseconds: millis == 0 ? 80 : millis);
  }

  Duration _highlightDuration(SolveState previous, SolveState current) {
    if (previous.focus.row == current.focus.row &&
        previous.focus.col == current.focus.col &&
        previous.focus.direction != current.focus.direction) {
      return const Duration(milliseconds: 200);
    }
    return const Duration(milliseconds: 150);
  }

  bool _isTerminal(PuzzleStatus status) =>
      status == PuzzleStatus.solved ||
      status == PuzzleStatus.solvedWithHelp ||
      status == PuzzleStatus.solvedWithReveal ||
      status == PuzzleStatus.revealed;

  bool _isWordComplete(SolveState state, Clue clue) {
    for (final (r, c) in ClueProgressCalculator.cellsFor(clue)) {
      final progress = state.progress.cell(r, c);
      final solution = state.puzzle.grid.cell(r, c).solution;
      if (progress.letter.isEmpty ||
          progress.letter.toUpperCase() != solution.toUpperCase()) {
        return false;
      }
    }
    return true;
  }
}
