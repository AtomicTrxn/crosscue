// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

/// Crosscue · Avatar normalization.
///
/// Any photo a player adds is centered, scaled (cover-fit + user zoom) and
/// cropped to a square, then exported at a fixed [ChallengeLimits.avatarOutputSize]
/// (512 × 512). The circular shape is applied at *display* time (see
/// PlayerAvatar) so the stored asset stays a simple square PNG — but you can
/// bake the circle in by passing [circularMask] = true.
///
/// Typical flow:
///   final src = await decodeImageFromBytes(pickedBytes);
///   final png = await AvatarNormalizer.normalize(
///     source: src,
///     viewport: const Size(232, 232), // the crop viewport used in the UI
///     userScale: controllerScale,     // 1.0 = cover-fit base
///     userOffset: controllerOffset,   // pan in viewport logical px
///   );
///   // upload `png` (Uint8List, PNG)
abstract final class AvatarNormalizer {
  static Future<ui.Image> decodeImageFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Produce a normalized square avatar as PNG bytes.
  static Future<Uint8List> normalize({
    required ui.Image source,
    required Size viewport,
    double userScale = 1.0,
    Offset userOffset = Offset.zero,
    int outputSize = 512,
    bool circularMask = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final out = outputSize.toDouble();

    // Background fill so transparent source edges stay defined.
    final paintBg = Paint()..color = const Color(0xFFEAECEF);
    canvas.drawRect(Rect.fromLTWH(0, 0, out, out), paintBg);

    if (circularMask) {
      canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, out, out)));
    } else {
      canvas.clipRect(Rect.fromLTWH(0, 0, out, out));
    }

    // Cover-fit base scale: fill the square viewport, then apply user zoom.
    final imgW = source.width.toDouble();
    final imgH = source.height.toDouble();
    final coverBase = [viewport.width / imgW, viewport.height / imgH]
        .reduce((a, b) => a > b ? a : b);
    final totalScale = coverBase * userScale;

    // Viewport→output factor (UI worked in `viewport` px; output is `out` px).
    final k = out / viewport.width;

    canvas.save();
    // Center of output + user pan (scaled into output space).
    canvas.translate(out / 2 + userOffset.dx * k, out / 2 + userOffset.dy * k);
    canvas.scale(totalScale * k);
    canvas.drawImage(source, Offset(-imgW / 2, -imgH / 2),
        Paint()..filterQuality = FilterQuality.high);
    canvas.restore();

    final picture = recorder.endRecording();
    final img = await picture.toImage(outputSize, outputSize);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
