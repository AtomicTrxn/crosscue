// Integration tests legitimately capture a BuildContext early (the live
// app's MaterialApp element) and use it after async pumps — that's the
// whole point of the "drive the running app from outside" pattern.
// ignore_for_file: use_build_context_synchronously

// Seed-and-solve integration test (PR 2 of #106).
//
// First end-to-end test that exercises the full vertical slice:
//   real Drift database
//   → real ImportRepository
//   → real Riverpod providers
//   → real router
//   → real solve screen render
//
// The launch smoke test (app_launch_test.dart) only checks the first
// frame. This goes further: seeds a known puzzle, navigates from home
// to the solve screen, and verifies the solve UI actually renders.
//
// Run from crosscue/:
//   flutter test integration_test/seed_and_solve_test.dart -d <sim-udid>
//
// Gotchas captured along the way (see the inline comments):
//   1. pumpAndSettle hangs — Crosscue's home has long-lived listeners
//      (stats, streak, solve timer). Use fixed-budget pump slices.
//   2. First-run onboarding gates the home screen. Bypass programmatically
//      via the settings provider — tapping "Skip" through the tutorial
//      keyboard widget crashes the test process on iOS.
//   3. The featured-puzzle title Text isn't tappable; the action button is.
//      Its label is "SOLVE" for an untouched puzzle, "CONTINUE SOLVING"
//      for one with progress (which happens any time prior test runs
//      touched the persistent app DB).
//   4. The app uses go_router; Navigator.of(rootCtx).pop() may not behave
//      as expected. Step 8's pop is best-effort.
//
// What's NOT covered yet (tracked in #106 as PRs 3-5):
//   - tapping specific grid cells (needs pixel math on CustomPaint or
//     new Semantics labels)
//   - typing letters via the on-screen keyboard
//   - rebus dialog, stats screen, settings screen
//   - persistence (background/foreground) and theme toggle

import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/puz_fixture_builder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pump fixed-budget frames. `pumpAndSettle` would block forever —
  /// Crosscue has long-running Riverpod listeners (stats, streak, solve
  /// timer) that never let the tree go idle. See app_launch_test.dart
  /// for the deeper explanation.
  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    const slice = Duration(milliseconds: 200);
    final ticks = (total.inMilliseconds / slice.inMilliseconds).ceil();
    for (var i = 0; i < ticks; i++) {
      await tester.pump(slice);
    }
  }

  testWidgets(
    'seed a puzzle via the real repo, open it from home, render solve screen',
    (tester) async {
      // 1. Boot the real app.
      app.main();
      await pumpFor(tester, const Duration(seconds: 5));

      // 2. Reach into the live ProviderContainer via the MaterialApp
      //    element. Standard integration-test escape hatch for talking
      //    to providers from outside the widget tree.
      final BuildContext appCtx = tester.element(find.byType(MaterialApp));
      final ProviderContainer container = ProviderScope.containerOf(appCtx);

      // 3. Seed a 3x3 puzzle through the production import path. Title
      //    is 'Test Puzzle' (see PuzFixtureBuilder.minimal3x3).
      //    Returns JobSuccess on a fresh DB, JobDuplicate when the test
      //    has already run against this sim — both count as "in DB".
      final result = await container.read(importRepositoryProvider).importBytes(
            PuzFixtureBuilder.minimal3x3(),
          );
      expect(result, isA<ImportJobResult>());

      // Give the home screen's Drift stream a chance to deliver the row.
      await pumpFor(tester, const Duration(seconds: 3));

      // 4. Bypass first-run onboarding by setting the gating flag
      //    directly. Tapping "Skip" through the tutorial's mock keyboard
      //    crashed the test process on iOS — programmatic skip is the
      //    only reliable path.
      await container.read(appSettingsProvider).setHasSeenOnboarding(true);
      container.invalidate(hasSeenOnboardingProvider);
      await pumpFor(tester, const Duration(seconds: 3));

      // 5. Home screen shows the seeded puzzle.
      expect(find.text('Test Puzzle'), findsOneWidget);

      // 6. Tap the action button on the featured puzzle. Label is 'SOLVE'
      //    if untouched, 'CONTINUE SOLVING' if there's prior progress.
      //    Match both via the leading-SOLV / CONTINUE-SOLV pattern.
      await tester.tap(
        find.textContaining(RegExp(r'^SOLVE|^CONTINUE SOLV')),
      );
      await pumpFor(tester, const Duration(seconds: 6));

      // 7. We're on the solve screen — the clue list and on-screen
      //    keyboard are visible. ACROSS/DOWN headers from clue_panel.dart
      //    are stable anchors that exist regardless of progress state.
      expect(find.text('ACROSS'), findsOneWidget);
      expect(find.text('DOWN'), findsOneWidget);
      // Clue text from PuzFixtureBuilder.minimal3x3.
      expect(find.text('1-Across'), findsWidgets);

      // 8. Best-effort: pop the solve route so its dispose() runs while
      //    the test body can still drain any exceptions. The fix for
      //    `SolveScreenState.dispose` (caching state + notifier in
      //    initState because `ref` is unsafe during deactivation) lives
      //    at solve_screen.dart:81-101 — a regression there should
      //    surface during this drain. Wrapped in try/catch because the
      //    app uses go_router and `Navigator.of(rootCtx)` semantics
      //    differ slightly from a vanilla Navigator stack; failure here
      //    is non-fatal.
      try {
        final navigator = Navigator.maybeOf(appCtx);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          await pumpFor(tester, const Duration(seconds: 2));
        }
      } catch (_) {
        // Best-effort; the meaningful assertions already passed.
      }
    },
  );
}
