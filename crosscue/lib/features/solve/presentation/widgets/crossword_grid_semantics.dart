import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';

/// Builds the screen-reader label for a single grid cell.
///
/// Kept as a pure top-level function (no widget/Riverpod dependencies) so the
/// per-cell semantics emitted by [CrosswordGridPainter.semanticsBuilder] can be
/// unit-tested directly. See issue #179.
///
/// Format (per product decision): **position + letter + state**, e.g.
///   - `Row 3, Column 2, empty`
///   - `Row 3, Column 2, letter A, correct`
///   - `Row 3, Column 2, selected, letter EST, revealed`
/// Black (blocked) cells read simply `Blocked` — they are not fillable and the
/// clue number is intentionally omitted (the active clue is announced by the
/// clue panel).
String cellSemanticLabel({
  required SolutionCell solution,
  required CellProgress progress,
  required int row,
  required int col,
  bool focused = false,
}) {
  if (solution.isBlack) return 'Blocked';

  final parts = <String>['Row ${row + 1}, Column ${col + 1}'];
  if (focused) parts.add('selected');

  if (progress.letter.isEmpty) {
    parts.add('empty');
  } else {
    parts.add('letter ${progress.letter}');
  }

  final stateWord = switch (progress.state) {
    CellState.checkedCorrect => 'correct',
    CellState.checkedIncorrect => 'incorrect',
    CellState.revealed => 'revealed',
    CellState.empty || CellState.filled => null,
  };
  if (stateWord != null) parts.add(stateWord);

  return parts.join(', ');
}
