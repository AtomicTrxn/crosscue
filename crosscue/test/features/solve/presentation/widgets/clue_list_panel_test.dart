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

Widget _wrap(Widget child, {double? width, double height = 400}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(height: height, width: width, child: child),
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

  testWidgets(
      'a two-digit clue number renders on a single line without overflow',
      (tester) async {
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress, acrossNumber: 18);

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
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress, acrossText: longText);

    await tester.pumpWidget(
      _wrap(
        ClueListPanel(
          clues: state.sortedClues,
          activeClue: null,
          crossClue: null,
          solveState: state,
          onSelectClue: (_) {},
        ),
        width: 200,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the row height grows at a larger text scale instead of staying fixed '
      '(so a 2nd wrapped line is not clipped)', (tester) async {
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress);

    Widget buildAt(TextScaler scaler) => _wrap(
          MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: ClueListPanel(
              clues: state.sortedClues,
              activeClue: null,
              crossClue: null,
              solveState: state,
              onSelectClue: (_) {},
            ),
          ),
          width: 200,
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
    final progress = Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [CellProgress.blank, CellProgress.blank],
    );
    final state = _stateWith(progress, acrossText: longText);

    // The 'Across' header shares this list's uniform itemExtent, so at 2x
    // text scale it grows tall too — tall enough that the ordinary test
    // surface would push the clue row (index 1, after the header) out of
    // the ListView's built/cached range before it ever mounts. A plain
    // SizedBox height doesn't help — it gets clamped back down to the
    // ambient test surface size — so grow the surface itself instead.
    tester.view.physicalSize = const Size(400, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: ClueListPanel(
            clues: state.sortedClues,
            activeClue: null,
            crossClue: null,
            solveState: state,
            onSelectClue: (_) {},
          ),
        ),
        width: 200,
        height: 6000,
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
