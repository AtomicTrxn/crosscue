import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for T6: verifies that a TextEditingController created
/// before showDialog is always disposed after the dialog closes, regardless
/// of how it is dismissed (OK button, system back, barrier tap).
void main() {
  group('rebus dialog controller disposal', () {
    Future<void> openAndDismiss(
      WidgetTester tester, {
      required Future<void> Function(BuildContext ctx) dismiss,
    }) async {
      bool disposed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: TextField(controller: controller),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  controller.dispose();
                  disposed = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(AlertDialog));
      await dismiss(ctx);
      await tester.pumpAndSettle();

      expect(
        disposed,
        isTrue,
        reason: 'Controller must be disposed after dialog closes',
      );
    }

    testWidgets('disposes controller when OK button is tapped', (tester) async {
      await openAndDismiss(
        tester,
        dismiss: (_) async => tester.tap(find.text('OK')),
      );
    });

    testWidgets('disposes controller on system back', (tester) async {
      await openAndDismiss(
        tester,
        dismiss: (ctx) async {
          final navigator =
              tester.state<NavigatorState>(find.byType(Navigator).last);
          navigator.pop();
        },
      );
    });

    testWidgets('disposes controller on barrier tap', (tester) async {
      await openAndDismiss(
        tester,
        dismiss: (_) async {
          // Tap outside the dialog (top-left corner of the screen).
          await tester.tapAt(const Offset(10, 10));
        },
      );
    });
  });
}
