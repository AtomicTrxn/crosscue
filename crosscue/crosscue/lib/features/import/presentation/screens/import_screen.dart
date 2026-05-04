import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../notifiers/import_notifier.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importProvider);

    // Listen for success / errors to show feedback then navigate/dismiss.
    ref.listen<ImportState>(importProvider, (prev, next) {
      if (next is ImportSuccess) {
        _showSuccessAndNavigate(next);
      } else if (next is ImportDuplicate) {
        _showDuplicateSheet(next.fileName);
      } else if (next is ImportFailure) {
        _showErrorSheet(next.message);
      }
    });

    final isLoading =
        importState is ImportPicking || importState is ImportParsing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Puzzle'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_open_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Import a crossword puzzle',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Supports .puz and .ipuz file formats.\nPuzzles are stored locally on your device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            if (importState is ImportParsing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Importing "${importState.fileName}"…',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(importProvider.notifier)
                        .pickAndImport(),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open),
                label: const Text('Choose File'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSuccessAndNavigate(ImportSuccess state) {
    // Invalidate the home list so it refreshes when we navigate there.
    ref.invalidate(puzzleListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported "${state.title}" successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Reset state then pop back to home
    ref.read(importProvider.notifier).reset();
    if (mounted) context.go(Routes.home);
  }

  void _showDuplicateSheet(String fileName) {
    ref.read(importProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _InfoSheet(
        icon: Icons.copy_outlined,
        title: 'Already imported',
        message:
            '"$fileName" is already in your library. Each puzzle can only be imported once.',
        actionLabel: 'Got it',
        onAction: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showErrorSheet(String message) {
    ref.read(importProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _InfoSheet(
        icon: Icons.error_outline,
        title: 'Import failed',
        message: message,
        actionLabel: 'Dismiss',
        onAction: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
