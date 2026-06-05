import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/solve/presentation/widgets/puzzle_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleMetadata _meta({
  required String sourceId,
  String? sourcePuzzleId,
  String author = 'Jane Doe',
  String copyright = '© 2026 Jane',
}) =>
    PuzzleMetadata(
      id: 'id',
      sourceId: sourceId,
      title: 'Monday Mini',
      author: author,
      copyright: copyright,
      format: PuzzleFormat.puz,
      width: 5,
      height: 5,
      importedAt: DateTime.utc(2026, 5, 9),
      sourcePuzzleId: sourcePuzzleId,
      publishDate: DateTime.utc(2026, 5, 9),
    );

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets(
    'Crosshare puzzle shows attribution + Open on Crosshare and launches URL',
    (tester) async {
      Uri? launched;
      await _pump(
        tester,
        PuzzleInfoSheet(
          metadata: _meta(
            sourceId: 'crosshare_daily_mini',
            sourcePuzzleId: 'abc123',
          ),
          launch: (uri) async {
            launched = uri;
            return true;
          },
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Crosshare'), findsOneWidget);
      expect(find.text('© 2026 Jane'), findsOneWidget);

      final action = find.text('Open on Crosshare');
      expect(action, findsOneWidget);

      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(launched, Uri.parse('https://crosshare.org/crosswords/abc123'));
    },
  );

  testWidgets('local import shows no source link', (tester) async {
    await _pump(
      tester,
      PuzzleInfoSheet(
        metadata: _meta(sourceId: 'local_import'),
      ),
    );

    expect(find.text('Open on Crosshare'), findsNothing);
    // Source row is hidden for local imports.
    expect(find.text('Crosshare'), findsNothing);
  });
}
