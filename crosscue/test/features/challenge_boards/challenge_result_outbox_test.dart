import 'dart:async';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_result_outbox.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_result_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/services/challenge_result_submitter.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChallengeResultOutbox outbox;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outbox = ChallengeResultOutbox(dao: db.appSettingsDao);
  });

  tearDown(() => db.close());

  test('outbox dedupes by source puzzle id', () async {
    await outbox.add(_submission(elapsedMs: 100000));
    await outbox.add(_submission(elapsedMs: 90000));

    final queued = await outbox.read();
    expect(queued, hasLength(1));
    expect(queued.single.elapsedMs, 90000);
  });

  test('submitter retains failed submissions and flushes later', () async {
    final repository = _FlakyResultRepository();
    final submitter = ChallengeResultSubmitter(
      repository: repository,
      outbox: outbox,
      enabled: true,
    );

    await submitter.submitOrQueue(_submission());

    expect(await outbox.read(), hasLength(1));
    expect(repository.attempts, 1);

    repository.fail = false;
    await submitter.flush();

    expect(await outbox.read(), isEmpty);
    expect(repository.submitted.single.sourcePuzzleId, '2026-06-05');
  });

  test('disabled submitter ignores submissions without queuing', () async {
    final submitter = ChallengeResultSubmitter(
      repository: _FlakyResultRepository()..fail = false,
      outbox: outbox,
      enabled: false,
    );

    await submitter.submitOrQueue(_submission());

    expect(await outbox.read(), isEmpty);
  });

  test('concurrent flush calls share one in-flight submission pass', () async {
    final repository = _SlowResultRepository();
    await outbox.add(_submission());
    final submitter = ChallengeResultSubmitter(
      repository: repository,
      outbox: outbox,
      enabled: true,
    );

    final first = submitter.flush();
    final second = submitter.flush();
    await Future<void>.delayed(Duration.zero);

    expect(repository.started, 1);
    repository.complete();
    await Future.wait([first, second]);

    expect(repository.submitted, hasLength(1));
    expect(await outbox.read(), isEmpty);
  });
}

ChallengeSolveSubmission _submission({int elapsedMs = 100000}) {
  return ChallengeSolveSubmission(
    sourceId: 'crosshare_daily_mini',
    sourcePuzzleId: '2026-06-05',
    completedAtUtc: DateTime.utc(2026, 6, 5, 12),
    elapsedMs: elapsedMs,
    completionType: ChallengeCompletionType.clean,
    cleanSolveEligible: true,
  );
}

class _FlakyResultRepository implements ChallengeResultRepository {
  bool fail = true;
  int attempts = 0;
  final submitted = <ChallengeSolveSubmission>[];

  @override
  Future<void> submitSolveResult(ChallengeSolveSubmission submission) async {
    attempts += 1;
    if (fail) throw StateError('offline');
    submitted.add(submission);
  }
}

class _SlowResultRepository implements ChallengeResultRepository {
  final _completer = Completer<void>();
  final submitted = <ChallengeSolveSubmission>[];
  int started = 0;

  void complete() => _completer.complete();

  @override
  Future<void> submitSolveResult(ChallengeSolveSubmission submission) async {
    started += 1;
    await _completer.future;
    submitted.add(submission);
  }
}
