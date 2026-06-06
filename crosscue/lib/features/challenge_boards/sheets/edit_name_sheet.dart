// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import '../avatar/player_avatar.dart';
import '../models/challenge_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../util/display_name_validator.dart';
import 'board_sheets.dart' show showCbSheet;

/// 7 · Edit display name. Single field, live 10-char counter, validation
/// against the allowed character set. Save is disabled while offline and
/// while the value is invalid.
Future<String?> showEditNameSheet(
  BuildContext context, {
  required String initial,
  PlayerAvatar currentAvatar = const PlayerAvatar.initials(),
  bool offline = false,
  Future<PlayerAvatar?> Function()? onChangeAvatar,
}) {
  final controller = TextEditingController(text: initial);
  var avatar = currentAvatar;
  return showCbSheet<String>(context, title: 'Profile', builder: (ctx) {
    return StatefulBuilder(builder: (ctx, setState) {
      final raw = controller.text;
      final error = DisplayNameValidator.validate(raw);
      final canSave = !offline && error == null;
      final count = DisplayNameValidator.counter(raw);

      return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onChangeAvatar != null) ...[
              Center(
                child: Semantics(
                  button: true,
                  label: 'Change avatar',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () async {
                      final next = await onChangeAvatar();
                      if (next == null) return;
                      setState(() => avatar = next);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PlayerAvatarView(
                          avatar: avatar,
                          name: raw.trim().isEmpty ? initial : raw,
                          size: 84,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary(ctx),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.dialogSurface(ctx),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              size: 16,
                              color: Theme.of(ctx).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: ChallengeLimits.displayNameMaxLen,
              onChanged: (_) => setState(() {}),
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              decoration: InputDecoration(
                hintText: 'Your name',
                errorText: error,
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 1,
                    child: Text('$count/${ChallengeLimits.displayNameMaxLen}',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: count > ChallengeLimits.displayNameMaxLen
                                ? AppColors.incorrect(ctx)
                                : AppColors.onSurface3(ctx))),
                  ),
                ),
              ),
            ),
            if (error == null && !offline)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    'Up to ${ChallengeLimits.displayNameMaxLen} characters. Shown to other players on your boards.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.onSurface3(ctx))),
              ),
            const SizedBox(height: 18),
            FilledButton(
                onPressed:
                    canSave ? () => Navigator.pop(ctx, raw.trim()) : null,
                child: const Text('Save')),
            const SizedBox(height: 4),
            if (offline)
              Row(children: [
                Icon(Icons.cloud_off_rounded,
                    size: 14, color: const Color(0xFFFF9800)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        'Saving is unavailable offline. Reconnect to update your name.',
                        style: AppTextStyles.caption
                            .copyWith(color: const Color(0xFFFF9800)))),
              ])
            else
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: TextStyle(color: AppColors.onSurface2(ctx)))),
          ]);
    });
  });
}
