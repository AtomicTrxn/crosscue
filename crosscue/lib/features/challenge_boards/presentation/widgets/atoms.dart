import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_text_styles.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/challenge_palette.dart';
import 'package:flutter/material.dart';

/// Section eyebrow: "THIS WEEK" + dim "· UTC".
class Eyebrow extends StatelessWidget {
  final String label;
  final String? suffix;
  const Eyebrow(this.label, {super.key, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelCaps
              .copyWith(color: AppColors.onSurface2(context)),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 5),
          Text(
            suffix!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onSurface3(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Rank pill "#2 /8". First place uses the warm accent tint.
class RankChip extends StatelessWidget {
  final int rank;
  final int? outOf;
  final bool first;
  const RankChip({
    super.key,
    required this.rank,
    this.outOf,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = first
        ? ChallengePalette.firstPlaceChipBg(context)
        : ChallengePalette.rankChipBg(context);
    final fg = first
        ? ChallengePalette.firstPlace
        : ChallengePalette.rankChipFg(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '#$rank',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ).copyWith(color: fg),
          ),
          if (outOf != null)
            Text(
              ' /$outOf',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.65),
              ),
            ),
        ],
      ),
    );
  }
}

/// Big value + small caps label. Accent label uses primary.
class Metric extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  const Metric({
    super.key,
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1,
          ).copyWith(color: AppColors.onSurface1(context)),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: accent
                ? AppColors.primary(context)
                : AppColors.onSurface3(context),
          ),
        ),
      ],
    );
  }
}

/// Freshness footer line.
class FreshnessLine extends StatelessWidget {
  final String text;
  const FreshnessLine(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onSurface3(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}

/// Skeleton placeholder block.
class Skeleton extends StatelessWidget {
  final double width, height, radius;
  const Skeleton({
    super.key,
    required this.width,
    this.height = 12,
    this.radius = 6,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B2030) : const Color(0xFFECEEF1),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

enum BannerTone { info, warn, error, offline }

/// Inline status strip (offline / error / info). Always pairs icon + text —
/// never communicates by color alone.
class StatusBanner extends StatelessWidget {
  final BannerTone tone;
  final IconData icon;
  final String text;
  final Widget? action;
  const StatusBanner({
    super.key,
    required this.tone,
    required this.icon,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    switch (tone) {
      case BannerTone.info:
        bg = ChallengePalette.bannerInfoBg(context);
        fg = AppColors.primary(context);
        break;
      case BannerTone.warn:
        bg = ChallengePalette.bannerWarnBg(context);
        fg = ChallengePalette.firstPlace;
        break;
      case BannerTone.error:
        bg = ChallengePalette.bannerErrorBg(context);
        fg = AppColors.incorrect(context);
        break;
      case BannerTone.offline:
        bg = ChallengePalette.bannerOfflineBg(context);
        fg = AppColors.onSurface2(context);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: tone == BannerTone.offline
                    ? AppColors.onSurface2(context)
                    : fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
