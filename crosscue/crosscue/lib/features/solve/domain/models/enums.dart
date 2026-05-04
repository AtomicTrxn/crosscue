// Core enums for the puzzle domain.
// These are declared here (solve feature) because the solve feature is the
// central domain for the app. Other features import from this file.

/// Clue direction.
enum Direction { across, down }

/// Per-cell visual/semantic state driven by user check/reveal actions.
/// State is only changed by explicit user actions, never during normal entry.
enum CellState {
  empty,
  filled,
  checkedCorrect,
  checkedIncorrect,
  revealed,
}

/// High-level puzzle completion status used by PuzzleState and persisted
/// via TypeConverter to solve_sessions.status.
///
/// DB string mapping (TypeConverter):
///   unsolved       → "not_started"
///   inProgress     → "in_progress"
///   solved         → "completed"   (completion_type = "clean" or "checked")
///   solvedWithHelp → "completed"   (completion_type = "hinted")
///   revealed       → "revealed"
///
/// solvedWithHelp is the combined "any assistance" bucket — covers checked
/// and hinted completions. The completion_type column in Drift carries the
/// finer distinction (clean / checked / hinted / revealed).
enum PuzzleStatus { unsolved, inProgress, solved, solvedWithHelp, revealed }

/// Entry mode for the current cell. Pencil mode is deferred post-MVP but
/// included here to avoid a future breaking change.
enum EntryMode { normal, pencil, rebus }

/// Puzzle file formats used in Puzzle.sourceFormat and PuzzleParser dispatch.
enum PuzzleFormat { puz, ipuz, jpz }

/// Source type used in PuzzleSource.type.
enum SourceType { free, subscription, local }

/// License status for puzzle sources. Enforced by SourceRegistry.register().
enum LicenseStatus {
  userImport,
  explicitPermission,
  openLicense,
  needsReview,
  prohibited,
}

/// Completion type stored in solve_sessions.completion_type.
/// Provides finer-grained distinction within completed sessions.
enum CompletionType { clean, checked, hinted, revealed }
