// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import 'theme/app_colors.dart';

/// Crosscue · Challenge Boards palette helpers.
///
/// Adds **no new color tokens** — every value resolves to an existing
/// Color Guide v3.5 token (see AppColors). These are convenience accessors
/// for roles specific to the Challenge feature, plus the three fixed
/// avatar silhouette palettes (theme-independent by design).
abstract final class ChallengePalette {
  // ── Rank chip ───────────────────────────────────────────────────────
  /// Default rank pill background = primaryContainer.
  static Color rankChipBg(BuildContext c) => AppColors.primaryContainer(c);

  /// Default rank pill text = primary.
  static Color rankChipFg(BuildContext c) => AppColors.primary(c);

  /// First-place tint reuses the shared warm accent (streakAccent / difficultyHard).
  static const Color firstPlace = AppColors.streakAccent; // #FF9800
  /// First-place pill background — 15% streakAccent over the surface.
  static Color firstPlaceChipBg(BuildContext c) => firstPlace.withOpacity(0.15);

  // ── Card surfaces ───────────────────────────────────────────────────
  /// Quiet (secondary) card border = divider.
  static Color quietBorder(BuildContext c) => AppColors.divider(c);

  /// Primary card shadow. Light: soft drop; Dark: deeper, no ambient tint.
  static List<BoxShadow> cardShadow(BuildContext c) {
    final dark = Theme.of(c).brightness == Brightness.dark;
    return dark
        ? const [
            BoxShadow(
                color: Color(0x73000000), blurRadius: 8, offset: Offset(0, 2))
          ]
        : const [
            BoxShadow(
                color: Color(0x17000000), blurRadius: 4, offset: Offset(0, 1)),
            BoxShadow(color: Color(0x0A000000), blurRadius: 0, spreadRadius: 1),
          ];
  }

  /// Status-banner tints.
  static Color bannerInfoBg(BuildContext c) => AppColors.primaryContainer(c);
  static Color bannerWarnBg(BuildContext c) => firstPlace.withOpacity(0.13);
  static Color bannerErrorBg(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0x1FE89691)
          : const Color(0xFFFBEAEA);
  static Color bannerOfflineBg(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF1B2030)
          : const Color(0xFFF1F3F5);
}

/// One fixed silhouette identity (theme-independent — an avatar looks the
/// same in light and dark so a chosen look never shifts).
class SilhouettePalette {
  final Color bg;
  final Color fig;
  final Color accent;
  const SilhouettePalette(this.bg, this.fig, this.accent);
}

/// The three preset "looks", indexed 1..3 (see avatar/silhouette_painter.dart).
const List<SilhouettePalette> kSilhouettePalettes = [
  SilhouettePalette(Color(0xFFDCEBFF), Color(0xFF1E6FD0),
      Color(0xFF10538F)), // 1 · blue · headphones
  SilhouettePalette(Color(0xFFFFE6C2), Color(0xFFE08900),
      Color(0xFFA85F00)), // 2 · warm · cap
  SilhouettePalette(Color(0xFF16294E), Color(0xFF8FC0FF),
      Color(0xFFC9DEFF)), // 3 · navy · top-knot
];
