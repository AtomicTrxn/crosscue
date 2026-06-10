import 'dart:async';
import 'dart:typed_data';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/challenge_boards/data/repositories/api_challenge_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/providers/challenge_board_providers.dart';
import 'package:crosscue/features/challenge_boards/presentation/screens/challenge_tab_screen.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/avatar_picker_sheet.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/board_sheets.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/confirm_dialogs.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/edit_name_sheet.dart';
import 'package:crosscue/features/challenge_boards/util/invite_link.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChallengeBoardsScreen extends ConsumerStatefulWidget {
  const ChallengeBoardsScreen({super.key, this.pendingInvite});

  /// When set (an invite deep link routed here), the join flow auto-launches
  /// for this invite on first build. See `util/invite_link.dart`.
  final InviteLink? pendingInvite;

  @override
  ConsumerState<ChallengeBoardsScreen> createState() =>
      _ChallengeBoardsScreenState();
}

class _ChallengeBoardsScreenState extends ConsumerState<ChallengeBoardsScreen> {
  @override
  void initState() {
    super.initState();
    final invite = widget.pendingInvite;
    if (invite != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            _previewAndJoin(context, ref, invite.toShareUri().toString()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final boards = ref.watch(challengeBoardsProvider);
    final profile = ref.watch(challengeProfileProvider);
    final lifetime = ref.watch(challengeLifetimeProvider);

    return ChallengeTabScreen(
      boards: boards.when(
        data: (data) => Loadable.data(data),
        error: (_, __) => const Loadable.error(),
        loading: () => const Loadable.loading(),
      ),
      me: profile.when(
        data: (player) => player,
        error: (_, __) => SampleChallengeFallbacks.me,
        loading: () => SampleChallengeFallbacks.me,
      ),
      lifetime: lifetime.when(
        data: (stats) => stats,
        error: (_, __) => SampleChallengeFallbacks.lifetime,
        loading: () => SampleChallengeFallbacks.lifetime,
      ),
      onRefresh: () async {
        ref.invalidate(challengeBoardsProvider);
        ref.invalidate(challengeProfileProvider);
        ref.invalidate(challengeLifetimeProvider);
      },
      onEditName: () => _editName(
        context,
        ref,
        profile.when(
          data: (player) => player,
          error: (_, __) => null,
          loading: () => null,
        ),
      ),
      onCreateOrJoin: () => _showCreateJoin(context, ref),
      onOpenBoard: (board) => context.push(Routes.challengeBoard(board.id)),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    Player? player,
  ) async {
    if (player == null) return;
    // Recovery rotation only applies when a real backend is configured; in
    // sample mode the action is hidden.
    final hasBackend = ref.read(challengeBoardApiProvider) != null;
    final choice = await showEditNameSheet(
      context,
      initial: player.displayName,
      currentAvatar: player.avatar,
      offline: false,
      onResetRecovery: hasBackend ? () => unawaited(_resetRecovery(ref)) : null,
      onChangeAvatar: () async {
        final avatarChoice = await showAvatarPickerSheet(
          context,
          selected: player.avatar.silhouetteLook,
          pickImageBytes: _pickImageBytes,
        );
        if (avatarChoice == null) return null;
        final avatar = avatarChoice.photoBytes != null
            ? PlayerAvatar.photoBytes(avatarChoice.photoBytes)
            : PlayerAvatar.silhouette(avatarChoice.look ?? 1);
        await ref.read(challengeProfileRepositoryProvider).updateAvatar(avatar);
        ref.invalidate(challengeProfileProvider);
        return avatar;
      },
    );
    if (choice == null) return;
    await ref
        .read(challengeProfileRepositoryProvider)
        .updateDisplayName(choice);
    ref.invalidate(challengeProfileProvider);
  }

  Future<void> _resetRecovery(WidgetRef ref) async {
    final confirmed = await showResetRecoveryDialog(context);
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String message;
    try {
      await ref.read(challengeProfileRepositoryProvider).rotateRecovery();
      message = 'Recovery code reset';
    } catch (_) {
      message = 'Could not reset recovery code. Try again.';
    }
    if (!mounted) return;
    // Close the Profile sheet so the result snackbar is visible.
    if (navigator.canPop()) navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCreateJoin(BuildContext context, WidgetRef ref) async {
    final action = await showCbSheet<_CreateJoinAction>(
      context,
      title: 'Challenge board',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Create board'),
            subtitle: const Text('Start a private board for friends'),
            onTap: () => Navigator.pop(ctx, _CreateJoinAction.create),
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('Join with link'),
            subtitle: const Text('Paste an invite from a friend'),
            onTap: () => Navigator.pop(ctx, _CreateJoinAction.join),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case _CreateJoinAction.create:
        await _createBoard(context, ref);
      case _CreateJoinAction.join:
        await _joinBoard(context, ref);
    }
  }

  Future<void> _createBoard(BuildContext context, WidgetRef ref) async {
    final draft = await showCreateBoardSheet(context);
    if (draft == null || draft.name.trim().isEmpty) return;
    final repository = ref.read(challengeBoardRepositoryProvider);
    final created = repository is ApiChallengeRepository
        ? await repository.createBoardWithInvite(draft)
        : null;
    final board = created?.board ?? await repository.createBoard(draft);
    ref.invalidate(challengeBoardsProvider);
    ref.invalidate(challengeLifetimeProvider);
    if (!context.mounted) return;
    final link = created?.inviteLink ??
        await ref
            .read(challengeBoardRepositoryProvider)
            .getInviteLink(board.id);
    if (!context.mounted) return;
    await showShareSheet(
      context,
      boardName: board.name,
      link: link,
      created: true,
      onRegenerate: () {
        unawaited(_regenerateInvite(context, ref, board));
      },
    );
  }

  Future<void> _joinBoard(BuildContext context, WidgetRef ref) async {
    final link = await showJoinSheet(context);
    if (link == null || link.trim().isEmpty) return;
    if (!context.mounted) return;
    await _previewAndJoin(context, ref, link.trim());
  }

  /// Shared preview → confirm → join, used both by the "Join with link" sheet
  /// and by an invite deep link that pre-supplies [link].
  Future<void> _previewAndJoin(
    BuildContext context,
    WidgetRef ref,
    String link,
  ) async {
    final repo = ref.read(challengeBoardRepositoryProvider);
    final preview = await repo.previewInvite(link);
    if (!context.mounted) return;
    final shouldJoin = await showInviteSheet(context, preview);
    if (shouldJoin != true) return;
    final board = await repo.joinInvite(link);
    ref.invalidate(challengeBoardsProvider);
    ref.invalidate(challengeLifetimeProvider);
    if (context.mounted && board != null) {
      unawaited(context.push(Routes.challengeBoard(board.id)));
    }
  }

  Future<void> _regenerateInvite(
    BuildContext context,
    WidgetRef ref,
    Board board,
  ) async {
    final link = await ref
        .read(challengeBoardRepositoryProvider)
        .regenerateInvite(board.id);
    if (!context.mounted) return;
    await showShareSheet(context, boardName: board.name, link: link);
  }

  Future<Uint8List?> _pickImageBytes() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    return result?.files.single.bytes;
  }
}

enum _CreateJoinAction { create, join }

abstract final class SampleChallengeFallbacks {
  static const me = Player(
    id: 'me',
    displayName: 'Maya',
    avatar: PlayerAvatar.silhouette(1),
    isMe: true,
  );

  static const lifetime = LifetimeStats(
    avgClean: '—',
    cleanSolves: 0,
    bestClean: '—',
    rankingStatus: 'Solve 5 clean puzzles to unlock lifetime ranking',
    weeksCounted: 0,
  );
}
