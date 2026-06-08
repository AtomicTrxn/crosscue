// Verifies the no-backend (sample) gate for the Challenge tab (issue #198):
// the fallback repository must start empty and neutral so the shipped app
// shows the Create / Join empty state instead of fabricated boards/standings.

import 'package:crosscue/features/challenge_boards/data/repositories/sample_challenge_repository.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SampleChallengeRepository no-backend gate', () {
    test('starts with no boards', () async {
      final repo = SampleChallengeRepository();
      expect(await repo.listBoards(), isEmpty);
    });

    test('reports a neutral lifetime (nothing to rank yet)', () {
      final stats = SampleChallengeRepository().lifetimeStats;
      expect(stats.cleanSolves, 0);
      expect(stats.avgClean, '—');
      expect(stats.bestClean, '—');
    });

    test('create still works, so the CTA is functional', () async {
      final repo = SampleChallengeRepository();
      final board = await repo.createBoard(
        const CreateBoardDraft(
          name: 'Friends',
          rankingMode: ChallengeRankingMode.fastestTime,
        ),
      );
      expect(board.name, 'Friends');
      expect(await repo.listBoards(), hasLength(1));
    });
  });
}
