// Core enums for the puzzle domain.
// These are declared here (solve feature) because the solve feature is the
// central domain for the app. Other features import from this file.

/// Domain-layer theme preference — mirrors Flutter's ThemeMode without
/// importing Flutter in the domain layer.
///
/// Translated to/from [ThemeMode] inside [AppSettingsRepositoryImpl].
enum AppThemeMode { light, dark, system }

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

/// Accessibility overlay mode for puzzle feedback.
enum ColorblindMode { none, deuteranopia }

/// High-level puzzle completion status used by PuzzleState and persisted
/// via TypeConverter to solve_sessions.status.
///
/// DB string mapping (TypeConverter):
///   unsolved          → "not_started"
///   inProgress        → "in_progress"
///   solved            → "completed"   (completion_type = "clean")
///   solvedWithHelp    → "completed"   (completion_type = "checked")
///   solvedWithReveal  → "completed"   (completion_type = "hinted")
///   revealed          → "revealed"
///
/// solvedWithHelp  = completed using check operations only (no reveals).
/// solvedWithReveal = completed where ≥1 cell was revealed (hints used).
enum PuzzleStatus {
  unsolved,
  inProgress,
  solved,
  solvedWithHelp,
  solvedWithReveal,
  revealed,
}

/// Entry mode for the current cell. `pencil` is reserved for a future
/// pencil-mode feature and is currently unused at runtime.
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
