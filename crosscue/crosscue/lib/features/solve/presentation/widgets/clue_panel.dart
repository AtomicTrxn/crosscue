import 'package:flutter/material.dart';

import '../../domain/models/clue.dart';
import '../../domain/models/enums.dart';
import '../notifiers/solve_state.dart';

/// Bottom panel showing the active clue and its cross-clue.
class CluePanel extends StatelessWidget {
  const CluePanel({super.key, required this.solveState});

  final SolveState solveState;

  @override
  Widget build(BuildContext context) {
    final activeClue = solveState.activeClue;
    final crossClue = solveState.crossClue;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeClue != null)
            _ClueTile(
              clue: activeClue,
              isPrimary: true,
            ),
          if (crossClue != null)
            _ClueTile(
              clue: crossClue,
              isPrimary: false,
            ),
          if (activeClue == null && crossClue == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tap a cell to begin solving.'),
            ),
        ],
      ),
    );
  }
}

class _ClueTile extends StatelessWidget {
  const _ClueTile({required this.clue, required this.isPrimary});

  final Clue clue;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final label =
        '${clue.number} ${clue.direction == Direction.across ? 'Across' : 'Down'}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight:
                        isPrimary ? FontWeight.bold : FontWeight.normal,
                    color: isPrimary
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              clue.text,
              style: isPrimary
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      )
                  : Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
