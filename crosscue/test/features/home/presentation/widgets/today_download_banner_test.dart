// Widget tests for TodayDownloadBanner (#116 Phase 1). Confirms the three
// phases render visibly distinct states: a spinner + "fetching" copy while in
// progress, an error row + Retry while failed, and nothing at all when idle.

import 'package:crosscue/features/home/presentation/widgets/today_download_banner.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  CrosshareAutoDownloadPhase phase,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: TodayDownloadBanner(phase: phase)),
      ),
    ),
  );
  // The inProgress phase renders an infinitely-animating
  // CircularProgressIndicator. Tear the tree down explicitly so its ticker is
  // disposed inside the test body rather than at the test boundary, where a
  // leaked animation can surface as an unexpected exception misattributed to
  // the next test (the source of an intermittent full-suite flake).
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
}

void main() {
  testWidgets('idle renders nothing', (tester) async {
    await _pump(tester, CrosshareAutoDownloadPhase.idle);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('puzzle'), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('inProgress shows a spinner and fetching copy, no Retry',
      (tester) async {
    await _pump(tester, CrosshareAutoDownloadPhase.inProgress);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Fetching today's puzzle…"), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('failed shows the error copy with a Retry button, no spinner',
      (tester) async {
    await _pump(tester, CrosshareAutoDownloadPhase.failed);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("Couldn't fetch today's puzzle"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
