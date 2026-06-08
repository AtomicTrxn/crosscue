import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';

abstract interface class ChallengeResultRepository {
  Future<void> submitSolveResult(ChallengeSolveSubmission submission);
}
