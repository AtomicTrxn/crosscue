import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/screens/challenge_tab_screen.dart';
import 'package:crosscue/features/challenge_boards/sample/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders weekly card before lifetime card', (tester) async {
    await tester.pumpWidget(
      const _Harness(
        child: ChallengeTabScreen(
          boards: Loadable.data(SampleData.boards),
          lifetime: SampleData.lifetime,
          me: SampleData.me,
        ),
      ),
    );

    final weeklyTop = tester.getTopLeft(find.text('THIS WEEK').first).dy;
    final lifetimeTop = tester.getTopLeft(find.text('LIFETIME').first).dy;
    expect(weeklyTop, lessThan(lifetimeTop));
    expect(find.text('The Cruciverbalists'), findsOneWidget);
    expect(find.text('Top 25% in 4 of 5 boards'), findsOneWidget);
  });

  testWidgets('renders empty, loading, error, and offline states',
      (tester) async {
    await tester.pumpWidget(
      const _Harness(
        child: ChallengeTabScreen(
          boards: Loadable.data(<Board>[]),
          lifetime: SampleData.lifetime,
          me: SampleData.me,
        ),
      ),
    );
    expect(find.text('Start a challenge with friends'), findsOneWidget);

    await tester.pumpWidget(
      const _Harness(
        child: ChallengeTabScreen(
          boards: Loadable.loading(),
          lifetime: SampleData.lifetime,
          me: SampleData.me,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(
      const _Harness(
        child: ChallengeTabScreen(
          boards: Loadable.error(),
          lifetime: SampleData.lifetime,
          me: SampleData.me,
        ),
      ),
    );
    expect(find.text('Couldn’t load your boards'), findsOneWidget);

    await tester.pumpWidget(
      const _Harness(
        child: ChallengeTabScreen(
          boards: Loadable.offline(
            SampleData.boards,
            lastUpdatedLabel: '2h ago',
          ),
          lifetime: SampleData.lifetime,
          me: SampleData.me,
        ),
      ),
    );
    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.text('The Cruciverbalists'), findsOneWidget);
  });

  testWidgets('board rows invoke open-board callback', (tester) async {
    Board? opened;
    await tester.pumpWidget(
      _Harness(
        child: ChallengeTabScreen(
          boards: const Loadable.data(SampleData.boards),
          lifetime: SampleData.lifetime,
          me: SampleData.me,
          onOpenBoard: (board) => opened = board,
        ),
      ),
    );

    await tester.tap(find.text('Friday Night Crew'));
    expect(opened?.id, 'b2');
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}
