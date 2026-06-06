import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';

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
  if (metadata.sourceId != challengeEligibleSourceId ||
      sourcePuzzleId == null ||
      sourcePuzzleId.trim().isEmpty) {
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
    publishedOn: metadata.publishDate,
  );
}

ChallengeCompletionType _completionType(CompletionType completionType) {
  return switch (completionType) {
    CompletionType.clean => ChallengeCompletionType.clean,
    CompletionType.checked => ChallengeCompletionType.checked,
    CompletionType.hinted => ChallengeCompletionType.hinted,
    CompletionType.revealed => ChallengeCompletionType.revealed,
  };
}
