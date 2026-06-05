import 'package:crosscue/core/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('publish-date formatting', () {
    test('uses UTC calendar day for Crosshare midnight publish dates', () {
      final easternJune4Evening = DateTime.parse('2026-06-04T20:00:00-04:00');

      expect(
        formatPuzzlePublishDateShort(easternJune4Evening),
        'Fri Jun 5',
      );
      expect(
        formatPuzzlePublishDateLong(easternJune4Evening),
        '5 Jun 2026',
      );
    });
  });
}
