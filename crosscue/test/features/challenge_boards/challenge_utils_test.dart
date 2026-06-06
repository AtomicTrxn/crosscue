import 'dart:ui' as ui;

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/challenge_boards/domain/services/challenge_solve_submission_mapper.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/util/avatar_normalizer.dart';
import 'package:crosscue/features/challenge_boards/util/display_name_validator.dart';
import 'package:crosscue/features/challenge_boards/util/utc_week.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisplayNameValidator', () {
    test('accepts allowed short display names', () {
      expect(DisplayNameValidator.validate('Maya_7'), isNull);
      expect(DisplayNameValidator.validate('Jo-Jo'), isNull);
    });

    test('rejects invalid display names', () {
      expect(DisplayNameValidator.validate('   '), 'Enter a display name.');
      expect(
        DisplayNameValidator.validate('LongerThan10'),
        'Max 10 characters.',
      );
      expect(
        DisplayNameValidator.validate('Bad  Name'),
        'Avoid repeated spaces.',
      );
      expect(
        DisplayNameValidator.validate('Maya!'),
        'Use letters, numbers, spaces, _ or - only',
      );
    });
  });

  group('UtcWeek', () {
    test('weekStart returns Monday 00:00 UTC', () {
      final start = UtcWeek.weekStart(DateTime.utc(2026, 6, 5, 17));
      expect(start, DateTime.utc(2026, 6, 1));
    });

    test('reset countdown is based on UTC boundaries', () {
      final label = UtcWeek.resetCountdownLabel(
        DateTime.utc(2026, 6, 7, 23, 30),
      );
      expect(label, 'Resets in 30m');
    });
  });

  group('challengeSubmissionFromCompletion', () {
    test('maps eligible Crosshare daily completion to submission', () {
      final submission = challengeSubmissionFromCompletion(
        puzzle: _puzzle(sourceId: challengeEligibleSourceId),
        elapsedMs: 125000,
        completionType: CompletionType.clean,
        cleanSolveEligible: true,
        completedAtUtc: DateTime.utc(2026, 6, 5, 12),
      );

      expect(submission, isNotNull);
      expect(submission!.sourcePuzzleId, '2026-06-05');
      expect(submission.completionType, ChallengeCompletionType.clean);
      expect(submission.isClean, isTrue);
    });

    test('ignores local imports and missing source puzzle ids', () {
      expect(
        challengeSubmissionFromCompletion(
          puzzle: _puzzle(sourceId: 'local_import'),
          elapsedMs: 125000,
          completionType: CompletionType.clean,
          cleanSolveEligible: true,
          completedAtUtc: DateTime.utc(2026),
        ),
        isNull,
      );
      expect(
        challengeSubmissionFromCompletion(
          puzzle: _puzzle(
            sourceId: challengeEligibleSourceId,
            sourcePuzzleId: null,
          ),
          elapsedMs: 125000,
          completionType: CompletionType.clean,
          cleanSolveEligible: true,
          completedAtUtc: DateTime.utc(2026),
        ),
        isNull,
      );
    });
  });

  testWidgets('AvatarNormalizer outputs a 512 square PNG', (tester) async {
    final bytes = await tester.runAsync(() async {
      final source = await _solidImage();
      return AvatarNormalizer.normalize(
        source: source,
        viewport: const Size.square(32),
        outputSize: 512,
      );
    });
    expect(bytes, isNotNull);
    final pngBytes = bytes!;

    expect(pngBytes.take(8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    expect(pngBytes.buffer.asByteData().getUint32(16), 512);
    expect(pngBytes.buffer.asByteData().getUint32(20), 512);
  });
}

Puzzle _puzzle({
  required String sourceId,
  String? sourcePuzzleId = '2026-06-05',
}) {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'puzzle-id',
      sourceId: sourceId,
      sourcePuzzleId: sourcePuzzleId,
      title: 'Daily Mini',
      author: 'Crosscue',
      copyright: '',
      format: PuzzleFormat.ipuz,
      width: 1,
      height: 1,
      importedAt: DateTime.utc(2026, 6, 5),
      publishDate: DateTime.utc(2026, 6, 5),
      fillableCellCount: 1,
    ),
    grid: Grid<SolutionCell>.generate(
      1,
      1,
      (_, __) => const SolutionCell(solution: 'A'),
    ),
    clues: const [],
  );
}

Future<ui.Image> _solidImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 16, 16),
    Paint()..color = Colors.blue,
  );
  final picture = recorder.endRecording();
  return picture.toImage(16, 16);
}
