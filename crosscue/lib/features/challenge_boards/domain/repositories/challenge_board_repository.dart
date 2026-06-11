import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';

abstract interface class ChallengeBoardRepository {
  Future<List<Board>> listBoards();
  Future<BoardDetail> getBoardDetail(String boardId);
  Future<Board> createBoard(CreateBoardDraft draft);
  Future<InvitePreview> previewInvite(String inviteLink);
  Future<Board?> joinInvite(String inviteLink);
  Future<void> leaveBoard(String boardId);

  /// Owner-only: removes an active member from the board.
  Future<void> removeMember(String boardId, String playerId);
  Future<String> regenerateInvite(String boardId);
  Future<String> getInviteLink(String boardId);
}

class BoardDetail {
  const BoardDetail({
    required this.board,
    required this.weekly,
    required this.lifetime,
  });

  final Board board;
  final List<LeaderboardEntry> weekly;
  final List<LeaderboardEntry> lifetime;
}
