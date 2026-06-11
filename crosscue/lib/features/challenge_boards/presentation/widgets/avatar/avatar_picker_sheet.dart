import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_text_styles.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/avatar_crop_sheet.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/preset_avatars.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/board_sheets.dart'
    show showCbSheet;
import 'package:crosscue/features/challenge_boards/util/avatar_normalizer.dart';
import 'package:flutter/material.dart';

/// The result of the avatar flow: either a chosen preset look or normalized
/// photo bytes the caller should upload.
class AvatarChoice {
  final int? look; // 1..kPresetAvatars.length when a preset is chosen
  final Uint8List? photoBytes; // normalized PNG when a photo is used
  const AvatarChoice.look(this.look) : photoBytes = null;
  const AvatarChoice.photo(this.photoBytes) : look = null;
}

/// Avatar picker: preview on top, a scrollable grid of the preset looks with
/// the add-photo tile at the end, and fixed Save/Cancel actions. The sheet
/// occupies roughly half the screen.
///
/// [pickImageBytes] should open the system picker and return raw image bytes
/// (e.g. via `image_picker` → `XFile.readAsBytes()`). Wired by the caller so
/// this package has no plugin dependency.
Future<AvatarChoice?> showAvatarPickerSheet(
  BuildContext context, {
  int selected = 1,
  Future<Uint8List?> Function()? pickImageBytes,
}) {
  var sel = selected.clamp(1, kPresetAvatars.length);
  return showCbSheet<AvatarChoice>(
    context,
    title: 'Choose your avatar',
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> addPhoto() async {
            final bytes = await pickImageBytes?.call();
            if (bytes == null) return;
            final ui.Image src =
                await AvatarNormalizer.decodeImageFromBytes(bytes);
            if (!ctx.mounted) return;
            final png = await showAvatarCropSheet(ctx, source: src);
            if (png != null && ctx.mounted) {
              Navigator.pop(ctx, AvatarChoice.photo(png));
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // preview
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer(ctx),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: PresetAvatar(look: sel, size: 84),
                ),
              ),
              const SizedBox(height: 16),
              // Scrollable looks with the add-photo tile at the end. About
              // two and a half rows: the cut row signals scrollability, and
              // the fixed height keeps the sheet near half the screen
              // without collapsing on short viewports.
              SizedBox(
                height: 200,
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisExtent: 84,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 10,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    for (int look = 1; look <= kPresetAvatars.length; look++)
                      Center(
                        child: _Option(
                          key: ValueKey('avatar-look-$look'),
                          selected: sel == look,
                          onTap: () => setState(() => sel = look),
                          child: PresetAvatar(look: look, size: 54),
                        ),
                      ),
                    Center(
                      child: _Option(
                        key: const ValueKey('avatar-add-photo'),
                        label: 'Add',
                        onTap: addPhoto,
                        child: _AddTile(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.onSurface3(ctx),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pick a look or add your own photo — shown to friends on your boards.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onSurface3(ctx),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, AvatarChoice.look(sel)),
                child: const Text('Save avatar'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.onSurface2(ctx)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _Option extends StatelessWidget {
  final bool selected;
  final String? label;
  final VoidCallback onTap;
  final Widget child;
  const _Option({
    super.key,
    this.selected = false,
    this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    selected ? AppColors.primary(context) : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                if (selected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.dialogSurface(context),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onSurface3(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface(context),
        border: Border.all(
          color: AppColors.onSurface3(context).withValues(alpha: 0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(
        Icons.add_a_photo_outlined,
        size: 22,
        color: AppColors.primary(context),
      ),
    );
  }
}
