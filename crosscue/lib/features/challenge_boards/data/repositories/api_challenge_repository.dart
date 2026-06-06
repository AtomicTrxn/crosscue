import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_board_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_profile_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_result_repository.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';

class ApiChallengeRepository
    implements
        ChallengeBoardRepository,
        ChallengeProfileRepository,
        ChallengeResultRepository {
  const ApiChallengeRepository({required ChallengeBoardApi api}) : _api = api;

  final ChallengeBoardApi _api;

  Future<LifetimeStats> getLifetimeStats() async {
    final summary = await _api.listBoards();
    return summary.lifetime;
  }

  @override
  Future<Board> createBoard(String name) async {
    final created = await _api.createBoard(name);
    return created.board;
  }

  Future<CreateBoardResponse> createBoardWithInvite(String name) =>
      _api.createBoard(name);

  @override
  Future<BoardDetail> getBoardDetail(String boardId) =>
      _api.getBoardDetail(boardId);

  @override
  Future<String> getInviteLink(String boardId) => _api.freshInviteLink(boardId);

  @override
  Future<Board?> joinInvite(String inviteLink) => _api.joinInvite(inviteLink);

  @override
  Future<void> leaveBoard(String boardId) => _api.leaveBoard(boardId);

  @override
  Future<List<Board>> listBoards() async {
    final summary = await _api.listBoards();
    return summary.boards;
  }

  @override
  Future<InvitePreview> previewInvite(String inviteLink) =>
      _api.previewInvite(inviteLink);

  @override
  Future<String> regenerateInvite(String boardId) =>
      _api.regenerateInvite(boardId);

  @override
  Future<Player> getProfile() => _api.getProfile();

  @override
  Future<Player> updateAvatar(PlayerAvatar avatar) => _api.updateAvatar(avatar);

  @override
  Future<Player> updateDisplayName(String displayName) =>
      _api.updateDisplayName(displayName);

  @override
  Future<void> submitSolveResult(ChallengeSolveSubmission submission) =>
      _api.submitSolveResult(submission);
}
