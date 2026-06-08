import 'package:crosscue/features/challenge_boards/presentation/theme/challenge_palette.dart';
import 'package:flutter/material.dart';

/// Crosscue · Preset avatar silhouettes.
///
/// Three theme-independent "looks", indexed 1..3:
///   1 · blue · headphones
///   2 · warm · cap
///   3 · navy · top-knot
/// Rendered in a 100×100 design space, clipped to a circle, then scaled to fit.
class SilhouettePainter extends CustomPainter {
  final int look; // 1..3
  const SilhouettePainter(this.look);

  @override
  void paint(Canvas canvas, Size size) {
    final p = kSilhouettePalettes[(look - 1) % 3];
    final s = size.width / 100.0;
    canvas.save();
    canvas.scale(s);
    canvas.clipPath(
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 50)),
    );

    // background
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), Paint()..color = p.bg);

    final fig = Paint()
      ..color = p.fig
      ..isAntiAlias = true;
    final accFill = Paint()
      ..color = p.accent
      ..isAntiAlias = true;

    // shared bust
    final bust = Path()
      ..moveTo(22, 92)
      ..cubicTo(22, 75, 34, 64, 50, 64)
      ..cubicTo(66, 64, 78, 75, 78, 92)
      ..close();
    canvas.drawPath(bust, fig);
    // head
    canvas.drawCircle(const Offset(50, 44), 15, fig);

    switch (look) {
      case 1: // headphones
        final band = Path()
          ..moveTo(33, 45)
          ..arcToPoint(
            const Offset(67, 45),
            radius: const Radius.circular(17),
            clockwise: true,
          );
        canvas.drawPath(
          band,
          Paint()
            ..color = p.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.5
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27.5, 41, 9, 15),
            const Radius.circular(4),
          ),
          accFill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(63.5, 41, 9, 15),
            const Radius.circular(4),
          ),
          accFill,
        );
        break;
      case 2: // cap with side brim
        final crown = Path()
          ..moveTo(35.5, 45)
          ..arcToPoint(
            const Offset(64.5, 45),
            radius: const Radius.circular(14.5),
            clockwise: true,
          )
          ..close();
        canvas.drawPath(crown, accFill);
        final brim = Path()
          ..moveTo(64, 41)
          ..quadraticBezierTo(79, 40, 81, 46)
          ..quadraticBezierTo(78, 51, 64, 49)
          ..close();
        canvas.drawPath(brim, accFill);
        canvas.drawCircle(const Offset(50, 30.5), 3, accFill);
        break;
      case 3: // top-knot
        canvas.drawCircle(const Offset(50, 27), 7.5, accFill);
        final hair = Path()
          ..moveTo(35, 44)
          ..arcToPoint(
            const Offset(65, 44),
            radius: const Radius.circular(15),
            clockwise: true,
          )
          ..quadraticBezierTo(50, 37, 35, 44)
          ..close();
        canvas.drawPath(hair, accFill);
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter old) => old.look != look;
}

/// A preset silhouette inside a circle, at any size.
class Silhouette extends StatelessWidget {
  final int look;
  final double size;
  const Silhouette({super.key, this.look = 1, this.size = 64});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: SilhouettePainter(look)),
      );
}
