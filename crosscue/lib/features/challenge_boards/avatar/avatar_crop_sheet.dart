// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../util/avatar_normalizer.dart';
import '../sheets/board_sheets.dart' show showCbSheet;

/// Crop & normalize. Pan + pinch/slide-zoom inside a circular viewport, then
/// export a fixed 512 × 512 avatar via [AvatarNormalizer]. Returns PNG bytes.
Future<Uint8List?> showAvatarCropSheet(BuildContext context,
    {required ui.Image source}) {
  return showCbSheet<Uint8List>(context, title: 'Adjust photo', builder: (ctx) {
    return _CropBody(source: source);
  });
}

class _CropBody extends StatefulWidget {
  final ui.Image source;
  const _CropBody({required this.source});
  @override
  State<_CropBody> createState() => _CropBodyState();
}

class _CropBodyState extends State<_CropBody> {
  static const double _viewport = 232;
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _baseOffset = Offset.zero;
  Offset _focal = Offset.zero;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onScaleStart: (d) {
                  _baseScale = _scale;
                  _baseOffset = _offset;
                  _focal = d.localFocalPoint;
                },
                onScaleUpdate: (d) => setState(() {
                  _scale = (_baseScale * d.scale).clamp(1.0, 4.0);
                  _offset = _baseOffset + (d.localFocalPoint - _focal);
                }),
                child: CustomPaint(
                  size: const Size.square(_viewport),
                  painter: _CropPainter(
                      image: widget.source,
                      scale: _scale,
                      offset: _offset,
                      viewport: _viewport),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // zoom slider
          Row(children: [
            Icon(Icons.remove, size: 18, color: AppColors.onSurface3(context)),
            Expanded(
                child: Slider(
              value: _scale,
              min: 1.0,
              max: 4.0,
              onChanged: (v) => setState(() => _scale = v),
            )),
            Icon(Icons.add, size: 20, color: AppColors.onSurface3(context)),
          ]),
          const SizedBox(height: 8),
          // normalized output note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.divider(context))),
            child: Row(children: [
              Icon(Icons.crop_free_rounded,
                  size: 20, color: AppColors.onSurface2(context)),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        'Normalized to ${ChallengeLimits.avatarOutputSize} × ${ChallengeLimits.avatarOutputSize} · circular',
                        style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface1(context))),
                    const SizedBox(height: 1),
                    Text('Drag to reposition · pinch or slide to zoom',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.onSurface3(context))),
                  ])),
            ]),
          ),
          const SizedBox(height: 18),
          FilledButton(
              onPressed: _busy ? null : _confirm,
              child: const Text('Use photo')),
          const SizedBox(height: 4),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.onSurface2(context)))),
        ]);
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final bytes = await AvatarNormalizer.normalize(
      source: widget.source,
      viewport: const Size.square(_viewport),
      userScale: _scale,
      userOffset: _offset,
      outputSize: ChallengeLimits.avatarOutputSize,
    );
    if (mounted) Navigator.pop(context, bytes);
  }
}

/// Draws the image with the current transform, then a dim mask with a circular
/// hole + thirds guides — WYSIWYG with [AvatarNormalizer].
class _CropPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;
  final double viewport;
  _CropPainter(
      {required this.image,
      required this.scale,
      required this.offset,
      required this.viewport});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final imgW = image.width.toDouble(), imgH = image.height.toDouble();
    final coverBase =
        [size.width / imgW, size.height / imgH].reduce((a, b) => a > b ? a : b);
    final total = coverBase * scale;

    canvas.save();
    canvas.translate(size.width / 2 + offset.dx, size.height / 2 + offset.dy);
    canvas.scale(total);
    canvas.drawImage(image, Offset(-imgW / 2, -imgH / 2),
        Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();

    // dim mask with circular hole
    final r = size.width * 0.40;
    final c = size.center(Offset.zero);
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = const Color(0x8F080A12));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xEBFFFFFF));

    // thirds guides
    final guide = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(c.dx - r, c.dy - r / 3), Offset(c.dx + r, c.dy - r / 3), guide);
    canvas.drawLine(
        Offset(c.dx - r, c.dy + r / 3), Offset(c.dx + r, c.dy + r / 3), guide);
    canvas.drawLine(
        Offset(c.dx - r / 3, c.dy - r), Offset(c.dx - r / 3, c.dy + r), guide);
    canvas.drawLine(
        Offset(c.dx + r / 3, c.dy - r), Offset(c.dx + r / 3, c.dy + r), guide);
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.scale != scale || old.offset != offset || old.image != image;
}
