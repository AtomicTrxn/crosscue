// Crosscue end-to-end smoke test.
//
// Boots the real app on a connected simulator or device and verifies it
// reaches a stable first frame without throwing. Intentionally minimal —
// PRs tracked under https://github.com/AtomicTrxn/crosscue/issues/106 will
// add deeper coverage (solve flow, rebus, persistence, theme).
//
// Run on iOS:
//   cd crosscue
//   flutter test integration_test/app_launch_test.dart -d <ios-sim-udid>
//
// Run on Android:
//   flutter test integration_test/app_launch_test.dart -d <android-emulator-id>
//
// See docs/qa/ios-release-checklist.md for the broader QA process this
// suite gradually subsumes.

import 'package:crosscue/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App launch smoke test', () {
    testWidgets(
      'Crosscue reaches a stable first frame without throwing',
      (tester) async {
        // Spin up the real app — this is what runs on a user's device.
        // `app.main()` is async now: it loads BootSettings off the real DB
        // before runApp. Awaiting here keeps the analyzer's unawaited_futures
        // lint happy and ensures the boot-snapshot is resolved before we pump.
        await app.main();

        // Don't use pumpAndSettle: Crosscue's home screen has Riverpod
        // listeners (stats/streak provider, optional solve timer) that
        // keep the widget tree from ever going idle. pumpAndSettle would
        // wait the full 10-minute default timeout and then fail.
        //
        // Instead, pump a fixed budget (~5 seconds real time, in 200 ms
        // slices) which is enough for Drift schema check, route resolution,
        // and the first paint of the home or onboarding screen.
        for (var i = 0; i < 25; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }

        // The app wired up far enough to render a MaterialApp. If startup
        // crashed before this point, the Flutter test binding would have
        // already surfaced the exception.
        expect(find.byType(MaterialApp), findsOneWidget);

        // No Flutter-framework red-screen artifacts visible. These strings
        // come from ErrorWidget.builder when an assertion or build failure
        // bubbles into the widget tree — same surface we hit during the
        // rebus dialog regression (#105).
        expect(find.textContaining('Failed assertion'), findsNothing);
        expect(find.textContaining('RenderFlex overflowed'), findsNothing);
      },
    );
  });
}
