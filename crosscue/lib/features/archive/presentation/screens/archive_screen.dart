import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/presentation/providers/archive_providers.dart';
import 'package:crosscue/features/archive/presentation/widgets/puzzle_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const _filterChipLabelStyle = TextStyle(
  fontSize: CrosscueTypography.bodySmall,
);
const _archiveMetaStyle = TextStyle(fontSize: CrosscueTypography.label);
const _sortButtonBaseStyle = TextStyle(
  fontSize: CrosscueTypography.label,
  fontWeight: FontWeight.w500,
);

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
                        itemBuilder: (ctx, i) {
                          final entry = sorted[i];
                          return PuzzleListTile(
                            title: entry.title,
                            entry: entry,
                            subtitle: _archiveSubtitle(entry),
                            iconWidth: 22,
                            iconSize: 18,
                            iconGap: 10,
                            dividerIndent: 52,
                            showStatusNote: true,
                            onTap: () => context.push(
                              Routes.solveFor(
                                Uri.encodeComponent(entry.puzzleId),
                              ),
                            ),
                            onLongPress: () => _confirmDelete(ctx, entry),
                          );
                        },
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
              backgroundColor: ctx.crosscueError,
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
          style: _filterChipLabelStyle.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color:
                selected ? context.crosscuePrimary : context.crosscueOnSurface3,
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
            style: _archiveMetaStyle.copyWith(
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
                  style: _sortButtonBaseStyle.copyWith(
                    color: context.crosscuePrimary,
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

String _archiveSubtitle(ArchiveEntry entry) {
  final date = entry.publishDate ?? entry.importedAt;
  return '${DateFormat('d MMM yyyy').format(date.toLocal())} · ${entry.sizeLabel}';
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
            color: context.crosscueOnSurface3,
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
                  color: context.crosscueOnSurface3,
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
              color: context.crosscueOnSurface3,
            ),
      ),
    );
  }
}
