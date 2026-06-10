import 'package:crosscue/features/challenge_boards/presentation/widgets/lifetime_card.dart';
import 'package:crosscue/features/challenge_boards/sample/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('info icon opens the lifetime explainer sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LifetimeCard(stats: SampleData.lifetime)),
      ),
    );

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Lifetime stats'), findsOneWidget);
    expect(
      find.textContaining('Solve 5 clean puzzles'),
      findsOneWidget,
    );
  });
}
