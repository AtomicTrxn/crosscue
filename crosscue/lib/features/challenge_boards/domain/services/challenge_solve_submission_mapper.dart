import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/util/utc_week.dart';

const challengeEligibleSourceId = 'crosshare_daily_mini';

ChallengeSolveSubmission? challengeSubmissionFromCompletion({
  required Puzzle puzzle,
  required int elapsedMs,
  required CompletionType completionType,
  required bool cleanSolveEligible,
  required DateTime completedAtUtc,
}) {
  final metadata = puzzle.metadata;
  final sourcePuzzleId = metadata.sourcePuzzleId;
  final publishDate = metadata.publishDate?.toUtc();
  if (metadata.sourceId != challengeEligibleSourceId ||
      sourcePuzzleId == null ||
      sourcePuzzleId.trim().isEmpty ||
      publishDate == null ||
      !_isInChallengeWeek(publishDate, completedAtUtc)) {
    return null;
  }

  return ChallengeSolveSubmission(
    sourceId: metadata.sourceId,
    sourcePuzzleId: sourcePuzzleId,
    completedAtUtc: completedAtUtc.toUtc(),
    elapsedMs: elapsedMs,
    completionType: _completionType(completionType),
    cleanSolveEligible: cleanSolveEligible,
    puzzleTitle: metadata.title,
    publishedOn: publishDate,
  );
}

bool _isInChallengeWeek(DateTime publishDate, DateTime completedAtUtc) {
  final start = UtcWeek.weekStart(completedAtUtc);
  final end = start.add(const Duration(days: 7));
  return !publishDate.isBefore(start) && publishDate.isBefore(end);
}

ChallengeCompletionType _completionType(CompletionType completionType) {
  return switch (completionType) {
    CompletionType.clean => ChallengeCompletionType.clean,
    CompletionType.checked => ChallengeCompletionType.checked,
    CompletionType.hinted => ChallengeCompletionType.hinted,
    CompletionType.revealed => ChallengeCompletionType.revealed,
  };
}
