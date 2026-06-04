import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a solve result.
///
/// On iOS we route through a native [MethodChannel] (`crosscue.share`) so the
/// share-sheet preview shows the Crosscue icon as `LPLinkMetadata.iconProvider`
/// — branded thumbnail, text-only payload. `share_plus` can't do that: its iOS
/// preview image is derived from a *shared file*, so branding it would mean
/// attaching the icon to the payload (see #147). Every other platform falls
/// back to `share_plus`.
class ResultShare {
  ResultShare({
    MethodChannel? channel,
    Future<ByteData> Function(String key)? loadAsset,
    bool? useNative,
  })  : _channel = channel ?? const MethodChannel(channelName),
        _loadAsset = loadAsset ?? rootBundle.load,
        _useNative = useNative ?? (!kIsWeb && Platform.isIOS);

  static const String channelName = 'crosscue.share';
  static const String _iconAsset = 'assets/images/ic_launcher.png';

  final MethodChannel _channel;
  final Future<ByteData> Function(String key) _loadAsset;

  /// Whether the native branded path is available. Defaults to iOS; overridable
  /// in tests since the host platform can't be iOS.
  final bool _useNative;

  /// Presents the OS share sheet for [text] (with [subject] where supported).
  ///
  /// [origin] anchors the share sheet popover on iPad/macOS; ignored on iPhone.
  /// Throws on failure so callers can surface an error to the user.
  Future<void> share({
    required String text,
    required String subject,
    Rect? origin,
  }) async {
    if (_useNative) {
      final icon = await _loadAsset(_iconAsset);
      await _channel.invokeMethod<void>('shareResult', {
        'text': text,
        'subject': subject,
        'iconPng': icon.buffer.asUint8List(),
        if (origin != null) ...{
          'originX': origin.left,
          'originY': origin.top,
          'originWidth': origin.width,
          'originHeight': origin.height,
        },
      });
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
      ),
    );
  }
}
