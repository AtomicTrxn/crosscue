import 'package:intl/intl.dart';

import '../../domain/models/stats_data.dart';
import '../../domain/repositories/stats_repository.dart';
import '../daos/stats_dao.dart';

/// Fetches raw session data from [StatsDao] and computes all aggregated stats
/// (streaks, averages, personal bests) in pure Dart.
class StatsRepositoryImpl implements StatsRepository {
  const StatsRepositoryImpl({required this.dao});

  final StatsDao dao;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<StatsData> getStats() async {
    final completedRows = await dao.getCompletedSessionsWithPuzzle();
    final streakDatesList = await dao.getStreakDates();
    final totalStarted = await dao.countAllSessions();

    // ── Streak ──────────────────────────────────────────────────────────────
    final dates = streakDatesList.whereType<String>().toList();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentStreak = _currentStreak(dates, today);
    final longestStreak = _longestStreak(dates);

    // ── Completion type counts & elapsed accumulation ────────────────────────
    var clean = 0;
    var checked = 0;
    var hinted = 0;
    var revealed = 0;
    final difficultyBreakdown = <String, int>{};

    final allSolvedElapsed = <int>[];
    final sevenDayElapsed = <int>[];
    int? pb15x15, pb21x21, pbMini;

    final sevenDaysAgo = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 7)));

    for (final row in completedRows) {
      final ct = row.completionType;
      final difficulty = _normalizeDifficulty(row.difficulty);
      if (difficulty != null) {
        difficultyBreakdown[difficulty] =
            (difficultyBreakdown[difficulty] ?? 0) + 1;
      }

      switch (ct) {
        case 'clean':
          clean++;
        case 'checked':
          checked++;
        case 'hinted':
          hinted++;
        case 'revealed':
          revealed++;
      }

      if (ct == 'clean' || ct == 'checked' || ct == 'hinted') {
        allSolvedElapsed.add(row.elapsedMs);

        final dl = row.solvedDateLocal;
        if (dl != null && dl.compareTo(sevenDaysAgo) >= 0) {
          sevenDayElapsed.add(row.elapsedMs);
        }

        // Personal best — clean solves only
        if (ct == 'clean') {
          if (row.width == 15 && row.height == 15) {
            if (pb15x15 == null || row.elapsedMs < pb15x15) {
              pb15x15 = row.elapsedMs;
            }
          } else if (row.width == 21 && row.height == 21) {
            if (pb21x21 == null || row.elapsedMs < pb21x21) {
              pb21x21 = row.elapsedMs;
            }
          } else if (row.width <= 7 && row.height <= 7) {
            if (pbMini == null || row.elapsedMs < pbMini) {
              pbMini = row.elapsedMs;
            }
          }
        }
      }
    }

    final totalSolved = clean + checked + hinted;

    final avg = allSolvedElapsed.isEmpty
        ? null
        : (allSolvedElapsed.reduce((a, b) => a + b) / allSolvedElapsed.length)
            .round();

    final sevenDayAvg = sevenDayElapsed.isEmpty
        ? null
        : (sevenDayElapsed.reduce((a, b) => a + b) / sevenDayElapsed.length)
            .round();

    final completionRate =
        totalStarted == 0 ? 0.0 : (totalSolved + revealed) / totalStarted;

    return StatsData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalSolved: totalSolved,
      cleanSolves: clean,
      hintedCheckedSolves: checked + hinted,
      revealedCount: revealed,
      completionRate: completionRate,
      startedCount: totalStarted,
      averageElapsedMs: avg,
      sevenDayAverageMs: sevenDayAvg,
      personalBest15x15Ms: pb15x15,
      personalBest21x21Ms: pb21x21,
      personalBestMiniMs: pbMini,
      difficultyBreakdown: difficultyBreakdown,
    );
  }

  // ---------------------------------------------------------------------------
  // Streak algorithm (topic-15)
  // ---------------------------------------------------------------------------

  /// Current streak: consecutive solved days ending today or yesterday.
  ///
  /// Allowing yesterday means a user who hasn't solved yet today still sees
  /// their streak intact rather than a premature reset.
  static int _currentStreak(List<String> dates, String today) {
    final dateSet = dates.toSet();
    final yesterday = _minusDays(today, 1);

    final String? start;
    if (dateSet.contains(today)) {
      start = today;
    } else if (dateSet.contains(yesterday)) {
      start = yesterday;
    } else {
      return 0;
    }

    var count = 0;
    var cursor = start;
    while (dateSet.contains(cursor)) {
      count++;
      cursor = _minusDays(cursor, 1);
    }
    return count;
  }

  /// Longest streak: maximum consecutive run across all solved dates.
  static int _longestStreak(List<String> dates) {
    if (dates.isEmpty) return 0;
    final sorted = dates.toSet().toList()..sort();

    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final diff = DateTime.parse(sorted[i])
          .difference(DateTime.parse(sorted[i - 1]))
          .inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static String _minusDays(String dateStr, int days) => DateFormat('yyyy-MM-dd')
      .format(DateTime.parse(dateStr).subtract(Duration(days: days)));

  static String? _normalizeDifficulty(String? difficulty) {
    final value = difficulty?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    if (value.contains('easy')) return 'easy';
    if (value.contains('medium')) return 'medium';
    if (value.contains('hard')) return 'hard';
    if (value.contains('themeless')) return 'themeless';
    return 'themeless';
  }
}
