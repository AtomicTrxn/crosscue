import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/solve/presentation/widgets/clue_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screen-reader tests for the clue bar (issue #179): the active clue is a
/// live region so the screen reader announces it as the focused word changes,
/// and the inactive (crossing) clue is a labeled button.
void main() {
  const across = Clue(
    number: 14,
    direction: Direction.across,
    text: 'Capital of France',
    startRow: 0,
    startCol: 0,
    length: 5,
  );
  const down = Clue(
    number: 3,
    direction: Direction.down,
    text: 'Feline pet',
    startRow: 0,
    startCol: 0,
    length: 3,
  );

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 240, child: child),
        ),
      );

  testWidgets('active clue is a live region with a spoken label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        CluePanel(
          activeClue: across,
          crossClue: down,
          onSelectClue: (_) {},
          onPrev: () {},
          onNext: () {},
        ),
      ),
    );

    expect(
      tester.getSemantics(
        find.bySemanticsLabel('14 Across, Capital of France'),
      ),
      isSemantics(
        label: '14 Across, Capital of France',
        isLiveRegion: true,
      ),
    );

    handle.dispose();
  });

  testWidgets('inactive crossing clue is a labeled button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        CluePanel(
          activeClue: across,
          crossClue: down,
          onSelectClue: (_) {},
          onPrev: () {},
          onNext: () {},
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Switch to 3 Down, Feline pet'),
      findsOneWidget,
    );

    handle.dispose();
  });
}
