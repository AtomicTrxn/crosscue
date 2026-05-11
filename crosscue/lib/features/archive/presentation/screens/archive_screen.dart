import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/presentation/providers/archive_providers.dart';
import 'package:crosscue/features/home/presentation/providers/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final archiveAsync = ref.watch(archiveEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archive')),
      body: archiveAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) return const _EmptyArchive();

          final filtered = _applyFilter(entries, _filter);
          final sorted = _applySort(filtered, _sort);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter chips
              _FilterChips(
                current: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
              // Sort bar
              _SortBar(
                count: filtered.length,
                sort: _sort,
                onSort: (s) => setState(() => _sort = s),
              ),
              // List
              Expanded(
                child: sorted.isEmpty
                    ? const _EmptyFilter()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: sorted.length,
                        itemBuilder: (ctx, i) => _ArchiveRow(
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
    List<ArchiveEntry> entries,
    _FilterMode filter,
  ) {
    return switch (filter) {
      _FilterMode.all => entries,
      _FilterMode.notStarted => entries.where((e) => e.isNotStarted).toList(),
      _FilterMode.inProgress => entries.where((e) => e.isInProgress).toList(),
      _FilterMode.completed =>
        entries.where((e) => e.isCompleted || e.isRevealed).toList(),
    };
  }

  static List<ArchiveEntry> _applySort(
    List<ArchiveEntry> entries,
    _SortOrder sort,
  ) {
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
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(archiveRepositoryProvider).deletePuzzle(entry.puzzleId);
    ref.invalidate(archiveEntriesProvider);
    ref.invalidate(puzzleListProvider);
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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.crosscueDivider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CrosscueSpacing.screenH,
          vertical: 10,
        ),
        child: Row(
          children: _FilterMode.values
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: _filterLabel(f),
                    selected: current == f,
                    onTap: () => onSelected(f),
                  ),
                ),
              )
              .toList(),
        ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
        decoration: BoxDecoration(
          color:
              selected ? context.crosscuePrimaryContainer : Colors.transparent,
          border: Border.all(
            color: selected
                ? context.crosscueWordHighlight
                : context.crosscueDivider,
          ),
          borderRadius: BorderRadius.circular(CrosscueSpacing.chipRadius),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: CrosscueTypography.bodySmall,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color:
                selected ? CrosscueColors.primary : context.crosscueOnSurface3,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort bar
// ---------------------------------------------------------------------------

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.count,
    required this.sort,
    required this.onSort,
  });

  final int count;
  final _SortOrder sort;
  final void Function(_SortOrder) onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: CrosscueSpacing.screenH,
      ),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'puzzle' : 'puzzles'}',
            style: TextStyle(
              fontSize: CrosscueTypography.label,
              color: context.crosscueOnSurface3,
            ),
          ),
          const Spacer(),
          PopupMenuButton<_SortOrder>(
            initialValue: sort,
            onSelected: onSort,
            tooltip: 'Sort',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort: ${_sortLabel(sort)} ↓',
                  style: const TextStyle(
                    fontSize: CrosscueTypography.label,
                    fontWeight: FontWeight.w500,
                    color: CrosscueColors.primary,
                  ),
                ),
              ],
            ),
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
          ),
        ],
      ),
    );
  }

  static String _sortLabel(_SortOrder s) => switch (s) {
        _SortOrder.importDate => 'Date',
        _SortOrder.puzzleDate => 'Pub. Date',
        _SortOrder.title => 'Title',
      };
}

// ---------------------------------------------------------------------------
// Archive row (flat design)
// ---------------------------------------------------------------------------

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.entry, required this.onDelete});

  final ArchiveEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor) = _iconAndColor(context, entry);
    final subtitle = _subtitleParts(entry).join(' · ');
    final (statusNote, statusColor) = _statusNote(context, entry);
    final onSurface3 = context.crosscueOnSurface3;

    return Column(
      children: [
        InkWell(
          onTap: () => context
              .push(Routes.solveFor(Uri.encodeComponent(entry.puzzleId))),
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: CrosscueSpacing.rowV,
              horizontal: CrosscueSpacing.screenH,
            ),
            child: Row(
              children: [
                // Status icon — 22dp wide
                SizedBox(
                  width: 22,
                  child: Icon(iconData, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                // Text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: CrosscueTypography.body,
                          fontWeight: FontWeight.w500,
                          color: context.crosscueOnSurface1,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: CrosscueTypography.label,
                            color: onSurface3,
                          ),
                        ),
                      if (statusNote != null)
                        Text(
                          statusNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: CrosscueTypography.label,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: onSurface3,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent:
              52, // 16 screenH + 22 icon col + 10 gap + 4 extra = 52 per spec
          endIndent: 0,
          color: context.crosscueDivider,
        ),
      ],
    );
  }

  (IconData, Color) _iconAndColor(BuildContext context, ArchiveEntry e) {
    if (e.isCleanSolve) {
      return (Icons.star_rounded, CrosscueColors.primary);
    }
    if (e.isCompleted || e.isRevealed) {
      return (Icons.check_circle_outline_rounded, context.crosscueCorrect);
    }
    if (e.isInProgress) {
      return (Icons.timelapse_rounded, CrosscueColors.primaryMid);
    }
    return (Icons.radio_button_unchecked_rounded, context.crosscueOnSurface3);
  }

  List<String> _subtitleParts(ArchiveEntry e) {
    final parts = <String>[];
    final date = e.publishDate ?? e.importedAt;
    parts.add(DateFormat('d MMM yyyy').format(date.toLocal()));
    parts.add(e.sizeLabel);
    return parts;
  }

  (String?, Color) _statusNote(BuildContext context, ArchiveEntry e) {
    if (e.isNotStarted) return (null, Colors.transparent);
    if (e.isInProgress) {
      final t = e.elapsedMs != null ? formatMs(e.elapsedMs!) : '';
      return (
        'In progress${t.isNotEmpty ? ' · $t' : ''}',
        CrosscueColors.primaryMid,
      );
    }
    if (e.isCompleted) {
      final t = e.elapsedMs != null ? formatMs(e.elapsedMs!) : '';
      return (
        'Completed${t.isNotEmpty ? ' · $t' : ''}',
        context.crosscueCorrect,
      );
    }
    if (e.isRevealed) return ('Revealed', context.crosscueOnSurface2);
    return (null, Colors.transparent);
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
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No puzzles yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
