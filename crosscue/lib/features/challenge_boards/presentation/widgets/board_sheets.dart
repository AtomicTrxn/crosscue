import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Shared bottom-sheet chrome: drag handle, title, close button.
Future<T?> showCbSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.dialogSurface(context),
    barrierColor: AppColors.dialogScrim(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 19,
                      color: AppColors.onSurface1(ctx),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.background(ctx),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.onSurface2(ctx),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            builder(ctx),
          ],
        ),
      ),
    ),
  );
}

Widget _caption(
  BuildContext c,
  IconData icon,
  String text, {
  bool warn = false,
}) {
  final color = warn ? const Color(0xFFFF9800) : AppColors.onSurface3(c);
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(color: color, height: 1.45),
          ),
        ),
      ],
    ),
  );
}

/// 1 · Create board.
Future<CreateBoardDraft?> showCreateBoardSheet(BuildContext context) {
  final controller = TextEditingController();
  var rankingMode = ChallengeRankingMode.averageTime;
  return showCbSheet<CreateBoardDraft>(
    context,
    title: 'Create a board',
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final value = controller.text.trim();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 30,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Board name',
                  counterText: '',
                ),
              ),
              _caption(
                ctx,
                Icons.group_outlined,
                'You and up to ${ChallengeLimits.maxPlayersPerBoard} friends. You can be in ${ChallengeLimits.maxBoardsPerPlayer} boards at once.',
              ),
              const SizedBox(height: 14),
              Text(
                'Rank players by',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurface2(ctx),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ChallengeRankingMode.values)
                    ChoiceChip(
                      label: Text(mode.label),
                      selected: rankingMode == mode,
                      onSelected: (_) => setState(() => rankingMode = mode),
                    ),
                ],
              ),
              _caption(
                ctx,
                Icons.timer_outlined,
                'Only Crosshare Daily Mini puzzles published during the current UTC week count.',
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: value.isEmpty
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          CreateBoardDraft(
                            name: value,
                            rankingMode: rankingMode,
                          ),
                        ),
                child: const Text('Create board'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// 2 · Join via invite link.
Future<String?> showJoinSheet(BuildContext context) {
  final controller = TextEditingController();
  return showCbSheet<String>(
    context,
    title: 'Join a board',
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final value = controller.text.trim();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration:
                    const InputDecoration(hintText: 'Paste invite link'),
              ),
              _caption(
                ctx,
                Icons.link_rounded,
                'Ask a friend for their board’s invite link.',
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed:
                    value.isEmpty ? null : () => Navigator.pop(ctx, value),
                child: const Text('Join board'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// 3 · Invite preview / confirm — resolves to whichever state applies.
Future<bool?> showInviteSheet(BuildContext context, InvitePreview preview) {
  return showCbSheet<bool>(
    context,
    title: preview.result == InviteResult.alreadyMember
        ? 'You’re in this board'
        : preview.result == InviteResult.boardDeleted
            ? 'Board unavailable'
            : preview.result == InviteResult.offline
                ? 'Connect to join'
                : preview.result == InviteResult.networkError
                    ? 'Couldn’t check invite'
                    : preview.result == InviteResult.invalidOrExpired
                        ? 'Invite unavailable'
                        : 'Join this board?',
    builder: (ctx) {
      if (preview.result == InviteResult.invalidOrExpired ||
          preview.result == InviteResult.boardDeleted ||
          preview.result == InviteResult.offline ||
          preview.result == InviteResult.networkError) {
        final message = switch (preview.result) {
          InviteResult.boardDeleted => (
              title: 'This board no longer exists',
              body:
                  'The final member may have left. Ask your friend to create a new board.'
            ),
          InviteResult.offline => (
              title: 'You’re offline',
              body: 'Reconnect to preview and join this private board.'
            ),
          InviteResult.networkError => (
              title: 'Couldn’t check this link',
              body: 'Try again in a moment. Your boards are unchanged.'
            ),
          _ => (
              title: 'This link has expired or is invalid',
              body:
                  'Invite links expire after ${ChallengeLimits.inviteExpiryDays} days. Ask a friend to share a fresh one.'
            ),
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _errorBlock(ctx, message.title, message.body),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Done'),
            ),
          ],
        );
      }

      final cfg = switch (preview.result) {
        InviteResult.valid => (
            label: 'Join board',
            enabled: true,
            icon: Icons.schedule_rounded,
            cap:
                'Invite expires in ${preview.daysUntilExpiry} days · anyone with the link can join',
            warn: false
          ),
        InviteResult.boardFull => (
            label: 'Board is full',
            enabled: false,
            icon: Icons.group_outlined,
            cap:
                'This board has ${ChallengeLimits.maxPlayersPerBoard} of ${ChallengeLimits.maxPlayersPerBoard} players. Ask the owner to make room.',
            warn: true
          ),
        InviteResult.alreadyMember => (
            label: 'Go to board',
            enabled: true,
            icon: Icons.check_rounded,
            cap: 'You’re already a member of this board.',
            warn: false
          ),
        InviteResult.playerLimitReached => (
            label: 'Join board',
            enabled: false,
            icon: Icons.error_outline_rounded,
            cap:
                'You’re in ${ChallengeLimits.maxBoardsPerPlayer} of ${ChallengeLimits.maxBoardsPerPlayer} boards. Leave one to join a new board.',
            warn: true
          ),
        _ => (
            label: 'Join board',
            enabled: true,
            icon: Icons.schedule_rounded,
            cap: '',
            warn: false
          ),
      };

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _invitePreviewCard(ctx, preview),
          _caption(ctx, cfg.icon, cfg.cap, warn: cfg.warn),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: cfg.enabled ? () => Navigator.pop(ctx, true) : null,
            child: Text(cfg.label),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
        ],
      );
    },
  );
}

