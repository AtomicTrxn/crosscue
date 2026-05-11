import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClueProgressCalculator', () {
    test('typed correct but unlocked clue does not count as locked complete',
        () {
      final puzzle = _puzzle();
      final progress = _progress({
        (0, 0): const CellProgress(letter: 'A', state: CellState.filled),
        (0, 1): const CellProgress(letter: 'B', state: CellState.filled),
      });

      expect(
        ClueProgressCalculator.isClueCorrect(
          puzzle: puzzle,
          progress: progress,
          clue: puzzle.clueFor(1, 'across')!,
        ),
        isTrue,
      );
      expect(
        ClueProgressCalculator.isClueLockedCorrect(
          puzzle: puzzle,
          progress: progress,
          clue: puzzle.clueFor(1, 'across')!,
        ),
        isFalse,
      );
      expect(
        ClueProgressCalculator.lockedClueCompletionFraction(
          puzzle: puzzle,
          progress: progress,
        ),
        0,
      );
    });

    test('checkedCorrect and revealed cells count toward locked clues', () {
      final puzzle = _puzzle();
      final progress = _progress({
        (0, 0):
            const CellProgress(letter: 'A', state: CellState.checkedCorrect),
        (0, 1): const CellProgress(letter: 'B', state: CellState.revealed),
      });

      expect(
        ClueProgressCalculator.isClueLockedCorrect(
          puzzle: puzzle,
          progress: progress,
          clue: puzzle.clueFor(1, 'across')!,
        ),
        isTrue,
      );
      expect(
        ClueProgressCalculator.lockedClueCompletionFraction(
          puzzle: puzzle,
          progress: progress,
        ),
        2 / 3,
      );
    });

    test('checkedIncorrect cell prevents locked completion', () {
      final puzzle = _puzzle();
      final progress = _progress({
        (0, 0):
            const CellProgress(letter: 'A', state: CellState.checkedCorrect),
        (0, 1):
            const CellProgress(letter: 'B', state: CellState.checkedIncorrect),
      });

      expect(
        ClueProgressCalculator.isClueLockedCorrect(
          puzzle: puzzle,
          progress: progress,
          clue: puzzle.clueFor(1, 'across')!,
        ),
        isFalse,
      );
    });
  });
}

Puzzle _puzzle() {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'test:puzzle',
      sourceId: 'test',
      title: 'Test',
      author: 'Tester',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 2,
      height: 2,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 2,
      height: 2,
      cells: const [
        SolutionCell(solution: 'A', number: 1),
        SolutionCell(solution: 'B', number: 2),
        SolutionCell(solution: 'C', number: 3),
        SolutionCell.black,
      ],
    ),
    clues: const [
      Clue(
        number: 1,
        direction: Direction.across,
        text: 'Across',
        startRow: 0,
        startCol: 0,
        length: 2,
      ),
      Clue(
        number: 1,
        direction: Direction.down,
        text: 'A down',
        startRow: 0,
        startCol: 0,
        length: 2,
      ),
      Clue(
        number: 2,
        direction: Direction.down,
        text: 'B down',
        startRow: 0,
        startCol: 1,
        length: 1,
      ),
    ],
  );
}

Grid<CellProgress> _progress(Map<(int, int), CellProgress> cells) {
  return Grid<CellProgress>.generate(
    2,
    2,
    (row, col) => cells[(row, col)] ?? CellProgress.blank,
  );
}
