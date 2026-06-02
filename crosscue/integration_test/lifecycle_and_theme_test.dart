// Integration tests legitimately capture a BuildContext early (the live
// app's MaterialApp element) and use it after async pumps — that's the
// whole point of the "drive the running app from outside" pattern.
// ignore_for_file: use_build_context_synchronously

// Lifecycle + theme integration test (PR 4 of #106).
//
// Builds on the rebus_and_navigation_test scaffolding. Covers QA-checklist
// §5 (app-lifecycle persistence — partial: fake background/resume, not a real
// force-quit) and §8 (dark-mode toggle via the Settings UI, without restart):
//   - input a letter, background -> resume the app, assert progress survived
//     and the puzzle auto-paused on background.
//   - toggle Dark from Settings, assert the theme switches live (provider +
//     resolved Brightness), and that the solve view renders dark.
//
// Run from crosscue/:
//   flutter test integration_test/lifecycle_and_theme_test.dart -d <sim-udid>
//
// Gotchas (shared with the other integration tests — see comments inline):
//   1. pumpAndSettle hangs; use fixed-budget pumpFor slices.
//   2. app.main() installs the app's FlutterError.onError — restore the test
//      binding's handler after boot so real failures report with detail.
//   3. Navigate to the seeded puzzle *by id*; the "featured" puzzle is
//      non-deterministic across sim reruns.
//   4. go_router decodes the path param, so read the live solveProvider key
//      off the open SolveScreen widget rather than reconstructing it.

import 'dart:async';

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/routing/app_router.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/screens/solve_screen.dart';
import 'package:crosscue/features/solve/presentation/widgets/crossword_grid.dart';
import 'package:crosscue/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/puz_fixture_builder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    const slice = Duration(milliseconds: 200);
    final ticks = (total.inMilliseconds / slice.inMilliseconds).ceil();
    for (var i = 0; i < ticks; i++) {
      await tester.pump(slice);
    }
  }

  // Drive the app-lifecycle state machine. Two rules force this shape:
  //   - AppLifecycleListener asserts valid transitions, so we can't jump
  //     straight to `paused` — step through `inactive`/`hidden` in order.
  //   - We must NOT pump a frame while `paused`: in the live integration
  //     binding the paused engine stops servicing frames, so `tester.pump()`
  //     would hang forever. The observers fire synchronously here, so no pump
  //     is needed between transitions.
  // Background:  resumed -> inactive -> hidden -> paused
  // Foreground:  paused  -> hidden   -> inactive -> resumed
  void setLifecycle(WidgetTester tester, List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  bool gridContainsLetter(Grid<CellProgress> progress, String letter) {
    for (var r = 0; r < progress.height; r++) {
      for (var c = 0; c < progress.width; c++) {
        if (progress.cell(r, c).letter == letter) return true;
      }
    }
    return false;
  }

  testWidgets(
    'progress survives background/resume; dark mode toggles live',
    (tester) async {
      // 1. Boot + restore the test error handler (see gotcha 2).
      final testOnError = FlutterError.onError;
      await app.main();
      await pumpFor(tester, const Duration(seconds: 5));
      FlutterError.onError = testOnError;

      final BuildContext appCtx = tester.element(find.byType(MaterialApp));
      final ProviderContainer container = ProviderScope.containerOf(appCtx);

      await container
          .read(importRepositoryProvider)
          .importBytes(PuzFixtureBuilder.minimal3x3());
      await pumpFor(tester, const Duration(seconds: 3));
      await container.read(hasSeenOnboardingProvider.notifier).markSeen();
      await pumpFor(tester, const Duration(seconds: 3));

      // 2. Open the seeded puzzle by id (gotcha 3).
      final meta =
          await container.read(importRepositoryProvider).getAllMetadata();
      final puzzle = meta.firstWhere((m) => m.title == 'Test Puzzle');
      final puzzleKey = Uri.encodeComponent(puzzle.id);
      unawaited(
        container.read(appRouterProvider).push(Routes.solveFor(puzzleKey)),
      );
      await pumpFor(tester, const Duration(seconds: 6));
      expect(find.text('ACROSS'), findsOneWidget);

      // Live family key off the open SolveScreen (gotcha 4).
      final openPuzzleId =
          tester.widget<SolveScreen>(find.byType(SolveScreen)).puzzleId;
      final notifier = container.read(solveProvider(openPuzzleId).notifier);

      // 3. §5 — Input a letter, then fake background → resume.
      notifier.inputLetter('A');
      await pumpFor(tester, const Duration(seconds: 1));
      expect(
        gridContainsLetter(
          container.read(solveProvider(openPuzzleId)).value!.progress,
          'A',
        ),
        isTrue,
      );

      // Background (no pump while paused — see setLifecycle). The solve-screen
      // observer pauses synchronously, so we can assert without a frame.
      setLifecycle(tester, const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      expect(
        container.read(solveProvider(openPuzzleId)).value!.isPaused,
        isTrue,
        reason: 'backgrounding should auto-pause the puzzle',
      );

      // Foreground — frames resume once we're back to `resumed`.
      setLifecycle(tester, const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await pumpFor(tester, const Duration(seconds: 1));

      // Progress survived the lifecycle round-trip.
      expect(
        gridContainsLetter(
          container.read(solveProvider(openPuzzleId)).value!.progress,
          'A',
        ),
        isTrue,
        reason: 'typed progress must survive background/resume',
      );

      // Resume the puzzle so re-opening it later isn't gated by the pause
      // overlay (the app intentionally does not auto-resume on foreground).
      notifier.resume();
      await pumpFor(tester, const Duration(milliseconds: 500));

      // 4. §8 — Toggle Dark via the Settings UI and assert it applies live.
      container.read(appRouterProvider).go(Routes.settings);
      await pumpFor(tester, const Duration(seconds: 2));
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await pumpFor(tester, const Duration(seconds: 1));

      expect(container.read(themeModeProvider), AppThemeMode.dark);
      // No restart: the live MaterialApp now resolves a dark scheme.
      final settingsCtx =
          tester.element(find.widgetWithText(AppBar, 'Settings'));
      expect(Theme.of(settingsCtx).brightness, Brightness.dark);

      // 5. The solve view also renders dark (re-open the same puzzle).
      unawaited(
        container.read(appRouterProvider).push(Routes.solveFor(puzzleKey)),
      );
      await pumpFor(tester, const Duration(seconds: 4));
      expect(find.text('ACROSS'), findsOneWidget);
      final solveCtx = tester.element(find.byType(CrosswordGrid));
      expect(Theme.of(solveCtx).brightness, Brightness.dark);

      // Cleanup: restore System theme so we don't pollute the persistent sim
      // DB for the next run / other tests.
      await container
          .read(themeModeProvider.notifier)
          .setMode(AppThemeMode.system);
      await pumpFor(tester, const Duration(milliseconds: 500));
    },
  );
}
