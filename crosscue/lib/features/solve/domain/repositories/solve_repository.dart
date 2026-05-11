import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';

/// Result returned when a solve session is created or resumed.
final class SessionLoadResult {
  const SessionLoadResult({
    required this.sessionId,
    required this.progress,
    required this.focus,
    required this.elapsedMs,
    required this.isPaused,
    required this.isResumed,
    this.checkCount = 0,
    this.revealCount = 0,
    this.usedCheck = false,
    this.usedReveal = false,
    this.cleanSolveEligible = true,
  });

  final int sessionId;
  final Grid<CellProgress> progress;
  final FocusPosition focus;
  final int elapsedMs;
  final bool isPaused;
  final bool isResumed;
  final int checkCount;
  final int revealCount;
  final bool usedCheck;
  final bool usedReveal;
  final bool cleanSolveEligible;
}

/// Abstract contract for the solve data layer.
abstract class SolveRepository {
  /// Finds an existing in-progress session for [puzzle.id], or creates one.
  /// Restores cell-progress from DB when resuming.
  Future<SessionLoadResult> createOrResumeSession(Puzzle puzzle);

  /// Persists incremental solve progress (called on every cell change, debounced).
  Future<void> saveProgress({
    required int sessionId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required bool isPaused,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  });

  /// Saves the final completed/revealed state of a session.
  Future<void> markComplete({
    required int sessionId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required CompletionType completionType,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  });
}
