import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';
import 'package:crosscue/features/import/presentation/providers/source_registry_provider.dart';

class SourceManagementScreen extends ConsumerWidget {
  const SourceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(sourceRegistryProvider);
    final sources = registry.allSources;
    final localSources = sources.where((source) => source.id == 'local_import');
    final communitySources =
        sources.where((source) => source.id != 'local_import');

    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle sources')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionHeader('Sources'),
          if (localSources.isEmpty)
            const ListTile(
              leading: Icon(Icons.source_outlined),
              title: Text('No sources configured'),
              subtitle: Text('Local file import is always available.'),
            )
          else
            for (final source in localSources) _SourceTile(source: source),
          const Divider(),
          const _SectionHeader('Community Crosswords'),
          for (final source in communitySources) _SourceTile(source: source),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('Source review checklist'),
            subtitle: const Text(
              'Required before any online source can be enabled',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showReviewChecklist(context),
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

  void _showReviewChecklist(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Source review checklist'),
        content: const Text(
          'Sources need reviewed terms, attribution, commercial-use, and cache policy before downloads are enabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final PuzzleSource source;

  const _SourceTile({required this.source});

  String _statusLabel(LicenseStatus status) {
    return switch (status) {
      LicenseStatus.userImport => 'Local',
      LicenseStatus.explicitPermission => 'Permitted',
      LicenseStatus.openLicense => 'Open',
      LicenseStatus.needsReview => 'Review',
      LicenseStatus.prohibited => 'Blocked',
    };
  }

  String _statusText(PuzzleSource source) {
    final status = source.licenseStatus;
    final enabled = source.enabled &&
        status != LicenseStatus.needsReview &&
        status != LicenseStatus.prohibited;

    if (source.id == 'local_import') {
      return '.puz and .ipuz files stay on this device';
    }
    if (source.id == 'crosshare_daily_mini') {
      return 'Community source candidate; downloads pending review';
    }

    return status == LicenseStatus.prohibited
        ? 'Blocked${source.enabled ? '; needs review' : ''}'.trim()
        : status == LicenseStatus.needsReview
            ? 'Needs review${source.enabled ? '; disabled for now' : ''}'.trim()
            : enabled
                ? 'All clear'.toUpperCase()
                : 'Disabled manually${status == LicenseStatus.userImport ? '' : ' (review)'}'
                    .trim();
  }

  String _createCompactContent(PuzzleSource source) {
    final enabled = source.enabled &&
        source.licenseStatus != LicenseStatus.needsReview &&
        source.licenseStatus != LicenseStatus.prohibited;
    return 'License: ${_statusLabel(source.licenseStatus)}. Enabled: ${enabled ? 'Yes' : 'No'}.';
  }

  void _showSourceDetails(BuildContext context, PuzzleSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(source.displayName),
        content: Text(_createCompactContent(source)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = source.licenseStatus;
    final enabled = source.enabled &&
        status != LicenseStatus.needsReview &&
        status != LicenseStatus.prohibited;
    final isLocalImport = source.id == 'local_import';

    return ListTile(
      leading: Icon(
        isLocalImport
            ? Icons.folder_open_outlined
            : enabled
                ? Icons.check_circle_outline
                : Icons.block_outlined,
        color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(source.displayName),
      subtitle: Text(_statusText(source)),
      trailing: isLocalImport ? const Icon(Icons.chevron_right) : null,
      onTap: () {
        if (isLocalImport) {
          context.push(Routes.import_);
        } else {
          _showSourceDetails(context, source);
        }
      },
    );
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
