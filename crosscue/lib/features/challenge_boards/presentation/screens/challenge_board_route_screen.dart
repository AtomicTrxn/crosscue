import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/providers/challenge_board_providers.dart';
import 'package:crosscue/features/challenge_boards/presentation/screens/board_detail_screen.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/board_sheets.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/confirm_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChallengeBoardRouteScreen extends ConsumerWidget {
  const ChallengeBoardRouteScreen({super.key, required this.boardId});

  final String boardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(challengeBoardDetailProvider(boardId));
    return detail.when(
      data: (data) => BoardDetailScreen(
        boardName: data.board.name,
        playerCount: data.board.playerCount,
        rankingMode: data.board.rankingMode,
        weekly: data.weekly,
        lifetime: data.lifetime,
        onRefresh: () async =>
            ref.invalidate(challengeBoardDetailProvider(boardId)),
        onShare: () => _share(context, ref, data.board),
        onRegenerate: () => _regenerate(context, ref, data.board),
        onLeave: () => _leave(context, ref, data.board),
        ownerPlayerId: data.board.ownerPlayerId,
        onRemoveMember: (player) =>
            _removeMember(context, ref, data.board, player),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Challenge board')),
        body: const Center(child: Text('This board could not be loaded.')),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Challenge board')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    Board board,
    Player player,
  ) async {
    final confirmed = await showRemoveMemberDialog(
      context,
      playerName: player.displayName,
      boardName: board.name,
    );
    if (confirmed != true) return;
    await ref
        .read(challengeBoardRepositoryProvider)
        .removeMember(board.id, player.id);
    ref.invalidate(challengeBoardDetailProvider(board.id));
    ref.invalidate(challengeBoardsProvider);
  }

  Future<void> _share(BuildContext context, WidgetRef ref, Board board) async {
    final link = await ref
        .read(challengeBoardRepositoryProvider)
        .getInviteLink(board.id);
    if (!context.mounted) return;
    await showShareSheet(
      context,
      boardName: board.name,
      link: link,
      onRegenerate: () => _regenerate(context, ref, board),
    );
  }

  Future<void> _regenerate(
    BuildContext context,
    WidgetRef ref,
    Board board,
  ) async {
    final confirmed = await showRegenerateDialog(context);
    if (confirmed != true) return;
    final link = await ref
        .read(challengeBoardRepositoryProvider)
        .regenerateInvite(board.id);
    if (!context.mounted) return;
    await showShareSheet(context, boardName: board.name, link: link);
  }

  Future<void> _leave(BuildContext context, WidgetRef ref, Board board) async {
    final confirmed = await showLeaveDialog(context, board.name);
    if (confirmed != true) return;
    await ref.read(challengeBoardRepositoryProvider).leaveBoard(board.id);
    ref.invalidate(challengeBoardsProvider);
    if (context.mounted) context.pop();
  }
}
