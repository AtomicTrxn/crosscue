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
Puzzle _puzzle({int acrossNumber = 1, String acrossText = 'Across clue'}) {
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
    clues: [
      Clue(
        number: acrossNumber,
        direction: Direction.across,
        text: acrossText,
        startRow: 0,
        startCol: 0,
        length: 2,
      ),
      const Clue(
        number: 1,
        direction: Direction.down,
        text: 'A down',
        startRow: 0,
        startCol: 0,
        length: 1,
      ),
      const Clue(
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

SolveState _stateWith(
  Grid<CellProgress> progress, {
  int acrossNumber = 1,
  String acrossText = 'Across clue',
}) {
  final puzzle = _puzzle(acrossNumber: acrossNumber, acrossText: acrossText);
  return SolveState(
    puzzle: puzzle,
    progress: progress,
    focus: const FocusPosition(row: 0, col: 0, direction: Direction.across),
    status: PuzzleStatus.inProgress,
    elapsedSeconds: 0,
  );
}

Widget _wrap(Widget child, {double width = 800, double height = 400}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(height: height, width: width, child: child),
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

  testWidgets(
      'a two-digit clue number renders on a single line without overflow',
      (tester) async {
    final state = _stateWith(blankProgress(), acrossNumber: 18);

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

    expect(tester.takeException(), isNull);
    expect(find.text('18'), findsOneWidget);
    final numberText = tester.widget<Text>(find.text('18'));
    expect(numberText.maxLines, 1);
  });

  testWidgets(
      'a clue that wraps to two lines does not overflow a narrow column',
      (tester) async {
    const longText =
        'A considerably long clue whose text should wrap across two '
        'lines inside a narrow column';
    final state = _stateWith(blankProgress(), acrossText: longText);

    await tester.pumpWidget(
      _wrap(
        ClueColumnsPanel(
          clues: state.sortedClues,
          activeClue: null,
          crossClue: null,
          solveState: state,
          onSelectClue: (_) {},
        ),
        // ~200px per column after the divider, like the real narrow layout.
        width: 420,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the row height grows at a larger text scale instead of staying fixed '
      '(so a 2nd wrapped line is not clipped)', (tester) async {
    final state = _stateWith(blankProgress());

    Widget buildAt(TextScaler scaler) => _wrap(
          MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: ClueColumnsPanel(
              clues: state.sortedClues,
              activeClue: null,
              crossClue: null,
              solveState: state,
              onSelectClue: (_) {},
            ),
          ),
          width: 420,
        );

    await tester.pumpWidget(buildAt(TextScaler.noScaling));
    await tester.pumpAndSettle();
    final defaultExtent =
        tester.widget<ListView>(find.byType(ListView).first).itemExtent;
    expect(defaultExtent, isNotNull);

    await tester.pumpWidget(buildAt(const TextScaler.linear(1.6)));
    await tester.pumpAndSettle();
    final scaledExtent =
        tester.widget<ListView>(find.byType(ListView).first).itemExtent;

    // A hardcoded row height (the pre-fix bug) would stay 56 regardless of
    // text scale, silently clipping a 2nd wrapped line under Row's
    // cross-axis overflow (which — unlike main-axis overflow — never throws
    // a RenderFlex error, so an exception-only assertion can't catch this).
    expect(scaledExtent, greaterThan(defaultExtent!));
  });

  testWidgets(
      'clue text needing 3+ lines is never truncated, at any text scale',
      (tester) async {
    const longText =
        'A considerably long clue whose text should wrap across two '
        'lines inside a narrow column and then some more text so that '
        'it needs a third line to fit at a larger text scale';
    final state = _stateWith(blankProgress(), acrossText: longText);

    await tester.pumpWidget(
      _wrap(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: ClueColumnsPanel(
            clues: state.sortedClues,
            activeClue: null,
            crossClue: null,
            solveState: state,
            onSelectClue: (_) {},
          ),
        ),
        // ~200px per column after the divider, like the real narrow layout.
        width: 420,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // find.text requires an exact match — if the clue got ellipsized this
    // fails, which is exactly the truncation regression this test guards.
    expect(find.text(longText), findsOneWidget);
    final clueTextWidget = tester.widget<Text>(find.text(longText));
    expect(clueTextWidget.maxLines, isNull);
  });
}
