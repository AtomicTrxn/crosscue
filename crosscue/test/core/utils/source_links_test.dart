import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/utils/source_links.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleMetadata _meta({required String sourceId, String? sourcePuzzleId}) =>
    PuzzleMetadata(
      id: 'id',
      sourceId: sourceId,
      title: 'T',
      author: 'A',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 5,
      height: 5,
      importedAt: DateTime.utc(2026),
      sourcePuzzleId: sourcePuzzleId,
    );

void main() {
  group('crosshareUrlFor', () {
    test('derives the Crosshare URL from sourcePuzzleId', () {
      final url = crosshareUrlFor(
        _meta(sourceId: 'crosshare_daily_mini', sourcePuzzleId: 'abc123'),
      );
      expect(url, Uri.parse('https://crosshare.org/crosswords/abc123'));
    });

    test('null when Crosshare row has no sourcePuzzleId', () {
      expect(
        crosshareUrlFor(_meta(sourceId: 'crosshare_daily_mini')),
        isNull,
      );
      expect(
        crosshareUrlFor(
          _meta(sourceId: 'crosshare_daily_mini', sourcePuzzleId: '   '),
        ),
        isNull,
      );
    });

    test('null for local imports even with a sourcePuzzleId', () {
      expect(
        crosshareUrlFor(_meta(sourceId: 'local_import', sourcePuzzleId: 'x')),
        isNull,
      );
    });
  });

  group('source labels', () {
    test('sourceNameFor', () {
      expect(sourceNameFor('crosshare_daily_mini'), 'Crosshare');
      expect(sourceNameFor('local_import'), isNull);
      expect(sourceNameFor('other_source'), 'other_source');
    });

    test('sourceLabelFor', () {
      expect(sourceLabelFor('crosshare_daily_mini'), 'via Crosshare');
      expect(sourceLabelFor('local_import'), isNull);
      expect(sourceLabelFor('other_source'), 'via other_source');
    });
  });
}
