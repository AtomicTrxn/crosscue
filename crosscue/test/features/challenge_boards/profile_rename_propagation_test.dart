import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/providers/challenge_board_providers.dart';
import 'package:crosscue/features/challenge_boards/sample/sample_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renaming refetches board leaderboards with the new handle', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final board =
        await container.read(challengeBoardRepositoryProvider).createBoard(
              const CreateBoardDraft(
                name: 'Rename Crew',
                rankingMode: ChallengeRankingMode.averageTime,
              ),
            );

    final before =
        await container.read(challengeBoardDetailProvider(board.id).future);
    final meBefore =
        before.weekly.firstWhere((entry) => entry.player.isMe).player;
    expect(meBefore.displayName, SampleData.me.displayName);

    await container
        .read(challengeProfileRepositoryProvider)
        .updateDisplayName('Newname');
    // The screen invalidates profile + boards + board details together
    // (_invalidateProfileEverywhere); a stale cached detail would keep the
    // old handle until app restart.
    container.invalidate(challengeProfileProvider);
    container.invalidate(challengeBoardsProvider);
    container.invalidate(challengeBoardDetailProvider);

    final after =
        await container.read(challengeBoardDetailProvider(board.id).future);
    final meAfter =
        after.weekly.firstWhere((entry) => entry.player.isMe).player;
    expect(meAfter.displayName, 'Newname');
  });
}
