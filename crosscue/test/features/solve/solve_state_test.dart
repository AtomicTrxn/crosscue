// Tests for SolveState's painter-hot memoized derivations (#120):
// `completedCells` and the active-word highlight set. These replaced the
// per-cell per-repaint clue walks the grid painter used to run.

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 2×1 puzzle: one across word of length 2 at (0,0).
/// [rebusFirst] makes cell (0,0) a rebus answer ("JACK") so we can verify
/// first-letter acceptance still completes the word.
Puzzle _twoCellAcross({bool rebusFirst = false}) {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'test',
      sourceId: 'test',
      title: 'T',
      author: 'A',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 2,
      height: 1,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 2,
      height: 1,
      cells: [
        SolutionCell(solution: rebusFirst ? 'JACK' : 'A', number: 1),
        const SolutionCell(solution: 'B', number: 2),
      ],
    ),
    clues: const [
      Clue(
        number: 1,
        direction: Direction.across,
        text: 'across',
        startRow: 0,
        startCol: 0,
        length: 2,
      ),
    ],
  );
}

SolveState _state(
  Puzzle puzzle,
  Grid<CellProgress> progress, {
  FocusPosition focus =
      const FocusPosition(row: 0, col: 0, direction: Direction.across),
}) {
  return SolveState(
    puzzle: puzzle,
    progress: progress,
    focus: focus,
    status: PuzzleStatus.inProgress,
    elapsedSeconds: 0,
  );
}

Grid<CellProgress> _progress(List<String> letters) {
  return Grid<CellProgress>(
    width: letters.length,
    height: 1,
    cells: [
      for (final l in letters)
        l.isEmpty
            ? CellProgress.blank
            : CellProgress(letter: l, state: CellState.filled),
    ],
  );
}

void main() {
  group('completedCells', () {
    test('includes every cell of a fully-correct word', () {
      final state = _state(_twoCellAcross(), _progress(['A', 'B']));
      expect(state.completedCells, {(0, 0), (0, 1)});
    });

    test('is empty when the word is only partially filled', () {
      final state = _state(_twoCellAcross(), _progress(['A', '']));
      expect(state.completedCells, isEmpty);
    });

    test('is empty when a letter is wrong', () {
      final state = _state(_twoCellAcross(), _progress(['A', 'Z']));
      expect(state.completedCells, isEmpty);
    });

    test('accepts the first letter of a rebus answer (matches solve rule)', () {
      // Cell (0,0) solution is "JACK"; typing just "J" must still complete
      // the word, lighting up both cells — the same forgiving rule the
      // notifier uses for completion.
      final state =
          _state(_twoCellAcross(rebusFirst: true), _progress(['J', 'B']));
      expect(state.completedCells, {(0, 0), (0, 1)});
    });
  });

  group('isWordHighlighted', () {
    test('covers exactly the active word, not the rest of the grid', () {
      final state = _state(_twoCellAcross(), _progress(['', '']));
      expect(state.isWordHighlighted(0, 0), isTrue);
      expect(state.isWordHighlighted(0, 1), isTrue);
    });

    test('memoized activeWordCells matches the active clue', () {
      final state = _state(_twoCellAcross(), _progress(['', '']));
      expect(state.activeWordCells, [(0, 0), (0, 1)]);
      expect(state.activeClue?.number, 1);
    });
  });
}
