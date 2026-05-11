import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/settings/presentation/widgets/settings_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = asyncSettingValue(
      ref.watch(themeModeProvider),
      fallback: AppThemeMode.system,
    );
    final appVersion = ref.watch(appVersionProvider).when(
          data: (v) => v,
          loading: () => null,
          error: (_, __) => null,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Appearance ─────────────────────────────────────────────────────
          const SettingsSectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CrosscueSpacing.screenH,
              8,
              CrosscueSpacing.screenH,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setMode(selection.first);
                  },
                ),
              ],
            ),
          ),
          const SettingsRowDivider(),
          SettingsSwitchRow(
            value: asyncSettingValue(
                  ref.watch(colorblindModeProvider),
                  fallback: ColorblindMode.none,
                ) !=
                ColorblindMode.none,
            onChanged: (_) =>
                ref.read(colorblindModeProvider.notifier).toggle(),
            leading: Icons.contrast_outlined,
            title: 'Colorblind mode',
            subtitle: 'Adds a dot to correct letters',
          ),

          // ── Touch & Sound ──────────────────────────────────────────────────
          const SettingsSectionHeader('Touch & Sound'),
          SettingsSwitchRow(
            value: asyncSettingValue(
              ref.watch(hapticsEnabledProvider),
              fallback: true,
            ),
            onChanged: (_) =>
                ref.read(hapticsEnabledProvider.notifier).toggle(),
            leading: Icons.vibration_outlined,
            title: 'Haptic feedback',
            subtitle: 'Vibrate on cell tap and puzzle events',
          ),
          SettingsSwitchRow(
            value: asyncSettingValue(
              ref.watch(soundsEnabledProvider),
              fallback: false,
            ),
            onChanged: (_) => ref.read(soundsEnabledProvider.notifier).toggle(),
            leading: Icons.volume_up_outlined,
            title: 'Sounds',
            subtitle: 'Play subtle feedback sounds',
          ),
          SettingsSwitchRow(
            value: asyncSettingValue(
              ref.watch(skipFilledCellsProvider),
              fallback: false,
            ),
            onChanged: (_) =>
                ref.read(skipFilledCellsProvider.notifier).toggle(),
            leading: Icons.skip_next_outlined,
            title: 'Skip filled cells',
            subtitle: 'Jump over filled letters while typing',
          ),

          // ── Puzzles ────────────────────────────────────────────────────────
          const SettingsSectionHeader('Puzzles'),
          SettingsNavRow(
            leading: Icons.source_outlined,
            title: 'Puzzle Sources',
            subtitle: 'Import local files and manage sources',
            onTap: () => context.push(Routes.sourceManagement),
          ),

          // ── Privacy & Data ─────────────────────────────────────────────────
          const SettingsSectionHeader('Privacy & Data'),
          SettingsNavRow(
            leading: Icons.security_outlined,
            title: 'Privacy & Data',
            subtitle: 'Crash reporting, export, import and clear data',
            onTap: () => context.push(Routes.privacySettings),
          ),

          // ── Help ───────────────────────────────────────────────────────────
          const SettingsSectionHeader('Help'),
          SettingsNavRow(
            leading: Icons.help_outline,
            title: 'How to play',
            subtitle: 'Replay the onboarding walkthrough',
            onTap: () => context.push(Routes.onboardingReplay),
          ),
          SettingsNavRow(
            leading: Icons.info_outline,
            title: 'About Crosscue',
            subtitle: appVersion,
            onTap: () => _showAboutDialog(context, appVersion),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, String? version) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AboutDialog(version: version),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog({this.version});

  final String? version;

  static const _githubUrl = 'https://github.com/AtomicTrxn/crosscue';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/ic_launcher.png',
              width: 72,
              height: 72,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Crosscue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A clean, offline-first crossword app for Android',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (version != null) ...[
            const SizedBox(height: 10),
            Text(
              version!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: _githubUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GitHub URL copied')),
                );
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text(_githubUrl),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
