import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/preset_avatars.dart';
import 'package:flutter/material.dart';

/// Crosscue · Player avatar widget.
///
/// Renders, by [PlayerAvatar.kind]:
///   • initials  → tinted disc with the player's initials
///   • silhouette → one of the preset looks (see kPresetAvatars)
///   • photo      → the player's normalized circular image
class PlayerAvatarView extends StatelessWidget {
  final PlayerAvatar avatar;
  final String name;
  final double size;
  const PlayerAvatarView({
    super.key,
    required this.avatar,
    required this.name,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    switch (avatar.kind) {
      case AvatarKind.silhouette:
        return PresetAvatar(look: avatar.silhouetteLook, size: size);
      case AvatarKind.photo:
        return ClipOval(
          child: SizedBox.square(
            dimension: size,
            child: avatar.photoBytes != null
                ? Image.memory(avatar.photoBytes!, fit: BoxFit.cover)
                : avatar.photoUrl == null
                    ? const SizedBox()
                    : Image.network(avatar.photoUrl!, fit: BoxFit.cover),
          ),
        );
      case AvatarKind.initials:
        final initials = _initials(name);
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer(context),
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: size * 0.38,
              letterSpacing: -0.5,
              color: AppColors.primary(context),
            ),
          ),
        );
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((w) => w.isEmpty ? '' : w[0]).join();
    return letters.toUpperCase();
  }
}
