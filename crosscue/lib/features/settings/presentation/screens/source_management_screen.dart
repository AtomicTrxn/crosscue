import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';
import 'package:crosscue/features/import/presentation/providers/source_registry_provider.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';

class SourceManagementScreen extends ConsumerWidget {
  const SourceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(sourceRegistryProvider);
    final sources = registry.allSources;
    final enabledSources = registry.enabledSources;

    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle sources')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionHeader('Import'),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Import local file'),
            subtitle: const Text('.puz and .ipuz files stay on this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.import_),
          ),
          const Divider(),
          const _SectionHeader('Sources'),
          if (sources.isEmpty)
            const ListTile(
              leading: Icon(Icons.source_outlined),
              title: Text('No sources configured'),
              subtitle: Text('Local file import is always available.'),
            )
          else
            for (final source in sources) _SourceTile(source: source),
          const Divider(),
          const _SectionHeader('Future downloads'),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Licensed online sources'),
            subtitle: Text(
              enabledSources.length <= 1
                  ? 'No rights-cleared online source is configured yet.'
                  : 'Only rights-cleared sources can be enabled.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CrosscueSpacing.screenH,
              8,
              CrosscueSpacing.screenH,
              24,
            ),
            child: Text(
              'Crosscue only enables user imports or sources with explicit '
              'permission or open-license terms. Sources pending review stay '
              'disabled until cleared.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source});

  final PuzzleSource source;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = source.licenseStatus;
    final enabled = source.enabled &&
        status != LicenseStatus.needsReview &&
        status != LicenseStatus.prohibited;

    return ListTile(
      leading: Icon(
        enabled ? Icons.check_circle_outline : Icons.block_outlined,
        color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(source.displayName),
      subtitle: Text(_statusText(source)),
      trailing: Chip(
        label: Text(_statusLabel(status)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _statusText(PuzzleSource source) {
    return switch (source.licenseStatus) {
      LicenseStatus.userImport => 'User-selected files only',
      LicenseStatus.explicitPermission => 'Enabled by explicit permission',
      LicenseStatus.openLicense => 'Enabled by open-license terms',
      LicenseStatus.needsReview => 'Disabled until legal review is complete',
      LicenseStatus.prohibited => 'Blocked by source policy',
    };
  }

  String _statusLabel(LicenseStatus status) {
    return switch (status) {
      LicenseStatus.userImport => 'Local',
      LicenseStatus.explicitPermission => 'Permitted',
      LicenseStatus.openLicense => 'Open',
      LicenseStatus.needsReview => 'Review',
      LicenseStatus.prohibited => 'Blocked',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

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
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
