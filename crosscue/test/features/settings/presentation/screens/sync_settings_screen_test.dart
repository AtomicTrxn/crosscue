// Widget test for SyncSettingsScreen (#142). Renders against the real
// SyncController over an in-memory DB + FakeSyncTransport, and checks the
// off → on transition surfaces the status section and Sync now action.

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/features/settings/presentation/screens/sync_settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncTransportProvider
              .overrideWithValue(FakeSyncTransport(store: <String, String>{})),
        ],
        child: const MaterialApp(home: SyncSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders disabled by default with the toggle off',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Sync with iCloud'), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);
    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isFalse);
  });

  testWidgets('enabling reveals the status section and Sync now',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isTrue);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(
      find.text('Turn off and remove iCloud copy'),
      findsOneWidget,
    );
  });
}
