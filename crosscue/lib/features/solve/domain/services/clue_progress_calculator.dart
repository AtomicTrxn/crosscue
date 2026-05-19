import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';

/// Pure helpers for deriving clue-level solve progress from cell progress.
class ClueProgressCalculator {
  const ClueProgressCalculator._();

  static List<(int row, int col)> cellsFor(Clue clue) => [
        for (var i = 0; i < clue.length; i++)
          clue.direction == Direction.across
              ? (clue.startRow, clue.startCol + i)
              : (clue.startRow + i, clue.startCol),
      ];

  static bool isClueCorrect({
    required Puzzle puzzle,
    required Grid<CellProgress> progress,
    required Clue clue,
  }) {
    for (final (row, col) in cellsFor(clue)) {
      final cellProgress = progress.cell(row, col);
      final solutionCell = puzzle.grid.cell(row, col);
      // Acceptance (incl. first-letter on rebus, bidirectional rebus) is
      // centralized on SolutionCell — see SolutionCellAccepts.
      if (!solutionCell.accepts(cellProgress.letter)) {
        return false;
      }
    }
    return true;
  }

  static bool isClueLockedCorrect({
    required Puzzle puzzle,
    required Grid<CellProgress> progress,
    required Clue clue,
  }) {
    for (final (row, col) in cellsFor(clue)) {
      final cellProgress = progress.cell(row, col);
      final solutionCell = puzzle.grid.cell(row, col);
      final isLocked = cellProgress.state == CellState.checkedCorrect ||
          cellProgress.state == CellState.revealed;
      if (!isLocked || !solutionCell.accepts(cellProgress.letter)) {
        return false;
      }
    }
    return true;
  }

  static double lockedClueCompletionFraction({
    required Puzzle puzzle,
    required Grid<CellProgress> progress,
  }) {
    final clues = puzzle.clues;
    if (clues.isEmpty) return 0;

    final lockedCorrect = clues.where(
      (clue) => isClueLockedCorrect(
        puzzle: puzzle,
        progress: progress,
        clue: clue,
      ),
    );
    return (lockedCorrect.length / clues.length).clamp(0.0, 1.0);
  }

  static double filledCellCompletionFraction({
    required Puzzle puzzle,
    required Grid<CellProgress> progress,
  }) {
    var fillable = 0;
    var filled = 0;

    for (var row = 0; row < puzzle.height; row++) {
      for (var col = 0; col < puzzle.width; col++) {
        if (puzzle.grid.cell(row, col).isBlack) continue;
        fillable++;
        if (progress.cell(row, col).letter.isNotEmpty) filled++;
      }
    }

    if (fillable == 0) return 0;
    return (filled / fillable).clamp(0.0, 1.0);
  }
}
