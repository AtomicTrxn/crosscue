/// Typed errors that can occur when loading or initialising a solve session.
sealed class SolveLoadError {
  const SolveLoadError();
}

/// The puzzle ID supplied to the solve screen does not exist in the database.
/// This can happen after a puzzle is deleted while the solve screen is queued.
class PuzzleNotFoundError extends SolveLoadError {
  const PuzzleNotFoundError(this.puzzleId);
  final String puzzleId;

  @override
  String toString() => 'Puzzle not found: $puzzleId';
}

/// A lower-level failure when opening or restoring a solve session.
class SolveSessionLoadError extends SolveLoadError {
  const SolveSessionLoadError(this.cause);
  final String cause;

  @override
  String toString() => 'Solve session load error: $cause';
}
