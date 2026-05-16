import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/services/clue_progress_calculator.dart';

/// Full state for the solve screen.
///
/// Uses a plain immutable class (not Freezed) because `Grid<T>` generics
/// are incompatible with Freezed's code generator.
class SolveState {
  SolveState({
    required this.puzzle,
    required this.progress,
    required this.focus,
    required this.status,
    required this.elapsedSeconds,
    this.isPaused = false,
    this.sessionId,
    this.checkCount = 0,
    this.revealCount = 0,
    this.usedCheck = false,
    this.usedReveal = false,
    this.cleanSolveEligible = true,
    this.previousPersonalBestMs,
  });

  final Puzzle puzzle;
  final Grid<CellProgress> progress;
  final FocusPosition focus;
  final PuzzleStatus status;
  final int elapsedSeconds;
  final bool isPaused;

  /// The Drift row id for the active solve session.
  /// Null only before the first autosave completes (should never be null in practice).
  final int? sessionId;

  // ---------------------------------------------------------------------------
  // Check / reveal counters
  // ---------------------------------------------------------------------------

  /// Number of times any check action has been triggered.
  final int checkCount;

  /// Number of times any reveal action has been triggered.
  final int revealCount;

  /// True once the user has checked at least one cell/word/grid.
  final bool usedCheck;

  /// True once the user has revealed at least one cell/word.
  final bool usedReveal;

  /// False once any reveal action is used; disqualifies clean solve and PB.
  final bool cleanSolveEligible;

  /// Previous clean personal best for this puzzle's size bucket, if one exists.
  final int? previousPersonalBestMs;

  // ---------------------------------------------------------------------------
  // Sorted clue cache
  // ---------------------------------------------------------------------------

  /// Clues sorted for Tab/Shift+arrow navigation: Across before Down for the
  /// same number. Computed once per SolveState instance because clue order is
  /// immutable — sorting on every Tab keypress was O(n log n) wasted work.
  late final List<Clue> sortedClues = _buildSortedClues();

  List<Clue> _buildSortedClues() {
    return [...puzzle.clues]..sort((a, b) {
        if (a.direction == b.direction) {
          return a.number.compareTo(b.number);
        }
        return a.direction == Direction.across ? -1 : 1;
      });
  }

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
    return ClueProgressCalculator.cellsFor(clue);
  }

  bool isFocused(int row, int col) => row == focus.row && col == focus.col;

  bool isWordHighlighted(int row, int col) {
    for (final (r, c) in activeWordCells) {
      if (r == row && c == col) return true;
    }
    return false;
  }

  SolveState copyWith({
    Grid<CellProgress>? progress,
    FocusPosition? focus,
    PuzzleStatus? status,
    int? elapsedSeconds,
    bool? isPaused,
    int? sessionId,
    int? checkCount,
    int? revealCount,
    bool? usedCheck,
    bool? usedReveal,
    bool? cleanSolveEligible,
    int? previousPersonalBestMs,
  }) {
    return SolveState(
      puzzle: puzzle,
      progress: progress ?? this.progress,
      focus: focus ?? this.focus,
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      sessionId: sessionId ?? this.sessionId,
      checkCount: checkCount ?? this.checkCount,
      revealCount: revealCount ?? this.revealCount,
      usedCheck: usedCheck ?? this.usedCheck,
      usedReveal: usedReveal ?? this.usedReveal,
      cleanSolveEligible: cleanSolveEligible ?? this.cleanSolveEligible,
      previousPersonalBestMs:
          previousPersonalBestMs ?? this.previousPersonalBestMs,
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
