import 'package:crosscue/features/stats/domain/models/stats_data.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:crosscue/features/stats/presentation/screens/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpStats(
    WidgetTester tester,
    Future<StatsData> Function() load,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [statsDataProvider.overrideWith((ref) => load())],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state before any session exists',
      (tester) async {
    await pumpStats(tester, () async => StatsData.empty);

    expect(find.text('No stats yet'), findsOneWidget);
    expect(find.text('STREAK'), findsNothing);
  });

  testWidgets('renders streaks, times, and solve counts', (tester) async {
    const stats = StatsData(
      currentStreak: 3,
      longestStreak: 7,
      totalSolved: 12,
      cleanSolves: 9,
      hintedCheckedSolves: 3,
      revealedCount: 1,
      completionRate: 0.8,
      startedCount: 15,
      averageElapsedMs: 90000,
      sevenDayAverageMs: 75000,
    );

    await pumpStats(tester, () async => stats);

    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('3'), findsWidgets); // current streak
    expect(find.text('7'), findsWidgets); // longest streak
    expect(find.text('TIMES'), findsOneWidget);
    expect(find.text('1:30'), findsWidgets); // average of 90000 ms
    expect(find.text('SOLVES'), findsOneWidget);
    expect(find.text('No stats yet'), findsNothing);
  });

  testWidgets('surfaces load failures instead of hanging', (tester) async {
    await pumpStats(
      tester,
      () => Future<StatsData>.error(StateError('boom')),
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });
}
