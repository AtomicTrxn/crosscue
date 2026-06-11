import 'dart:async';

import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_board_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_profile_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_result_repository.dart';
import 'package:crosscue/features/challenge_boards/sample/sample_data.dart';
import 'package:flutter/foundation.dart';

class SampleChallengeRepository extends ChangeNotifier
    implements
        ChallengeBoardRepository,
        ChallengeProfileRepository,
        ChallengeResultRepository {
  SampleChallengeRepository()
      : _me = SampleData.me,
        // Start with no boards. This repository is the fallback used whenever
        // no challenge backend is configured (the default release build — see
        // issue #198), so it must not present fabricated boards/standings as
        // real. The Challenge tab then shows its genuine empty state with the
        // Create / Join CTA (WeeklyEmpty), and create/join still work locally.
        // SampleData.boards is retained for tests/design demos.
        _boards = <Board>[];

  Player _me;
  final List<Board> _boards;
  final Map<String, Set<String>> _removedByBoard = {};
  int _nextBoard = 6;

  /// Neutral until the user has real challenge results from a backend.
  LifetimeStats get lifetimeStats => SampleData.lifetimeEmpty;

  @override
  Future<List<Board>> listBoards() async => List<Board>.unmodifiable(_boards);

  @override
  Future<BoardDetail> getBoardDetail(String boardId) async {
    final board = _boards.firstWhere(
      (board) => board.id == boardId,
      orElse: () => _boards.first,
    );
    final removed = _removedByBoard[board.id] ?? const <String>{};
    final weekly = SampleData.weeklyLeaderboard
        .where((entry) => !removed.contains(entry.player.id))
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
  Future<Board> createBoard(CreateBoardDraft draft) async {
    final board = Board(
      id: 'b${_nextBoard++}',
      name: draft.name,
      playerCount: 1,
      rankingMode: draft.rankingMode,
      ownerPlayerId: _me.id,
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
  Future<void> removeMember(String boardId, String playerId) async {
    (_removedByBoard[boardId] ??= <String>{}).add(playerId);
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
  Future<void> rotateRecovery() async {}

  @override
  Future<void> submitSolveResult(ChallengeSolveSubmission submission) async {}
}
