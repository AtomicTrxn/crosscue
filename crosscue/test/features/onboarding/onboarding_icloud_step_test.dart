// Widget test for the onboarding iCloud opt-in step (#142). Drives
// welcome → source → iCloud and asserts "Turn on iCloud Sync" persists the
// flag. Import-only is chosen on the source step so advancing to the fetch
// step doesn't kick off a network download.

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/core/sync/transport/no_op_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:crosscue/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:crosscue/features/settings/domain/models/boot_settings.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<ProviderContainer> pumpToICloudStep(
    WidgetTester tester, {
    SyncTransport? transport,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          bootSettingsProvider.overrideWithValue(BootSettings.defaults),
          syncTransportProvider.overrideWithValue(
            transport ?? FakeSyncTransport(store: <String, String>{}),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    // Welcome → Source.
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Pick import-only so the fetch step won't trigger a network download.
    await tester.tap(find.text('Import your own'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    return ProviderScope.containerOf(
      tester.element(find.byType(OnboardingScreen)),
    );
  }

  testWidgets('source → Continue lands on the iCloud opt-in step',
      (tester) async {
    await pumpToICloudStep(tester);

    expect(find.text('Turn on iCloud Sync'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('"Turn on iCloud Sync" persists the opt-in', (tester) async {
    final container = await pumpToICloudStep(tester);

    await tester.tap(find.text('Turn on iCloud Sync'));
    await tester.pumpAndSettle();

    expect(await container.read(appSettingsProvider).getSyncEnabled(), isTrue);
  });

  testWidgets('"Not now" leaves sync off', (tester) async {
    final container = await pumpToICloudStep(tester);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(await container.read(appSettingsProvider).getSyncEnabled(), isFalse);
  });

  testWidgets('not signed in: Turn on is disabled, Continue proceeds',
      (tester) async {
    // NoOpSyncTransport reports no account → enabling is blocked.
    await pumpToICloudStep(tester, transport: const NoOpSyncTransport());

    final turnOn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Turn on iCloud Sync'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(
      turnOn.onPressed,
      isNull,
      reason: 'cannot enable without an account',
    );
    expect(find.textContaining("not signed in to iCloud"), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
