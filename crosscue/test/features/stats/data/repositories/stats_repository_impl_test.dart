// Tests for StatsRepositoryImpl — streak algorithm, aggregations, and PBs.
//
// The streak algorithm (_currentStreak, _longestStreak) is tested indirectly
// via getStats() with seeded imported_solve_stats rows (no puzzle FK needed).

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/stats/data/repositories/stats_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StatsRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = StatsRepositoryImpl(dao: db.statsDao);
  });
  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> seed({
    required String date,
    String completionType = 'clean',
    int elapsedMs = 60000,
    int width = 5,
    int height = 5,
    String? puzzleTitle,
  }) =>
      db.statsDao.insertImportedRecord(
        (
          completionType: completionType,
          elapsedMs: elapsedMs,
          solvedDateLocal: date,
          solvedTimezone: null,
          width: width,
          height: height,
          puzzleTitle: puzzleTitle ?? 'Puzzle $date',
        ),
      );

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  group('getStats – empty DB', () {
    test('returns all zeros when no sessions exist', () async {
      final stats = await repo.getStats();
      expect(stats.currentStreak, equals(0));
      expect(stats.longestStreak, equals(0));
      expect(stats.totalSolved, equals(0));
      expect(stats.cleanSolves, equals(0));
      expect(stats.startedCount, equals(0));
      expect(stats.completionRate, equals(0.0));
      expect(stats.averageElapsedMs, isNull);
      expect(stats.personalBest15x15Ms, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Completion type counts
  // ---------------------------------------------------------------------------

  group('completionType counts', () {
    test('counts clean, checked, hinted, revealed separately', () async {
      await seed(date: '2025-01-01', completionType: 'clean');
      await seed(date: '2025-01-02', completionType: 'clean');
      await seed(date: '2025-01-03', completionType: 'checked');
      await seed(date: '2025-01-04', completionType: 'hinted');
      await seed(date: '2025-01-05', completionType: 'revealed');

      final stats = await repo.getStats();
      expect(stats.cleanSolves, equals(2));
      expect(stats.hintedCheckedSolves, equals(2)); // checked + hinted
      expect(stats.revealedCount, equals(1));
      expect(stats.totalSolved, equals(4)); // clean + checked + hinted
    });

    test('startedCount includes all sessions', () async {
      await seed(date: '2025-01-01', completionType: 'clean');
      await seed(date: '2025-01-02', completionType: 'revealed');

      final stats = await repo.getStats();
      expect(stats.startedCount, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // Average elapsed
  // ---------------------------------------------------------------------------

  group('averageElapsedMs', () {
    test('null when no solved sessions', () async {
      final stats = await repo.getStats();
      expect(stats.averageElapsedMs, isNull);
    });

    test('computes mean for clean/checked/hinted (excludes revealed)',
        () async {
      await seed(date: '2025-01-01', completionType: 'clean', elapsedMs: 60000);
      await seed(
        date: '2025-01-02',
        completionType: 'checked',
        elapsedMs: 90000,
      );
      await seed(
        date: '2025-01-03',
        completionType: 'revealed',
        elapsedMs: 30000,
      );

      final stats = await repo.getStats();
      // avg of [60000, 90000] = 75000; revealed excluded
      expect(stats.averageElapsedMs, equals(75000));
    });
  });

  // ---------------------------------------------------------------------------
  // Completion rate
  // ---------------------------------------------------------------------------

  group('completionRate', () {
    test('0.0 when no sessions', () async {
      final stats = await repo.getStats();
      expect(stats.completionRate, equals(0.0));
    });

    test('1.0 when all sessions are completed', () async {
      await seed(date: '2025-01-01', completionType: 'clean');
      await seed(date: '2025-01-02', completionType: 'clean');

      final stats = await repo.getStats();
      expect(stats.completionRate, equals(1.0));
    });
  });

  // ---------------------------------------------------------------------------
  // Streak algorithm
  // ---------------------------------------------------------------------------

  group('currentStreak', () {
    test('0 when no solves', () async {
      final stats = await repo.getStats();
      expect(stats.currentStreak, equals(0));
    });

    test('counts consecutive days including today', () async {
      final today = DateTime.now();
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await seed(date: fmt(today));
      await seed(
        date: fmt(today.subtract(const Duration(days: 1))),
        puzzleTitle: 'yesterday',
      );
      await seed(
        date: fmt(today.subtract(const Duration(days: 2))),
        puzzleTitle: '2 days ago',
      );

      final stats = await repo.getStats();
      expect(stats.currentStreak, equals(3));
    });

    test('streak breaks on gap', () async {
      final today = DateTime.now();
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await seed(date: fmt(today));
      // Gap: skip yesterday
      await seed(
        date: fmt(today.subtract(const Duration(days: 2))),
        puzzleTitle: '2 days ago',
      );

      final stats = await repo.getStats();
      expect(stats.currentStreak, equals(1));
    });

    test('streak of 1 when only yesterday solved', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      await seed(date: fmt(yesterday));

      final stats = await repo.getStats();
      expect(stats.currentStreak, equals(1));
    });

    test('revealed solves do not count for streak', () async {
      final today = DateTime.now();
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      // Only revealed today — should not contribute to streak
      await seed(
        date: fmt(today),
        completionType: 'revealed',
        puzzleTitle: 'rev',
      );

      final stats = await repo.getStats();
      expect(stats.currentStreak, equals(0));
    });
  });

  group('longestStreak', () {
    test('0 when no solves', () async {
      final stats = await repo.getStats();
      expect(stats.longestStreak, equals(0));
    });

    test('finds longest run across multiple streaks', () async {
      // Streak 1: Jan 1–3 (length 3)
      await seed(date: '2025-01-01', puzzleTitle: 'a1');
      await seed(date: '2025-01-02', puzzleTitle: 'a2');
      await seed(date: '2025-01-03', puzzleTitle: 'a3');
      // Gap
      // Streak 2: Jan 10–12 (length 3)
      await seed(date: '2025-01-10', puzzleTitle: 'b1');
      await seed(date: '2025-01-11', puzzleTitle: 'b2');
      await seed(date: '2025-01-12', puzzleTitle: 'b3');
      // Streak 3: Feb 1–5 (length 5)
      for (var i = 1; i <= 5; i++) {
        await seed(
          date: '2025-02-${i.toString().padLeft(2, '0')}',
          puzzleTitle: 'c$i',
        );
      }

      final stats = await repo.getStats();
      expect(stats.longestStreak, equals(5));
    });

    test('duplicate dates count once in streak', () async {
      // Same date twice — should only count as 1 day
      await seed(date: '2025-03-01', puzzleTitle: 'p1');
      await seed(date: '2025-03-01', puzzleTitle: 'p1-dup');
      await seed(date: '2025-03-02', puzzleTitle: 'p2');

      final stats = await repo.getStats();
      expect(stats.longestStreak, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // Personal bests
  // ---------------------------------------------------------------------------

  group('personalBests', () {
    test('personal best for mini (≤7×7) from clean solve', () async {
      await seed(
        date: '2025-01-01',
        completionType: 'clean',
        elapsedMs: 45000,
        width: 5,
        height: 5,
      );
      await seed(
        date: '2025-01-02',
        completionType: 'clean',
        elapsedMs: 30000,
        width: 5,
        height: 5,
        puzzleTitle: 'faster',
      );

      final stats = await repo.getStats();
      expect(stats.personalBestMiniMs, equals(30000));
    });

    test('personal best for 15×15 from clean solve', () async {
      await seed(
        date: '2025-01-01',
        completionType: 'clean',
        elapsedMs: 600000,
        width: 15,
        height: 15,
      );

      final stats = await repo.getStats();
      expect(stats.personalBest15x15Ms, equals(600000));
    });

    test('non-clean solve does not count as personal best', () async {
      await seed(
        date: '2025-01-01',
        completionType: 'checked',
        elapsedMs: 10000,
        width: 15,
        height: 15,
      );

      final stats = await repo.getStats();
      expect(stats.personalBest15x15Ms, isNull);
    });

    test('PBs are null when no matching solves', () async {
      final stats = await repo.getStats();
      expect(stats.personalBestMiniMs, isNull);
      expect(stats.personalBest15x15Ms, isNull);
      expect(stats.personalBest21x21Ms, isNull);
    });
  });
}
