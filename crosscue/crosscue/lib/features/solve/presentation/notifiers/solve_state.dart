import '../../domain/models/cell_progress.dart';
import '../../domain/models/clue.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/focus_position.dart';
import '../../domain/models/grid.dart';
import '../../domain/models/puzzle.dart';

/// Full state for the solve screen.
///
/// Uses a plain immutable class (not Freezed) because Grid<T> generics
/// are incompatible with Freezed's code generator.
class SolveState {
  const SolveState({
    required this.puzzle,
    required this.progress,
    required this.focus,
    required this.status,
    required this.elapsedSeconds,
    this.isPaused = false,
  });

  final Puzzle puzzle;
  final Grid<CellProgress> progress;
  final FocusPosition focus;
  final PuzzleStatus status;
  final int elapsedSeconds;
  final bool isPaused;

  // ---------------------------------------------------------------------------
  // Derived helpers
  // ---------------------------------------------------------------------------

  Clue? get activeClue {
    for (final clue in puzzle.clues) {
      if (clue.direction == focus.direction &&
          cellInClue(focus.row, focus.col, clue)) {
        return clue;
      }
    }
    return null;
  }

  Clue? get crossClue {
    final crossDir =
        focus.direction == Direction.across ? Direction.down : Direction.across;
    for (final clue in puzzle.clues) {
      if (clue.direction == crossDir &&
          cellInClue(focus.row, focus.col, clue)) {
        return clue;
      }
    }
    return null;
  }

  /// All (row, col) pairs that belong to the active word.
  List<(int, int)> get activeWordCells {
    final clue = activeClue;
    if (clue == null) return [];
    return [
      for (var i = 0; i < clue.length; i++)
        clue.direction == Direction.across
            ? (clue.startRow, clue.startCol + i)
            : (clue.startRow + i, clue.startCol),
    ];
  }

  bool isFocused(int row, int col) =>
      row == focus.row && col == focus.col;

  bool isWordHighlighted(int row, int col) {
    for (final (r, c) in activeWordCells) {
      if (r == row && c == col) return true;
    }
    return false;
  }

  bool isCrossHighlighted(int row, int col) {
    final clue = crossClue;
    if (clue == null) return false;
    return cellInClue(row, col, clue);
  }

  SolveState copyWith({
    Grid<CellProgress>? progress,
    FocusPosition? focus,
    PuzzleStatus? status,
    int? elapsedSeconds,
    bool? isPaused,
  }) {
    return SolveState(
      puzzle: puzzle,
      progress: progress ?? this.progress,
      focus: focus ?? this.focus,
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  static bool cellInClue(int row, int col, Clue clue) {
    if (clue.direction == Direction.across) {
      return row == clue.startRow &&
          col >= clue.startCol &&
          col < clue.startCol + clue.length;
    } else {
      return col == clue.startCol &&
          row >= clue.startRow &&
          row < clue.startRow + clue.length;
    }
  }
}
