// Regression coverage for the landscape two-column clue list (#298 follow-up
// — revival of the app's original two-column clue panel, removed in #154).
// The key property under test: active clue and cross clue are both visible
// at once, one per column, without needing to scroll a shared list between
// Across and Down sections.

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
import 'package:crosscue/features/solve/presentation/widgets/clue_columns_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 2x1 grid: "AB", clued as 1-Across "AB", 1-Down "A", 2-Down "B".
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
      height: 1,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 2,
      height: 1,
      cells: const [
        SolutionCell(solution: 'A', number: 1),
        SolutionCell(solution: 'B', number: 2),
      ],
    ),
    clues: const [
      Clue(
        number: 1,
        direction: Direction.across,
        text: 'Across clue',
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
        length: 1,
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

SolveState _stateWith(Grid<CellProgress> progress) {
  final puzzle = _puzzle();
  return SolveState(
    puzzle: puzzle,
    progress: progress,
    focus: const FocusPosition(row: 0, col: 0, direction: Direction.across),
    status: PuzzleStatus.inProgress,
    elapsedSeconds: 0,
  );
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(height: 400, width: 800, child: child),
      ),
    );

void main() {
  final puzzle = _puzzle();
  final acrossClue =
      puzzle.clues.firstWhere((c) => c.direction == Direction.across);
  final downClue = puzzle.clues.firstWhere(
    (c) => c.direction == Direction.down && c.number == 1,
  );

  Grid<CellProgress> blankProgress() => Grid<CellProgress>(
        width: 2,
        height: 1,
        cells: const [CellProgress.blank, CellProgress.blank],
      );

  testWidgets(
      'the active clue and its cross clue are both visible at once, '
      'one per column', (tester) async {
    final handle = tester.ensureSemantics();
    final state = _stateWith(blankProgress());

    await tester.pumpWidget(
      _wrap(
        ClueColumnsPanel(
          clues: state.sortedClues,
          activeClue: acrossClue,
          crossClue: downClue,
          solveState: state,
          onSelectClue: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Both rows on screen simultaneously — the whole point of two
    // independently scrollable columns instead of one shared list.
    expect(find.text('Across clue'), findsOneWidget);
    expect(find.text('A down'), findsOneWidget);

    expect(
      tester.getSemantics(find.bySemanticsLabel('1 Across, Across clue')),
      isSemantics(label: '1 Across, Across clue', isSelected: true),
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Material &&
            w.color == CrosswordTheme.light().cluePanelCrossRowBg,
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('1 Down, A down')),
      isSemantics(label: '1 Down, A down', isSelected: false),
    );

    handle.dispose();
  });

  testWidgets('tapping a clue in either column invokes onSelectClue',
      (tester) async {
    final state = _stateWith(blankProgress());
    Clue? selected;

    await tester.pumpWidget(
      _wrap(
        ClueColumnsPanel(
          clues: state.sortedClues,
          activeClue: acrossClue,
          crossClue: downClue,
          solveState: state,
          onSelectClue: (c) => selected = c,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A down'));
    await tester.pump();

    expect(selected, downClue);
  });

  testWidgets(
      'a wrong-but-fully-typed answer is still marked filled, '
      'not marked wrong', (tester) async {
    final handle = tester.ensureSemantics();
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [
        CellProgress(letter: 'X', state: CellState.filled),
        CellProgress(letter: 'Y', state: CellState.filled),
      ],
    );
    final state = _stateWith(progress);

    await tester.pumpWidget(
      _wrap(
        ClueColumnsPanel(
          clues: state.sortedClues,
          activeClue: null,
          crossClue: null,
          solveState: state,
          onSelectClue: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('1 Across, Across clue, filled'),
      findsOneWidget,
    );

    handle.dispose();
  });

  testWidgets('the Across and Down columns are labeled', (tester) async {
    final state = _stateWith(blankProgress());

    await tester.pumpWidget(
      _wrap(
        ClueColumnsPanel(
          clues: state.sortedClues,
          activeClue: null,
          crossClue: null,
          solveState: state,
          onSelectClue: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACROSS'), findsOneWidget);
    expect(find.text('DOWN'), findsOneWidget);
  });
}
