import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shared row widgets
// ---------------------------------------------------------------------------

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          secondary: Icon(leading),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
        const SettingsRowDivider(),
      ],
    );
  }
}

class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData leading;
  final String title;

  /// Subtitle text. When null the subtitle slot is omitted entirely.
  final String? subtitle;
  final VoidCallback onTap;

  /// Optional trailing widget. Defaults to a chevron icon.
  final Widget? trailing;

  /// Optional tint applied to leading icon and title text.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(leading, color: color),
          title: Text(title, style: TextStyle(color: color)),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const SettingsRowDivider(),
      ],
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CrosscueSpacing.screenH,
        CrosscueSpacing.sectionTop,
        CrosscueSpacing.screenH,
        CrosscueSpacing.sectionBot,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.crosscueOnSurface3,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class SettingsRowDivider extends StatelessWidget {
  const SettingsRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: CrosscueSpacing.screenH,
      color: context.crosscueDivider,
    );
  }
}
