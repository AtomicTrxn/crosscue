// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';

abstract interface class ChallengeBoardRepository {
  Future<List<Board>> listBoards();
  Future<BoardDetail> getBoardDetail(String boardId);
  Future<Board> createBoard(CreateBoardDraft draft);
  Future<InvitePreview> previewInvite(String inviteLink);
  Future<Board?> joinInvite(String inviteLink);
  Future<void> leaveBoard(String boardId);
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
