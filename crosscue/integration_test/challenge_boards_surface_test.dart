// Integration test for the offline/local Challenge Boards experience.
//
// It deliberately runs without a Challenge Boards endpoint so it validates the
// customer-safe release-build fallback: the tab must not fabricate standings,
// but customers can still understand the feature and create a local board.

// ignore_for_file: use_build_context_synchronously

import 'package:crosscue/core/routing/app_router.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    const slice = Duration(milliseconds: 200);
    final ticks = (total.inMilliseconds / slice.inMilliseconds).ceil();
    for (var i = 0; i < ticks; i++) {
      await tester.pump(slice);
    }
  }

  testWidgets(
    'Challenge Boards explains its empty state and creates a local board',
    (tester) async {
      final testOnError = FlutterError.onError;
      await app.main();
      await pumpFor(tester, const Duration(seconds: 5));
      FlutterError.onError = testOnError;

      final appContext = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(appContext);
      await container.read(hasSeenOnboardingProvider.notifier).markSeen();
      await pumpFor(tester, const Duration(seconds: 1));

      // Use the live app router rather than injecting a test-only screen: this
      // covers the customer-visible tab and its provider-driven fallback.
      container.read(appRouterProvider).go(Routes.challenge);
      await pumpFor(tester, const Duration(seconds: 2));

      // The label appears in both the screen heading and bottom navigation.
      expect(find.text('Challenge'), findsWidgets);
      expect(find.text('Start a challenge with friends'), findsOneWidget);
      expect(find.text('Create a board'), findsWidgets);
      expect(find.text('Join with a link'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Create a board'));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.text('Challenge board'), findsOneWidget);

      await tester.tap(find.text('Create board'));
      await pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.text('Create a board'), findsWidgets);

      await tester.enterText(find.byType(TextField), 'Weekend Solvers');
      await pumpFor(tester, const Duration(milliseconds: 300));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Create board'),
      );
      await pumpFor(tester, const Duration(seconds: 1));

      // The invite sheet is the confirmation customers receive after a
      // successful create; no external sharing service is invoked here.
      expect(find.text('Board created'), findsOneWidget);
      expect(find.textContaining('Weekend Solvers'), findsWidgets);
      expect(find.text('Share link'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
