import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/core/theme/crossword_theme.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid_painter.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid_semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the pure per-cell screen-reader label builder (issue #179).
/// Keeping the label logic in a top-level function lets us assert the exact
/// spoken text without pumping a widget or standing up Riverpod.
void main() {
  String label(
    SolutionCell solution,
    CellProgress progress, {
    int row = 2,
    int col = 1,
    bool focused = false,
  }) =>
      cellSemanticLabel(
        solution: solution,
        progress: progress,
        row: row,
        col: col,
        focused: focused,
      );

  test('black cell reads "Blocked"', () {
    expect(label(SolutionCell.black, CellProgress.blank), 'Blocked');
  });

  test('empty white cell reads position + empty (1-based)', () {
    expect(
      label(const SolutionCell(solution: 'A'), CellProgress.blank),
      'Row 3, Column 2, empty',
    );
  });

  test('filled cell reads the entered letter, no state suffix', () {
    expect(
      label(
        const SolutionCell(solution: 'A'),
        const CellProgress(letter: 'A', state: CellState.filled),
      ),
      'Row 3, Column 2, letter A',
    );
  });

  test('checked-correct cell appends "correct"', () {
    expect(
      label(
        const SolutionCell(solution: 'A'),
        const CellProgress(letter: 'A', state: CellState.checkedCorrect),
      ),
      'Row 3, Column 2, letter A, correct',
    );
  });

  test('checked-incorrect cell appends "incorrect"', () {
    expect(
      label(
        const SolutionCell(solution: 'A'),
        const CellProgress(letter: 'B', state: CellState.checkedIncorrect),
      ),
      'Row 3, Column 2, letter B, incorrect',
    );
  });

  test('revealed cell appends "revealed" and reads rebus content', () {
    expect(
      label(
        const SolutionCell(solution: 'EST'),
        const CellProgress(letter: 'EST', state: CellState.revealed),
      ),
      'Row 3, Column 2, letter EST, revealed',
    );
  });

  test('focused cell announces "selected" before the letter', () {
    expect(
      label(
        const SolutionCell(solution: 'A'),
        const CellProgress(letter: 'A', state: CellState.filled),
        focused: true,
      ),
      'Row 3, Column 2, selected, letter A',
    );
  });

  group('CrosswordGridPainter.semanticsBuilder', () {
    // A 2×1 grid: one fillable white cell at (0,0) and a black cell at (0,1).
    SolveState buildState() {
      final puzzle = Puzzle(
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
          cells: const [
            SolutionCell(solution: 'A', number: 1),
            SolutionCell.black,
          ],
        ),
        clues: const [
          Clue(
            number: 1,
            direction: Direction.across,
            text: 'across',
            startRow: 0,
            startCol: 0,
            length: 1,
          ),
        ],
      );
      return SolveState(
        puzzle: puzzle,
        progress: Grid<CellProgress>(
          width: 2,
          height: 1,
          cells: const [CellProgress.blank, CellProgress.blank],
        ),
        focus: const FocusPosition(
          row: 0,
          col: 0,
          direction: Direction.across,
        ),
        status: PuzzleStatus.inProgress,
        elapsedSeconds: 0,
      );
    }

    CrosswordGridPainter painter({void Function(int, int)? onCellTap}) {
      final state = buildState();
      return CrosswordGridPainter(
        puzzle: state.puzzle,
        progress: state.progress,
        solveState: state,
        theme: CrosswordTheme.light(),
        colorblindMode: ColorblindMode.none,
        onCellTap: onCellTap,
      );
    }

    test('emits one semantics node per cell in reading order', () {
      final nodes = painter().semanticsBuilder(const Size(200, 100));
      expect(nodes, hasLength(2));
      expect(
        nodes[0].properties.label,
        'Row 1, Column 1, selected, empty',
      );
      expect(nodes[1].properties.label, 'Blocked');
    });

    test('white cell is a selectable button; black cell is neither', () {
      final nodes = painter().semanticsBuilder(const Size(200, 100));
      expect(nodes[0].properties.button, isTrue);
      expect(nodes[0].properties.selected, isTrue);
      expect(nodes[0].properties.onTap, isNotNull);

      expect(nodes[1].properties.button, isNull);
      expect(nodes[1].properties.onTap, isNull);
    });

    test('activating a white cell calls onCellTap with its coordinates', () {
      (int, int)? tapped;
      final nodes = painter(
        onCellTap: (r, c) => tapped = (r, c),
      ).semanticsBuilder(const Size(200, 100));
      nodes[0].properties.onTap!();
      expect(tapped, (0, 0));
    });
  });
}
