// Integration tests legitimately capture a BuildContext early (the live
// app's MaterialApp element) and use it after async pumps — that's the
// whole point of the "drive the running app from outside" pattern.
// ignore_for_file: use_build_context_synchronously

// Rebus + navigation integration test (PR 3 of #106).
//
// Builds on seed_and_solve_test.dart (PR 2): seeds a puzzle, opens it, then
// exercises two more checklist sections end-to-end on the device —
//   §4  rebus entry via the cell long-press menu
//   §6  Stats screen renders
//   §7  Settings screen renders
//
// Run from crosscue/:
//   flutter test integration_test/rebus_and_navigation_test.dart -d <sim-udid>
//
// Notes / gotchas (some shared with seed_and_solve_test.dart):
//   1. pumpAndSettle hangs — Crosscue's home/solve screens have long-lived
//      listeners (stats, streak, solve timer) that never let the tree go
//      idle. Use fixed-budget pump slices via pumpFor.
//   2. First-run onboarding gates the home screen. Bypass it programmatically
//      via the settings provider — the tutorial keyboard crashes on iOS.
//   3. Cell contents are painted on a CustomPainter, not Text widgets, so the
//      rebus entry is verified through the live SolveState (read off the
//      ProviderContainer), not a find.text.
//   4. Long-press opens a *contextual menu* (since #126 — focus only moves
//      once an action is picked). "Enter rebus" is the first item; tapping it
//      opens the real RebusDialog.

import 'dart:async';

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

  /// Pump fixed-budget frames. See seed_and_solve_test.dart for why
  /// `pumpAndSettle` can't be used here.
  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    const slice = Duration(milliseconds: 200);
    final ticks = (total.inMilliseconds / slice.inMilliseconds).ceil();
    for (var i = 0; i < ticks; i++) {
      await tester.pump(slice);
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
    'long-press rebus entry, then navigate to Stats and Settings',
    (tester) async {
      // 1. Boot the real app + seed a 3x3 puzzle through the production path.
      //    `app.main()` installs the app's own FlutterError.onError crash
      //    handler, which would otherwise swallow framework errors and surface
      //    only as an opaque teardown assertion. Restore the test binding's
      //    handler after boot so real failures report with full detail.
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

      // Bypass first-run onboarding (see note 2).
      await container.read(hasSeenOnboardingProvider.notifier).markSeen();
      await pumpFor(tester, const Duration(seconds: 3));

      // 2. Open the *seeded* puzzle directly by id. (Tapping the "featured"
      //    puzzle is non-deterministic across sim reruns — a more recently
      //    downloaded daily could be featured instead, and its center cell
      //    might be black, breaking the long-press. The 3x3 fixture is all
      //    white, so its center cell is always a valid long-press target.)
      final meta =
          await container.read(importRepositoryProvider).getAllMetadata();
      final puzzle = meta.firstWhere((m) => m.title == 'Test Puzzle');
      final puzzleKey = Uri.encodeComponent(puzzle.id);
      unawaited(
        container.read(appRouterProvider).push(Routes.solveFor(puzzleKey)),
      );
      await pumpFor(tester, const Duration(seconds: 6));
      expect(find.text('ACROSS'), findsOneWidget);

      // 3. §4 — Rebus entry. Long-press the grid (center cell of the all-white
      //    3x3) → contextual menu → "Enter rebus" → RebusDialog.
      await tester.longPress(find.byType(CrosswordGrid));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(
        find.text('Enter rebus'),
        findsOneWidget,
        reason: 'long-press should open the cell contextual menu (#126)',
      );

      await tester.tap(find.text('Enter rebus'));
      await pumpFor(tester, const Duration(seconds: 1));

      // Type into the dialog's TextField specifically — the solve screen also
      // has a hidden TextField driving the soft keyboard.
      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogField, findsOneWidget);
      await tester.enterText(dialogField, 'EST');
      await pumpFor(tester, const Duration(milliseconds: 500));
      await tester.tap(find.text('Enter'));
      await pumpFor(tester, const Duration(seconds: 1));

      // Verify the multi-letter entry landed (cells are canvas-painted, so we
      // read the live SolveState rather than looking for a Text widget). Read
      // the family key off the open SolveScreen widget — go_router decodes the
      // path param, so the live provider key is the *decoded* id, not the
      // encoded one we pushed with.
      final openPuzzleId =
          tester.widget<SolveScreen>(find.byType(SolveScreen)).puzzleId;
      final solveState = container.read(solveProvider(openPuzzleId)).value;
      expect(solveState, isNotNull);
      expect(
        gridContainsLetter(solveState!.progress, 'EST'),
        isTrue,
        reason: 'rebus "EST" should be written into the focused cell',
      );

      // 4. §6 — Stats renders. Navigate via the router (deterministic, and it
      //    unwinds the pushed solve route). Asserting a specific per-puzzle
      //    tile is intentionally avoided: tile contents vary with accumulated
      //    DB state across sim reruns — the same brittleness seed_and_solve
      //    calls out.
      container.read(appRouterProvider).go(Routes.stats);
      await pumpFor(tester, const Duration(seconds: 2));
      expect(find.widgetWithText(AppBar, 'Stats'), findsOneWidget);

      // 5. §7 — Settings renders, with a stable row present.
      container.read(appRouterProvider).go(Routes.settings);
      await pumpFor(tester, const Duration(seconds: 2));
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    },
  );
}
