import 'dart:math' as math;

import 'package:flutter/material.dart';

class CrosscueNavIcon extends StatelessWidget {
  const CrosscueNavIcon.home({super.key, required this.selected})
      : _type = _NavIconType.home;

  const CrosscueNavIcon.archive({super.key, required this.selected})
      : _type = _NavIconType.archive;

  const CrosscueNavIcon.stats({super.key, required this.selected})
      : _type = _NavIconType.stats;

  const CrosscueNavIcon.settings({super.key, required this.selected})
      : _type = _NavIconType.settings;

  final bool selected;
  final _NavIconType _type;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox.square(
      dimension: 24,
      child: CustomPaint(
        painter: _NavIconPainter(type: _type, selected: selected, color: color),
      ),
    );
  }
}

enum _NavIconType { home, archive, stats, settings }

class _NavIconPainter extends CustomPainter {
  const _NavIconPainter({
    required this.type,
    required this.selected,
    required this.color,
  });

  final _NavIconType type;
  final bool selected;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _NavIconType.home:
        _paintHome(canvas);
      case _NavIconType.archive:
        _paintArchive(canvas);
      case _NavIconType.stats:
        _paintStats(canvas);
      case _NavIconType.settings:
        _paintSettings(canvas, size);
    }
  }

  void _paintHome(Canvas canvas) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const rects = [
      Rect.fromLTWH(4, 4, 7, 7),
      Rect.fromLTWH(13, 4, 7, 7),
      Rect.fromLTWH(4, 13, 7, 7),
      Rect.fromLTWH(13, 13, 7, 7),
    ];
    for (var i = 0; i < rects.length; i++) {
      final rrect =
          RRect.fromRectAndRadius(rects[i], const Radius.circular(1.5));
      if (selected && i < 3) {
        canvas.drawRRect(rrect, fill);
      } else {
        canvas.drawRRect(rrect, stroke);
      }
    }
  }

  void _paintArchive(Canvas canvas) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final outline = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 5, 16, 15),
      const Radius.circular(2),
    );
    canvas.drawRRect(outline, selected ? fill : stroke);
    if (!selected) {
      canvas.drawLine(const Offset(4, 9), const Offset(20, 9), stroke);
    }
    final cutout = Paint()
      ..color = selected ? Colors.white : color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 12, 5, 4), const Radius.circular(1)),
      cutout,
    );
  }

  void _paintStats(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = selected ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.8;
    const bars = [
      Rect.fromLTWH(4, 12, 4, 8),
      Rect.fromLTWH(10, 7, 4, 13),
      Rect.fromLTWH(16, 2, 4, 18),
    ];
    for (final rect in bars) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
    }
  }

  void _paintSettings(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gear = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? 9.5 : 7.2;
      final angle = -math.pi / 2 + i * math.pi / 8;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        gear.moveTo(point.dx, point.dy);
      } else {
        gear.lineTo(point.dx, point.dy);
      }
    }
    gear.close();

    if (selected) {
      final path = Path.combine(
        PathOperation.difference,
        gear,
        Path()..addOval(Rect.fromCircle(center: center, radius: 3.2)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    } else {
      canvas.drawPath(
        gear,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(
        center,
        3.2,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.selected != selected ||
      oldDelegate.color != color;
}
