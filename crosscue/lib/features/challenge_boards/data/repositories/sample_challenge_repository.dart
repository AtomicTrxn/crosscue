// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'dart:async';

import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_board_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_profile_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_result_repository.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/sample/sample_data.dart';
import 'package:flutter/foundation.dart';

class SampleChallengeRepository extends ChangeNotifier
    implements
        ChallengeBoardRepository,
        ChallengeProfileRepository,
        ChallengeResultRepository {
  SampleChallengeRepository()
      : _me = SampleData.me,
        _boards = List<Board>.from(SampleData.boards);

  Player _me;
  final List<Board> _boards;
  int _nextBoard = 6;

  LifetimeStats get lifetimeStats => SampleData.lifetime;

  @override
  Future<List<Board>> listBoards() async => List<Board>.unmodifiable(_boards);

  @override
  Future<BoardDetail> getBoardDetail(String boardId) async {
    final board = _boards.firstWhere(
      (board) => board.id == boardId,
      orElse: () => _boards.first,
    );
    final weekly = SampleData.weeklyLeaderboard
        .map(
          (entry) => entry.player.isMe
              ? LeaderboardEntry(
                  rank: entry.rank,
                  player: _me,
                  cleanSolves: entry.cleanSolves,
                  avgClean: entry.avgClean,
                  weeksCounted: entry.weeksCounted,
                )
              : entry,
        )
        .toList(growable: false);
    return BoardDetail(board: board, weekly: weekly, lifetime: weekly);
  }

  @override
  Future<Board> createBoard(String name) async {
    final board = Board(
      id: 'b${_nextBoard++}',
      name: name,
      playerCount: 1,
      myWeekly: const Standing(
        rank: 1,
        outOf: 1,
        cleanSolves: 0,
        avgClean: '—',
      ),
    );
    _boards.insert(0, board);
    notifyListeners();
    return board;
  }

  @override
  Future<String> getInviteLink(String boardId) async =>
      'https://crosscue.app/join/$boardId?token=demo-invite';

  @override
  Future<Board?> joinInvite(String inviteLink) async {
    final preview = await previewInvite(inviteLink);
    if (preview.result == InviteResult.alreadyMember) {
      return _boards.firstWhere(
        (board) => board.name == preview.boardName,
        orElse: () => _boards.first,
      );
    }
    if (preview.result != InviteResult.valid) return null;
    final board = Board(
      id: 'joined-${_nextBoard++}',
      name: preview.boardName,
      playerCount: preview.playerCount + 1,
      myWeekly: Standing(
        rank: preview.playerCount + 1,
        outOf: preview.playerCount + 1,
        cleanSolves: 0,
        avgClean: '—',
      ),
    );
    _boards.insert(0, board);
    notifyListeners();
    return board;
  }

  @override
  Future<void> leaveBoard(String boardId) async {
    _boards.removeWhere((board) => board.id == boardId);
    notifyListeners();
  }

  @override
  Future<InvitePreview> previewInvite(String inviteLink) async {
    final link = inviteLink.toLowerCase();
    if (link.contains('offline')) {
      return const InvitePreview(
        result: InviteResult.offline,
        boardName: 'Challenge board',
        playerCount: 0,
        daysUntilExpiry: 0,
      );
    }
    if (link.contains('network')) {
      return const InvitePreview(
        result: InviteResult.networkError,
        boardName: 'Challenge board',
        playerCount: 0,
        daysUntilExpiry: 0,
      );
    }
    if (link.contains('deleted')) {
      return const InvitePreview(
        result: InviteResult.boardDeleted,
        boardName: 'Old board',
        playerCount: 0,
        daysUntilExpiry: 0,
      );
    }
    if (link.contains('full')) {
      return const InvitePreview(
        result: InviteResult.boardFull,
        boardName: 'Full board',
        playerCount: ChallengeLimits.maxPlayersPerBoard,
        daysUntilExpiry: 12,
      );
    }
    if (link.contains('limit')) {
      return const InvitePreview(
        result: InviteResult.playerLimitReached,
        boardName: 'Saturday Solvers',
        playerCount: 9,
        daysUntilExpiry: 12,
      );
    }
    if (link.contains('expired') || link.contains('invalid')) {
      return const InvitePreview(
        result: InviteResult.invalidOrExpired,
        boardName: 'Challenge board',
        playerCount: 0,
        daysUntilExpiry: 0,
      );
    }
    if (_boards.any((board) => inviteLink.contains(board.id))) {
      final board =
          _boards.firstWhere((board) => inviteLink.contains(board.id));
      return InvitePreview(
        result: InviteResult.alreadyMember,
        boardName: board.name,
        playerCount: board.playerCount,
        daysUntilExpiry: 28,
      );
    }
    return SampleData.invitePreview;
  }

  @override
  Future<String> regenerateInvite(String boardId) async =>
      'https://crosscue.app/join/$boardId?token=demo-regenerated';

  @override
  Future<Player> getProfile() async => _me;

  @override
  Future<Player> updateAvatar(PlayerAvatar avatar) async {
    _me = _me.copyWith(avatar: avatar);
    notifyListeners();
    return _me;
  }

  @override
  Future<Player> updateDisplayName(String displayName) async {
    _me = _me.copyWith(displayName: displayName);
    notifyListeners();
    return _me;
  }

  @override
  Future<void> submitSolveResult(ChallengeSolveSubmission submission) async {}
}
