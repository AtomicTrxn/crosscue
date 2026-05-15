import 'dart:math' as math;

import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:crosscue/core/theme/theme_colors.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/presentation/widgets/archive_entry_status.dart';
import 'package:flutter/material.dart';

const _tileTitleStyle = TextStyle(
  fontSize: CrosscueTypography.body,
  fontWeight: FontWeight.w500,
);
const _tileMetaStyle = TextStyle(fontSize: CrosscueTypography.label);
const _tileStatusNoteStyle = TextStyle(
  fontSize: CrosscueTypography.label,
  fontWeight: FontWeight.w500,
);

class PuzzleListTile extends StatelessWidget {
  const PuzzleListTile({
    super.key,
    required this.title,
    required this.entry,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.showProgress = false,
    this.iconWidth = 20,
    this.iconSize = 16,
    this.iconGap = 12,
    this.dividerIndent = 50,
    this.showStatusNote = false,
  });

  final String title;
  final ArchiveEntry? entry;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showProgress;
  final double iconWidth;
  final double iconSize;
  final double iconGap;
  final double dividerIndent;
  final bool showStatusNote;

  @override
  Widget build(BuildContext context) {
    final status = ArchiveEntryStatus.of(context, entry);
    final noteLabel = showStatusNote ? status.noteLabel : null;
    final noteColor = status.noteColor ?? status.color;
    final onSurface3 = context.crosscueOnSurface3;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: CrosscueSpacing.rowV,
              horizontal: CrosscueSpacing.screenH,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: iconWidth,
                  child: Icon(status.icon, size: iconSize, color: status.color),
                ),
                SizedBox(width: iconGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _tileTitleStyle.copyWith(
                          color: context.crosscueOnSurface1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _tileMetaStyle.copyWith(
                                  color: onSurface3,
                                ),
                              ),
                            ),
                            if (showProgress) ...[
                              const SizedBox(width: 4),
                              PuzzleProgressPie(
                                value: entry?.completionFraction ?? 0,
                              ),
                            ],
                          ],
                        ),
                      if (noteLabel != null)
                        Text(
                          noteLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _tileStatusNoteStyle.copyWith(
                            color: noteColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: onSurface3),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: dividerIndent,
          endIndent: 0,
          color: context.crosscueDivider,
        ),
      ],
    );
  }
}

class PuzzleProgressPie extends StatelessWidget {
  const PuzzleProgressPie({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _PuzzleProgressPiePainter(
          value: value.clamp(0.0, 1.0),
          fill: context.crosscuePrimary,
          track: CrosscueColors.trackGrey,
        ),
      ),
    );
  }
}

class _PuzzleProgressPiePainter extends CustomPainter {
  const _PuzzleProgressPiePainter({
    required this.value,
    required this.fill,
    required this.track,
  });

  final double value;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = track;
    canvas.drawCircle(center, radius - 1.25, trackPaint);

    if (value <= 0) return;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill;
    if (value >= 1) {
      canvas.drawCircle(center, radius - 1.25, fillPaint);
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius - 1.25);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -math.pi / 2, math.pi * 2 * value, false)
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(_PuzzleProgressPiePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.fill != fill ||
        oldDelegate.track != track;
  }
}
