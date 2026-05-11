// Smoke test: app launches without crashing.
import 'package:crosscue/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CrosscueApp(),
      ),
    );
    // Allow async providers to settle.
    await tester.pumpAndSettle();
    // If we get here without an exception, the app launched successfully.
  });
}
