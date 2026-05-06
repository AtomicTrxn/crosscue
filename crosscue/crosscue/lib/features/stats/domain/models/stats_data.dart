/// Aggregated statistics derived from all solve sessions.
///
/// Computed by [StatsRepositoryImpl.getStats()] and displayed on the Stats
/// screen.  All duration values are in milliseconds.
class StatsData {
  const StatsData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSolved,
    required this.cleanSolves,
    required this.hintedCheckedSolves,
    required this.revealedCount,
    required this.completionRate,
    required this.startedCount,
    this.averageElapsedMs,
    this.sevenDayAverageMs,
    this.personalBest15x15Ms,
    this.personalBest21x21Ms,
    this.personalBestMiniMs,
    this.difficultyBreakdown = const {},
  });

  /// Number of consecutive streak-eligible days ending today (or yesterday).
  final int currentStreak;

  /// All-time longest consecutive streak.
  final int longestStreak;

  /// Count of sessions with completion_type in clean | checked | hinted.
  final int totalSolved;

  /// Count of clean completions (no checks or reveals).
  final int cleanSolves;

  /// Count of checked + hinted completions.
  final int hintedCheckedSolves;

  /// Count of full-puzzle reveals (not streak-eligible).
  final int revealedCount;

  /// (totalSolved + revealedCount) / startedCount; 0.0 if never started.
  final double completionRate;

  /// Total session rows ever created.
  final int startedCount;

  /// Mean elapsed_ms for clean | checked | hinted sessions; null if none.
  final int? averageElapsedMs;

  /// Mean elapsed_ms for streak-eligible sessions in the last 7 local days.
  final int? sevenDayAverageMs;

  /// Best (lowest) elapsed_ms for clean 15×15 solves; null if none.
  final int? personalBest15x15Ms;

  /// Best elapsed_ms for clean 21×21 solves; null if none.
  final int? personalBest21x21Ms;

  /// Best elapsed_ms for clean mini-grid (≤7×7) solves; null if none.
  final int? personalBestMiniMs;

  /// Completed sessions grouped by puzzle difficulty.
  final Map<String, int> difficultyBreakdown;

  /// Convenience: returns true when the user has solved at least one puzzle.
  bool get hasSolves => totalSolved > 0;

  static const empty = StatsData(
    currentStreak: 0,
    longestStreak: 0,
    totalSolved: 0,
    cleanSolves: 0,
    hintedCheckedSolves: 0,
    revealedCount: 0,
    completionRate: 0.0,
    startedCount: 0,
  );
}
