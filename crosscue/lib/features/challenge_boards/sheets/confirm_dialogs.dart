// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Center confirmation dialog. Names the consequence; primary action is the
/// affirmative, destructive variant uses actionDestructive.
Future<bool?> _confirm(BuildContext context,
    {required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false}) {
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
              Text(title,
                  style: AppTextStyles.titleMedium.copyWith(
                      fontSize: 18, color: AppColors.onSurface1(ctx))),
              const SizedBox(height: 8),
              Text(body,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.onSurface2(ctx))),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel',
                        style: TextStyle(color: AppColors.onSurface2(ctx)))),
                const SizedBox(width: 6),
                if (destructive)
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.actionDestructive(ctx),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 18)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(confirmLabel))
                else
                  FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 18)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(confirmLabel)),
              ]),
            ]),
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
