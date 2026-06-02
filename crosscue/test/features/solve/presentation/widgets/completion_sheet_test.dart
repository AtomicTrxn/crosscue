// Widget test for CompletionSheet (#147): the Crosscue icon renders and the
// "Share result" action is present on a completed (non-revealed) solve.

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/widgets/completion_sheet.dart';
import 'package:crosscue/features/stats/domain/models/stats_data.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

SolveState _solvedState() {
  final puzzle = Puzzle(
    metadata: PuzzleMetadata(
      id: 'test',
      sourceId: 'test',
      title: 'Test Puzzle',
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
        SolutionCell(solution: 'B', number: 2),
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
  return SolveState(
    puzzle: puzzle,
    progress: Grid<CellProgress>(
      width: 2,
      height: 1,
      cells: const [
        CellProgress(letter: 'A', state: CellState.filled),
        CellProgress(letter: 'B', state: CellState.filled),
      ],
    ),
    focus: const FocusPosition(row: 0, col: 0, direction: Direction.across),
    status: PuzzleStatus.solved,
    elapsedSeconds: 65,
  );
}

Future<void> _pumpSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        statsDataProvider.overrideWith((ref) => StatsData.empty),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CompletionSheet(
            solveState: _solvedState(),
            onViewGrid: () {},
            onNextPuzzle: () {},
            onResetPuzzle: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the Crosscue icon', (tester) async {
    await _pumpSheet(tester);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shows the Share result action on a clean solve', (tester) async {
    await _pumpSheet(tester);
    expect(find.text('Clean solve'), findsOneWidget);
    expect(find.text('Share result'), findsOneWidget);
  });
}
