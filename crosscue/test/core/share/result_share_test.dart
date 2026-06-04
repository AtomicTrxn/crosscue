// Tests for ResultShare (#147): the iOS native path forwards the result text,
// subject, icon bytes, and popover origin over the `crosscue.share` channel.

import 'package:crosscue/core/share/result_share.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ResultShare.channelName);
  final binaryMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  ByteData fakeIcon() => ByteData.view(Uint8List.fromList([1, 2, 3, 4]).buffer);

  tearDown(() {
    binaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('native path forwards text, subject, icon bytes, and origin', () async {
    MethodCall? captured;
    binaryMessenger.setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return null;
    });

    final share = ResultShare(
      channel: channel,
      loadAsset: (_) async => fakeIcon(),
      useNative: true,
    );

    await share.share(
      text: 'Puzzle\n00:42 - Clean solve\nSolved in Crosscue',
      subject: 'Crosscue result',
      origin: const Rect.fromLTWH(1, 2, 3, 4),
    );

    expect(captured?.method, 'shareResult');
    final args = captured!.arguments as Map;
    expect(args['text'], 'Puzzle\n00:42 - Clean solve\nSolved in Crosscue');
    expect(args['subject'], 'Crosscue result');
    expect(args['iconPng'], isA<Uint8List>());
    expect((args['iconPng'] as Uint8List).toList(), [1, 2, 3, 4]);
    expect(args['originX'], 1.0);
    expect(args['originY'], 2.0);
    expect(args['originWidth'], 3.0);
    expect(args['originHeight'], 4.0);
  });

  test('native path omits origin keys when no origin given', () async {
    MethodCall? captured;
    binaryMessenger.setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return null;
    });

    final share = ResultShare(
      channel: channel,
      loadAsset: (_) async => fakeIcon(),
      useNative: true,
    );

    await share.share(text: 't', subject: 's');

    final args = captured!.arguments as Map;
    expect(args.containsKey('originX'), isFalse);
  });

  test('native channel errors propagate to the caller', () async {
    binaryMessenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'SHARE_FAILED', message: 'boom');
    });

    final share = ResultShare(
      channel: channel,
      loadAsset: (_) async => fakeIcon(),
      useNative: true,
    );

    expect(
      () => share.share(text: 't', subject: 's'),
      throwsA(isA<PlatformException>()),
    );
  });
}
