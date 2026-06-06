// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Two-option segmented control (This week / Lifetime). Selected pill uses
/// surface over segmentedControlBg; announces selected state for a11y.
class CbSegmented extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const CbSegmented(
      {super.key,
      required this.options,
      required this.selectedIndex,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.segmentedControlBg(context),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(children: [
        for (int i = 0; i < options.length; i++)
          Expanded(
            child: Semantics(
              selected: i == selectedIndex,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.surface(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: i == selectedIndex && !dark
                        ? const [
                            BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 2,
                                offset: Offset(0, 1))
                          ]
                        : null,
                  ),
                  child: Text(options[i],
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: i == selectedIndex
                              ? AppColors.primary(context)
                              : AppColors.onSurface2(context))),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
