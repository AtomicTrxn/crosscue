import 'package:crosscue/features/challenge_boards/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Primary app tab bar. Challenge replaces Archive in slot 2.
/// (Archive moves to Settings — see README.)
enum CbTab { today, challenge, stats, settings }

class ChallengeBottomNav extends StatelessWidget {
  final CbTab active;
  final ValueChanged<CbTab>? onSelect;
  const ChallengeBottomNav({
    super.key,
    this.active = CbTab.challenge,
    this.onSelect,
  });

  static const _items = <(CbTab, IconData, IconData, String)>[
    (CbTab.today, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Today'),
    (
      CbTab.challenge,
      Icons.emoji_events_rounded,
      Icons.emoji_events_outlined,
      'Challenge'
    ),
    (CbTab.stats, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Stats'),
    (
      CbTab.settings,
      Icons.settings_rounded,
      Icons.settings_outlined,
      'Settings'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(top: BorderSide(color: AppColors.divider(context))),
      ),
      child: Row(
        children: [
          for (final (tab, on, off, label) in _items)
            Expanded(
              child: InkWell(
                onTap: () => onSelect?.call(tab),
                child: _NavItem(
                  icon: tab == active ? on : off,
                  label: label,
                  color: tab == active
                      ? AppColors.primary(context)
                      : AppColors.onSurface3(context),
                  bold: tab == active,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool bold;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bold,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 21, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 10,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.2,
            color: color,
          ),
        ),
      ],
    );
  }
}
