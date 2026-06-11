import 'package:flutter/material.dart';

/// Crosscue · Preset avatars.
///
/// Ten theme-independent cartoon "looks", indexed 1..10 — an emoji glyph on
/// a fixed pastel disc. Discs are theme-independent so a chosen look never
/// shifts between light and dark.
///
/// The look index is what is stored and synced (`avatar_silhouette_look` on
/// the server, clamped 1..10 there) — reordering or repurposing an index
/// changes the avatar of every player who picked it, so only ever append.
class PresetAvatarSpec {
  final String emoji;
  final Color bg;
  final String label;
  const PresetAvatarSpec(this.emoji, this.bg, this.label);
}

const List<PresetAvatarSpec> kPresetAvatars = [
  PresetAvatarSpec('🍣', Color(0xFFFFE3E0), 'Sushi'), // 1 · soft coral
  PresetAvatarSpec('🥟', Color(0xFFFFEFD1), 'Ravioli'), // 2 · warm cream
  PresetAvatarSpec('🌈', Color(0xFFE2F4FF), 'Rainbow'), // 3 · sky
  PresetAvatarSpec('🥳', Color(0xFFFFE8F4), 'Party hat'), // 4 · pink
  PresetAvatarSpec('🍭', Color(0xFFF3E6FF), 'Lollipop'), // 5 · lilac
  PresetAvatarSpec('🎡', Color(0xFFE0F7EE), 'Ferris wheel'), // 6 · mint
  PresetAvatarSpec('🐱', Color(0xFFFFF3C9), 'Cat'), // 7 · butter
  PresetAvatarSpec('🐶', Color(0xFFEDEAFF), 'Dog'), // 8 · periwinkle
  PresetAvatarSpec('🐰', Color(0xFFE8F8D8), 'Rabbit'), // 9 · leaf
  PresetAvatarSpec('🐧', Color(0xFFDDF1FA), 'Penguin'), // 10 · ice
];

/// A preset avatar disc at any size. Out-of-range looks render look 1 so a
/// value from a newer app version degrades gracefully instead of throwing.
class PresetAvatar extends StatelessWidget {
  final int look; // 1..kPresetAvatars.length
  final double size;
  const PresetAvatar({super.key, this.look = 1, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final spec = kPresetAvatars[
        (look >= 1 && look <= kPresetAvatars.length) ? look - 1 : 0];
    return Semantics(
      label: '${spec.label} avatar',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: spec.bg, shape: BoxShape.circle),
        child: Text(
          spec.emoji,
          // The glyph is decorative artwork: it keeps its proportions under
          // system text scaling rather than overflowing the disc.
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontSize: size * 0.52, height: 1),
        ),
      ),
    );
  }
}