/// 4 · Share invite (also the post-create state).
Future<void> showShareSheet(
  BuildContext context, {
  required String boardName,
  required String link,
  bool created = false,
  VoidCallback? onRegenerate,
}) {
  return showCbSheet<void>(
    context,
    title: created ? 'Board created' : 'Invite to $boardName',
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (created)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AppColors.correct(ctx),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '“$boardName” is ready. Invite friends to start.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.onSurface2(ctx)),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            height: 50,
            padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
            decoration: BoxDecoration(
              color: AppColors.background(ctx),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider(ctx)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 17,
                  color: AppColors.onSurface3(ctx),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontFamily: 'RobotoMono',
                      color: AppColors.onSurface2(ctx),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: link)),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer(ctx),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: AppColors.primary(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _caption(
            ctx,
            Icons.schedule_rounded,
            'Anyone with this link can join. Expires in ${ChallengeLimits.inviteExpiryDays} days.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: link, subject: 'Join my Crosscue board'),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share link'),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Clipboard.setData(ClipboardData(text: link)),
                child: const Text('Copy link'),
              ),
              TextButton(
                onPressed: onRegenerate,
                child: Text(
                  'Regenerate',
                  style: TextStyle(color: AppColors.onSurface2(ctx)),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Widget _invitePreviewCard(BuildContext c, InvitePreview p) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.background(c),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider(c)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer(c),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            size: 24,
            color: AppColors.primary(c),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.boardName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium
                    .copyWith(fontSize: 16, color: AppColors.onSurface1(c)),
              ),
              const SizedBox(height: 2),
              Text(
                '${p.playerCount} players · invite-only',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.onSurface2(c)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _errorBlock(BuildContext c, String title, String body) {
  return Column(
    children: [
      Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.incorrect(c).withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error_outline_rounded,
          size: 24,
          color: AppColors.incorrect(c),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        title,
        textAlign: TextAlign.center,
        style: AppTextStyles.titleMedium
            .copyWith(fontSize: 15, color: AppColors.onSurface1(c)),
      ),
      const SizedBox(height: 6),
      Text(
        body,
        textAlign: TextAlign.center,
        style:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurface2(c)),
      ),
    ],
  );
}
