// Regression coverage for the landscape clue list (issue: keyboard/landscape
// feedback). The key correctness property under test: "filled" styling must
// come from whether every cell has a letter, NOT from whether that letter
// matches the solution — using solution-correctness would turn the list into
// a free, always-on checker that leaks answers without Check/Reveal.

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
import 'package:crosscue/features/solve/presentation/widgets/clue_list_panel.dart';
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
        body: SizedBox(height: 400, child: child),
      ),
    );

void main() {
  final puzzle = _puzzle();
  final acrossClue =
      puzzle.clues.firstWhere((c) => c.direction == Direction.across);

  testWidgets(
      'a wrong-but-fully-typed answer is still marked filled, '
      'not marked wrong', (tester) async {
    final handle = tester.ensureSemantics();
    // Both cells filled, but with the WRONG letters — this must not throw,
    // and per the fix it should render as "filled" without ever comparing
    // against the solution.
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
        ClueListPanel(
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

  testWidgets('a blank clue is not marked filled', (tester) async {
    final handle = tester.ensureSemantics();
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress);

    await tester.pumpWidget(
      _wrap(
        ClueListPanel(
          clues: state.sortedClues,
          activeClue: null,
          crossClue: null,
          solveState: state,
          onSelectClue: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('1 Across, Across clue'), findsOneWidget);
    expect(
      find.bySemanticsLabel('1 Across, Across clue, filled'),
      findsNothing,
    );

    handle.dispose();
  });

  testWidgets('tapping a row invokes onSelectClue with that clue',
      (tester) async {
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress);
    Clue? selected;

    await tester.pumpWidget(
      _wrap(
        ClueListPanel(
          clues: state.sortedClues,
          activeClue: null,
          crossClue: null,
          solveState: state,
          onSelectClue: (c) => selected = c,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Across clue'));
    await tester.pump();

    expect(selected, acrossClue);
  });

  testWidgets('the active clue is exposed as selected in semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress);

    await tester.pumpWidget(
      _wrap(
        ClueListPanel(
          clues: state.sortedClues,
          activeClue: acrossClue,
          crossClue: null,
          solveState: state,
          onSelectClue: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('1 Across, Across clue')),
      isSemantics(label: '1 Across, Across clue', isSelected: true),
    );

    handle.dispose();
  });

  testWidgets(
      'the cross clue row is tinted with the Color Guide cross-row token '
      'but not marked selected', (tester) async {
    final handle = tester.ensureSemantics();
    final downClue = puzzle.clues.firstWhere(
      (c) => c.direction == Direction.down && c.number == 1,
    );
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress);

    await tester.pumpWidget(
      _wrap(
        ClueListPanel(
          clues: state.sortedClues,
          activeClue: acrossClue,
          crossClue: downClue,
          solveState: state,
          onSelectClue: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

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
}
