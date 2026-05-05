import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/routes.dart';
import '../../domain/models/archive_entry.dart';
import '../providers/archive_providers.dart';

// ---------------------------------------------------------------------------
// Sort / filter enums
// ---------------------------------------------------------------------------

enum _SortOrder { importDate, puzzleDate, title }

enum _FilterMode { all, notStarted, inProgress, completed }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  _SortOrder _sort = _SortOrder.importDate;
  _FilterMode _filter = _FilterMode.all;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final archiveAsync = ref.watch(archiveEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        actions: [
          _SortMenuButton(
            current: _sort,
            onSelected: (s) => setState(() => _sort = s),
          ),
        ],
      ),
      body: archiveAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptyArchive();
          }
          final filtered = _applyFilter(entries, _filter);
          final sorted = _applySort(filtered, _sort);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterChips(
                current: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: sorted.isEmpty
                    ? const _EmptyFilter()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sorted.length,
                        itemBuilder: (ctx, i) => _ArchiveTile(
                          entry: sorted[i],
                          onDelete: () => _confirmDelete(ctx, sorted[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter / sort
  // ---------------------------------------------------------------------------

  static List<ArchiveEntry> _applyFilter(
      List<ArchiveEntry> entries, _FilterMode filter) {
    return switch (filter) {
      _FilterMode.all => entries,
      _FilterMode.notStarted =>
        entries.where((e) => e.isNotStarted).toList(),
      _FilterMode.inProgress =>
        entries.where((e) => e.isInProgress).toList(),
      _FilterMode.completed =>
        entries.where((e) => e.isCompleted || e.isRevealed).toList(),
    };
  }

  static List<ArchiveEntry> _applySort(
      List<ArchiveEntry> entries, _SortOrder sort) {
    final copy = List<ArchiveEntry>.from(entries);
    switch (sort) {
      case _SortOrder.importDate:
        copy.sort((a, b) => b.importedAt.compareTo(a.importedAt));
      case _SortOrder.puzzleDate:
        copy.sort((a, b) {
          final aDate = a.publishDate ?? a.importedAt;
          final bDate = b.publishDate ?? b.importedAt;
          return bDate.compareTo(aDate);
        });
      case _SortOrder.title:
        copy.sort((a, b) => a.title.compareTo(b.title));
    }
    return copy;
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(BuildContext context, ArchiveEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete puzzle?'),
        content: Text(
          'Delete "${entry.title}" and all solve history? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(archiveRepositoryProvider)
        .deletePuzzle(entry.puzzleId);
    ref.invalidate(archiveEntriesProvider);
  }
}

// ---------------------------------------------------------------------------
// Sort menu button
// ---------------------------------------------------------------------------

class _SortMenuButton extends StatelessWidget {
  const _SortMenuButton({required this.current, required this.onSelected});

  final _SortOrder current;
  final void Function(_SortOrder) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortOrder>(
      tooltip: 'Sort by',
      icon: const Icon(Icons.sort),
      initialValue: current,
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _SortOrder.importDate,
          child: Text('Import date'),
        ),
        PopupMenuItem(
          value: _SortOrder.puzzleDate,
          child: Text('Puzzle date'),
        ),
        PopupMenuItem(
          value: _SortOrder.title,
          child: Text('Title (A–Z)'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips
// ---------------------------------------------------------------------------

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onSelected});

  final _FilterMode current;
  final void Function(_FilterMode) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _FilterMode.values
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(f)),
                    selected: current == f,
                    onSelected: (_) => onSelected(f),
                  ),
                ))
            .toList(),
      ),
    );
  }

  static String _filterLabel(_FilterMode f) => switch (f) {
        _FilterMode.all => 'All',
        _FilterMode.notStarted => 'Not Started',
        _FilterMode.inProgress => 'In Progress',
        _FilterMode.completed => 'Completed',
      };
}

// ---------------------------------------------------------------------------
// Archive tile
// ---------------------------------------------------------------------------

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({required this.entry, required this.onDelete});

  final ArchiveEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _StatusIcon(entry: entry),
      title: Text(
        entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _subtitle(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          context.push(Routes.solveFor(Uri.encodeComponent(entry.puzzleId))),
      onLongPress: onDelete,
    );
  }

  String _subtitle(BuildContext context) {
    final parts = <String>[];

    // Source / dimensions
    final dateStr = _puzzleDateLabel(entry);
    if (dateStr != null) parts.add(dateStr);
    parts.add(entry.sizeLabel);

    // Status
    if (entry.isNotStarted) {
      parts.add('Not started');
    } else if (entry.isInProgress) {
      final t = entry.elapsedMs != null ? _formatMs(entry.elapsedMs!) : '';
      parts.add('In progress${t.isNotEmpty ? ' · $t elapsed' : ''}');
    } else if (entry.isCompleted) {
      final t = entry.elapsedMs != null ? _formatMs(entry.elapsedMs!) : '';
      parts.add('Completed${t.isNotEmpty ? ' · $t' : ''}');
    } else if (entry.isRevealed) {
      parts.add('Revealed');
    }

    return parts.join(' · ');
  }

  static String? _puzzleDateLabel(ArchiveEntry entry) {
    final date = entry.publishDate ?? entry.importedAt;
    return DateFormat('EEE d MMM yyyy').format(date.toLocal());
  }
}

// ---------------------------------------------------------------------------
// Status icon
// ---------------------------------------------------------------------------

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.entry});

  final ArchiveEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    if (entry.isCleanSolve) {
      // ★ Personal-best eligible clean solve
      return Icon(Icons.star_rounded, color: color.primary, size: 28);
    }
    if (entry.isCompleted || entry.isRevealed) {
      // ✓ Completed (with help or revealed)
      return Icon(Icons.check_circle_outline_rounded,
          color: color.primary, size: 28);
    }
    if (entry.isInProgress) {
      // ◑ In progress
      return Icon(Icons.timelapse_rounded,
          color: color.secondary, size: 28);
    }
    // ○ Not started
    return Icon(Icons.radio_button_unchecked_rounded,
        color: color.onSurfaceVariant, size: 28);
  }
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No puzzles yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Import a puzzle to get started.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No puzzles match this filter.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Formats [ms] as m:ss (or h:mm:ss if ≥ 1 hour).
String _formatMs(int ms) {
  final total = ms ~/ 1000;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
