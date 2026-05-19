import 'package:crosscue/features/solve/presentation/widgets/crossword_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the soft keyboard's rebus affordance.
///
/// The Rebus key is always visible (the puzzle's rebus-or-not status must
/// not leak via keyboard layout — see docs/architecture/rebus-entry.md §4.1).
/// Tapping it fires the `onRebus` callback so the screen can open the dialog.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the Rebus key on the bottom row', (tester) async {
    await tester.pumpWidget(
      wrap(
        CrosswordKeyboard(
          onLetter: (_) {},
          onBackspace: () {},
          onCheckWord: () {},
          onRebus: () {},
          onFeedbackSound: () {},
        ),
      ),
    );
    expect(find.text('Rebus'), findsOneWidget);
  });

  testWidgets('tapping Rebus fires the callback exactly once', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(
        CrosswordKeyboard(
          onLetter: (_) {},
          onBackspace: () {},
          onCheckWord: () {},
          onRebus: () => tapped++,
          onFeedbackSound: () {},
          hapticsEnabled: false,
        ),
      ),
    );

    await tester.tap(find.text('Rebus'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('Rebus key is rendered regardless of small-puzzle mode',
      (tester) async {
    // The key must not be hidden on minis — small grids are exactly where
    // a solver might land on a rebus cell unexpectedly.
    await tester.pumpWidget(
      wrap(
        CrosswordKeyboard(
          onLetter: (_) {},
          onBackspace: () {},
          onCheckWord: () {},
          onRebus: () {},
          onFeedbackSound: () {},
          isSmallPuzzle: true,
        ),
      ),
    );
    expect(find.text('Rebus'), findsOneWidget);
  });
}
