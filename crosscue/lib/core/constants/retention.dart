/// Retention tuning knobs.
///
/// Exposed as plain constants for now. When/if a settings UI for advanced
/// users is added, these can be promoted to user-configurable preferences
/// stored in [AppSettingsTable].
class CrosscueRetention {
  CrosscueRetention._();

  /// Max number of [puzzle_completions] rows retained per puzzle. Pruning
  /// always preserves:
  ///   * the earliest completion (first solve — streak truth),
  ///   * the fastest completion (best time — leaderboard truth),
  ///   * the most recent N completions for context.
  ///
  /// Anything outside that set is deleted on insert.
  static const int completionsPerPuzzle = 15;
}
