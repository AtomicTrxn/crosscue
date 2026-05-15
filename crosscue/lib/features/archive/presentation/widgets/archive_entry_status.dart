import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/core/utils/time_format.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:flutter/material.dart';

/// Visual status (icon + color) for an [ArchiveEntry].
///
/// Single source of truth for "how does this puzzle's progress look?" —
/// used by both the Today screen (`_PuzzleRow`, featured puzzle) and the
/// Archive screen (`_ArchiveRow`). Keeping the mapping here prevents drift
/// (e.g. one screen showing a star while the other shows a checkmark for
/// the same `isCleanSolve` state).
///
/// Status precedence (highest first):
///   1. Clean solve → star (primary)
///   2. Completed or revealed → check (correct)
///   3. In progress → hourglass (mid-primary)
///   4. Not started (or no entry yet) → empty circle (subtle)
class ArchiveEntryStatus {
  const ArchiveEntryStatus({
    required this.icon,
    required this.color,
    this.noteLabel,
    this.noteColor,
  });

  final IconData icon;
  final Color color;
  final String? noteLabel;
  final Color? noteColor;

  /// Resolves the visual status for [entry]. A null [entry] is treated as
  /// "not started" since absence of an archive row means no progress has
  /// been recorded yet.
  factory ArchiveEntryStatus.of(BuildContext context, ArchiveEntry? entry) {
    if (entry == null || entry.isNotStarted) {
      return ArchiveEntryStatus(
        icon: Icons.radio_button_unchecked_rounded,
        color: context.crosscueOnSurface3,
      );
    }
    if (entry.isCleanSolve) {
      return ArchiveEntryStatus(
        icon: Icons.star_rounded,
        color: context.crosscuePrimary,
      );
    }
    if (entry.isCompleted || entry.isRevealed) {
      final isRevealed = entry.isRevealed && !entry.isCompleted;
      final elapsed = entry.elapsedMs == null ? '' : formatMs(entry.elapsedMs!);
      final label = isRevealed
          ? 'Revealed'
          : 'Completed${elapsed.isNotEmpty ? ' · $elapsed' : ''}';
      return ArchiveEntryStatus(
        icon: Icons.check_circle_outline_rounded,
        color: context.crosscueCorrect,
        noteLabel: label,
        noteColor:
            isRevealed ? context.crosscueOnSurface2 : context.crosscueCorrect,
      );
    }
    // In progress
    final elapsed = entry.elapsedMs == null ? '' : formatMs(entry.elapsedMs!);
    return ArchiveEntryStatus(
      icon: Icons.timelapse_rounded,
      color: context.crosscuePrimary,
      noteLabel: 'In progress${elapsed.isNotEmpty ? ' · $elapsed' : ''}',
      noteColor: context.crosscuePrimary,
    );
  }
}
