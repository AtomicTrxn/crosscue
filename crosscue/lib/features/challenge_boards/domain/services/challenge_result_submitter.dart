import 'package:crosscue/features/challenge_boards/data/services/challenge_result_outbox.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_result_repository.dart';

class ChallengeResultSubmitter {
  ChallengeResultSubmitter({
    required ChallengeResultRepository repository,
    required ChallengeResultOutbox outbox,
    required bool enabled,
  })  : _repository = repository,
        _outbox = outbox,
        _enabled = enabled;

  final ChallengeResultRepository _repository;
  final ChallengeResultOutbox _outbox;
  final bool _enabled;
  Future<void>? _flushInFlight;

  Future<void> submitOrQueue(ChallengeSolveSubmission submission) async {
    if (!_enabled) return;
    await _outbox.add(submission);
    await flush();
  }

  Future<void> flush() async {
    if (!_enabled) return;
    final inFlight = _flushInFlight;
    if (inFlight != null) return inFlight;

    final flush = _flush();
    _flushInFlight = flush;
    try {
      await flush;
    } finally {
      if (identical(_flushInFlight, flush)) {
        _flushInFlight = null;
      }
    }
  }

  Future<void> _flush() async {
    final queued = await _outbox.read();
    if (queued.isEmpty) return;

    final remaining = <ChallengeSolveSubmission>[];
    for (var i = 0; i < queued.length; i++) {
      final submission = queued[i];
      try {
        await _repository.submitSolveResult(submission);
      } catch (_) {
        remaining.addAll(queued.skip(i));
        break;
      }
    }
    await _outbox.replace(remaining);
  }
}
