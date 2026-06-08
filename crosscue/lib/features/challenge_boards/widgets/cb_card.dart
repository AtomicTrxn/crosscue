import 'package:crosscue/features/challenge_boards/challenge_palette.dart';
import 'package:crosscue/features/challenge_boards/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Card container. [quiet] = bordered, no shadow (secondary surfaces like the
/// Lifetime card); default = elevated surface with the Challenge card shadow.
class CbCard extends StatelessWidget {
  final Widget child;
  final bool quiet;
  final EdgeInsets padding;
  const CbCard({
    super.key,
    required this.child,
    this.quiet = false,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: quiet
            ? Border.all(color: ChallengePalette.quietBorder(context))
            : null,
        boxShadow: quiet ? null : ChallengePalette.cardShadow(context),
      ),
      child: child,
    );
  }
}
