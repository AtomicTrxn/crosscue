import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_secure_store.dart';

const _enabled = bool.fromEnvironment('CHALLENGE_LIVE_API_SMOKE');
const _baseUrl = String.fromEnvironment('CHALLENGE_API_BASE_URL');

void main() {
  test(
    'Flutter API client can talk to a live Challenge Worker',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final identityStore = ChallengeIdentityStore(
        dao: db.appSettingsDao,
        secureStore: InMemorySecureKeyValueStore(),
      );
      final api = ChallengeBoardApi(
        dio: Dio(),
        identityStore: identityStore,
        baseUrl: _baseUrl,
      );

      await api.bootstrap(displayName: 'Maya');
      final mayaIdentity = await identityStore.read();
      await api.bootstrap(displayName: 'Noah');
      final noahIdentity = await identityStore.read();
      expect(mayaIdentity, isNotNull);
      expect(noahIdentity, isNotNull);

      await identityStore.write(mayaIdentity!);
      final created = await api.createBoard(
        const CreateBoardDraft(
          name: 'Friday Crew',
          rankingMode: ChallengeRankingMode.averageTime,
        ),
      );
      await identityStore.write(noahIdentity!);
      final preview = await api.previewInvite(created.inviteLink!);
      expect(preview.result, InviteResult.valid);

      final joined = await api.joinInvite(created.inviteLink!);
      expect(joined?.playerCount, 2);

      final sourcePuzzleId =
          'flutter-smoke-${DateTime.now().microsecondsSinceEpoch}';
      final completedAt = DateTime.now().toUtc();
      final publishedOn = DateTime.utc(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      await identityStore.write(mayaIdentity);
      await api.submitSolveResult(
        ChallengeSolveSubmission(
          sourceId: 'crosshare_daily_mini',
          sourcePuzzleId: sourcePuzzleId,
          completedAtUtc: completedAt,
          elapsedMs: 91000,
          completionType: ChallengeCompletionType.clean,
          cleanSolveEligible: true,
          puzzleTitle: 'Daily Mini',
          publishedOn: publishedOn,
        ),
      );
      await identityStore.write(noahIdentity);
      await api.submitSolveResult(
        ChallengeSolveSubmission(
          sourceId: 'crosshare_daily_mini',
          sourcePuzzleId: sourcePuzzleId,
          completedAtUtc: completedAt,
          elapsedMs: 61000,
          completionType: ChallengeCompletionType.checked,
          cleanSolveEligible: false,
          puzzleTitle: 'Daily Mini',
          publishedOn: publishedOn,
        ),
      );

      await identityStore.write(mayaIdentity);
      final detail = await api.getBoardDetail(created.board.id);
      expect(detail.weekly.first.player.displayName, 'Maya');
      expect(detail.weekly.first.cleanSolves, 1);
      expect(detail.weekly.first.avgClean, '1:31');
      expect(detail.weekly.last.player.displayName, 'Noah');
      expect(detail.weekly.last.cleanSolves, 0);
    },
    skip: !_enabled,
  );
}
