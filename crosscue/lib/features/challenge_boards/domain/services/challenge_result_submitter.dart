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
  // Both enqueueing and flushing read and replace the same persisted list.
  // Keep the whole operation serial so a submission added while an older
  // flush is awaiting the network cannot be overwritten by that flush's
  // stale snapshot.
  Future<void> _operationChain = Future.value();

  Future<void> submitOrQueue(ChallengeSolveSubmission submission) {
    if (!_enabled) return Future.value();
    return _serialize(() async {
      await _outbox.add(submission);
      await _flush();
    });
  }

  Future<void> flush() {
    if (!_enabled) return Future.value();
    return _serialize(_flush);
  }

  /// Queues a persisted-outbox operation after the previous one, while keeping
  /// the queue usable if that operation fails (for example, a local DB error).
  Future<void> _serialize(Future<void> Function() operation) {
    final queued = _operationChain.then<void>((_) => operation());
    _operationChain = queued.catchError((_) {});
    return queued;
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
