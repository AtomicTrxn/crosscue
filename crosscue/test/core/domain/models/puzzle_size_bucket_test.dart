import 'package:crosscue/core/domain/models/puzzle_size_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleSizeBucket.fromDimensions', () {
    test('classifies 5×5 as mini', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 5, height: 5),
        PuzzleSizeBucket.mini,
      );
    });

    test('classifies 7×7 as mini (boundary)', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 7, height: 7),
        PuzzleSizeBucket.mini,
      );
    });

    test('classifies 8×8 as other (above mini boundary)', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 8, height: 8),
        PuzzleSizeBucket.other,
      );
    });

    test('classifies 15×15 as standard', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 15, height: 15),
        PuzzleSizeBucket.standard,
      );
    });

    test('classifies 21×21 as large', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 21, height: 21),
        PuzzleSizeBucket.large,
      );
    });

    test('classifies non-square 15×16 as other', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 15, height: 16),
        PuzzleSizeBucket.other,
      );
    });

    test('classifies non-square 21×15 as other', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 21, height: 15),
        PuzzleSizeBucket.other,
      );
    });

    test('classifies non-square but small (5×7) as mini', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 5, height: 7),
        PuzzleSizeBucket.mini,
      );
    });

    test('classifies oversized 25×25 as other', () {
      expect(
        PuzzleSizeBucket.fromDimensions(width: 25, height: 25),
        PuzzleSizeBucket.other,
      );
    });
  });

  group('PuzzleSizeBucket.tracksPersonalBest', () {
    test('mini / standard / large track a personal best', () {
      expect(PuzzleSizeBucket.mini.tracksPersonalBest, isTrue);
      expect(PuzzleSizeBucket.standard.tracksPersonalBest, isTrue);
      expect(PuzzleSizeBucket.large.tracksPersonalBest, isTrue);
    });

    test('other does not track a personal best', () {
      expect(PuzzleSizeBucket.other.tracksPersonalBest, isFalse);
    });
  });

  group('PuzzleSizeBucket.displayLabel', () {
    test('returns the size-specific label for tracked buckets', () {
      expect(PuzzleSizeBucket.mini.displayLabel, 'Mini');
      expect(PuzzleSizeBucket.standard.displayLabel, '15×15');
      expect(PuzzleSizeBucket.large.displayLabel, '21×21');
    });

    test('returns empty string for the untracked bucket', () {
      expect(PuzzleSizeBucket.other.displayLabel, '');
    });
  });
}
