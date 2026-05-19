// Dart-side tests for ICloudSyncTransport. The Swift handler is exercised
// manually per docs/architecture/sync-icloud-setup.md; here we cover the
// argument marshaling and the error-swallowing behavior the orchestrator
// relies on.

import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/transport/icloud_sync_transport.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ICloudSyncTransport.channelName);
  late ICloudSyncTransport transport;
  late List<MethodCall> calls;

  void installHandler(Future<Object?>? Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = <MethodCall>[];
    transport = ICloudSyncTransport();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('account', () {
    test('returns null when the handler reports no ubiquity token', () async {
      installHandler((_) async => null);
      expect(await transport.account(), isNull);
      expect(calls.single.method, 'account');
    });

    test('parses a payload into a SyncAccount with iCloud provider', () async {
      installHandler((_) async => {'displayName': 'Test Acct', 'id': null});
      final account = await transport.account();
      expect(account, isNotNull);
      expect(account!.provider, SyncProvider.iCloud);
      expect(account.displayName, 'Test Acct');
      expect(account.id, isNull);
    });

    test('falls back to "iCloud" when displayName is missing', () async {
      installHandler((_) async => <String, Object?>{});
      final account = await transport.account();
      expect(account!.displayName, 'iCloud');
    });

    test('returns null when the channel is not registered', () async {
      // No handler installed — channel will throw MissingPluginException.
      expect(await transport.account(), isNull);
    });

    test('returns null when the handler throws PlatformException', () async {
      installHandler((_) async {
        throw PlatformException(code: 'IO_ERROR', message: 'disk');
      });
      expect(await transport.account(), isNull);
    });
  });

  group('list', () {
    test('forwards prefix and returns the string list', () async {
      installHandler((_) async => <Object?>['a.json', 'b.json']);
      final result = await transport.list('puzzles/');
      expect(result, ['a.json', 'b.json']);
      expect(calls.single.method, 'list');
      expect(calls.single.arguments, {'prefix': 'puzzles/'});
    });

    test('returns empty list when the channel returns null', () async {
      installHandler((_) async => null);
      expect(await transport.list('puzzles/'), isEmpty);
    });

    test('filters non-string items defensively', () async {
      installHandler((_) async => <Object?>['ok.json', 42, null]);
      expect(await transport.list('puzzles/'), ['ok.json']);
    });
  });

  group('read', () {
    test('forwards key and returns the file bytes', () async {
      installHandler((_) async => '{"hello":1}');
      final result = await transport.read('puzzles/p1.json');
      expect(result, '{"hello":1}');
      expect(calls.single.arguments, {'key': 'puzzles/p1.json'});
    });

    test('returns null when the channel returns null', () async {
      installHandler((_) async => null);
      expect(await transport.read('puzzles/missing.json'), isNull);
    });
  });

  group('write', () {
    test('forwards key and bytes', () async {
      installHandler((_) async => null);
      await transport.write('sessions/s1.json', '{"x":1}');
      expect(calls.single.method, 'write');
      expect(calls.single.arguments, {
        'key': 'sessions/s1.json',
        'bytes': '{"x":1}',
      });
    });

    test('includes ifMatch when provided', () async {
      installHandler((_) async => null);
      await transport.write('sessions/s1.json', '{}', ifMatch: 'etag-1');
      expect(calls.single.arguments, {
        'key': 'sessions/s1.json',
        'bytes': '{}',
        'ifMatch': 'etag-1',
      });
    });

    test('completes silently when the channel is unregistered', () async {
      // No handler — MissingPluginException is swallowed.
      await transport.write('a/b.json', '{}');
    });
  });

  group('delete', () {
    test('forwards key', () async {
      installHandler((_) async => null);
      await transport.delete('completions/uuid-1.json');
      expect(calls.single.method, 'delete');
      expect(calls.single.arguments, {'key': 'completions/uuid-1.json'});
    });

    test('completes silently when the channel throws', () async {
      installHandler((_) async {
        throw PlatformException(code: 'IO_ERROR', message: 'disk');
      });
      await transport.delete('completions/uuid-1.json');
    });
  });
}
