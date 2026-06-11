import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Center confirmation dialog. Names the consequence; primary action is the
/// affirmative, destructive variant uses actionDestructive.
Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.dialogScrim(context),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.dialogSurface(ctx),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 18,
                color: AppColors.onSurface1(ctx),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onSurface2(ctx)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.onSurface2(ctx)),
                  ),
                ),
                const SizedBox(width: 6),
                if (destructive)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.actionDestructive(ctx),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(confirmLabel),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(confirmLabel),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// 5 · Regenerate invite link.
Future<bool?> showRegenerateDialog(BuildContext context) => _confirm(
      context,
      title: 'Regenerate invite link?',
      body:
          'The current link will stop working immediately. You’ll need to share the new link with anyone who hasn’t joined yet.',
      confirmLabel: 'Regenerate',
    );

/// Reset recovery code (rotate the recovery secret).
Future<bool?> showResetRecoveryDialog(BuildContext context) => _confirm(
      context,
      title: 'Reset recovery code?',
      body:
          'This creates a new code for restoring your boards on another device. '
          'Any device still using the old code will need to reconnect. Your '
          'boards and stats are not affected.',
      confirmLabel: 'Reset code',
    );

/// Remove a member (destructive, owner-only).
Future<bool?> showRemoveMemberDialog(
  BuildContext context, {
  required String playerName,
  required String boardName,
}) =>
    _confirm(
      context,
      title: 'Remove $playerName?',
      body:
          '$playerName will be removed from $boardName. They can rejoin with a valid invite link — regenerate the link to keep them out.',
      confirmLabel: 'Remove',
      destructive: true,
    );

/// 6 · Leave board (destructive).
Future<bool?> showLeaveDialog(BuildContext context, String boardName) =>
    _confirm(
      context,
      title: 'Leave $boardName?',
      body:
          'You’ll lose your standing in this board and need a new invite to rejoin. This won’t affect your lifetime stats.',
      confirmLabel: 'Leave board',
      destructive: true,
    );
