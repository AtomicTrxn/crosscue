import 'dart:convert';

import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/sync_manifest_store.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncManifest', () {
    test('round-trips namespace metadata', () {
      final manifest = SyncManifest(
        schemaVersion: SyncManifest.currentSchemaVersion,
        updatedAt: DateTime.utc(2026, 6, 5),
        namespaces: {
          SyncNamespace.puzzles: {
            'puzzles/local:abc.json': SyncManifestEntry(
              syncVersion: 3,
              updatedAt: DateTime.utc(2026, 6, 5, 1),
              deviceId: 'device-a',
            ),
          },
          SyncNamespace.sessions: const {},
          SyncNamespace.completions: const {},
          SyncNamespace.settings: const {},
        },
      );

      final decoded = SyncManifest.decode(manifest.encode());

      expect(decoded, isNotNull);
      expect(decoded!.schemaVersion, equals(1));
      expect(decoded.updatedAt, equals(DateTime.utc(2026, 6, 5)));
      final entry =
          decoded.namespaces[SyncNamespace.puzzles]!['puzzles/local:abc.json'];
      expect(entry, isNotNull);
      expect(entry!.syncVersion, equals(3));
      expect(entry.updatedAt, equals(DateTime.utc(2026, 6, 5, 1)));
      expect(entry.deviceId, equals('device-a'));
      expect(decoded.namespaces[SyncNamespace.sessions], isEmpty);
    });

    test('decode returns null for corrupt and newer-schema manifests', () {
      expect(SyncManifest.decode('not-json'), isNull);
      expect(
        SyncManifest.decode(
          jsonEncode({
            'schemaVersion': SyncManifest.currentSchemaVersion + 1,
            'updatedAt': DateTime.utc(2026).toIso8601String(),
            'namespaces': <String, Object?>{},
          }),
        ),
        isNull,
      );
    });
  });

  group('SyncManifestStore', () {
    test('missing, corrupt, and newer-schema manifests require fallback',
        () async {
      final store = <String, String>{};
      final transport = FakeSyncTransport(store: store);
      const manifestStore = SyncManifestStore();

      expect((await manifestStore.read(transport)).requiresFallback, isTrue);

      store[SyncManifest.key] = 'not-json';
      expect((await manifestStore.read(transport)).requiresFallback, isTrue);

      store[SyncManifest.key] = jsonEncode({
        'schemaVersion': SyncManifest.currentSchemaVersion + 1,
        'updatedAt': DateTime.utc(2026).toIso8601String(),
        'namespaces': <String, Object?>{},
      });
      expect((await manifestStore.read(transport)).requiresFallback, isTrue);
    });

    test('valid manifest is found', () async {
      final manifest = SyncManifest(
        schemaVersion: SyncManifest.currentSchemaVersion,
        updatedAt: DateTime.utc(2026),
        namespaces: const {},
      );
      final transport = FakeSyncTransport(
        store: {SyncManifest.key: manifest.encode()},
      );

      final result = await const SyncManifestStore().read(transport);

      expect(result.requiresFallback, isFalse);
      expect(result.manifest, isNotNull);
    });

    test('rebuildFromRemote indexes only valid sync blobs', () async {
      final valid = SyncBlob(
        schemaVersion: SyncBlob.currentSchemaVersion,
        deviceId: 'device-a',
        syncVersion: 2,
        updatedAt: DateTime.utc(2026, 6, 5),
        payload: const {'id': 'puz-1'},
      );
      final transport = FakeSyncTransport(
        store: {
          'puzzles/puz-1.json': valid.encode(),
          'puzzles/bad.json': 'not-json',
        },
      );

      final rebuilt = await const SyncManifestStore().rebuildFromRemote(
        transport: transport,
        adapters: [_TestAdapter(SyncNamespace.puzzles)],
        now: DateTime.utc(2026, 6, 6),
      );

      expect(rebuilt.updatedAt, equals(DateTime.utc(2026, 6, 6)));
      expect(
        rebuilt.namespaces[SyncNamespace.puzzles]!.keys,
        contains('puzzles/puz-1.json'),
      );
      expect(
        rebuilt.namespaces[SyncNamespace.puzzles]!.keys,
        isNot(contains('puzzles/bad.json')),
      );
    });
  });
}

class _TestAdapter extends NamespaceSyncAdapter {
  _TestAdapter(this.namespace);

  @override
  final SyncNamespace namespace;

  @override
  Future<NamespaceSyncOutcome> pull(SyncTransport transport) async =>
      NamespaceSyncOutcome.zero;

  @override
  Future<NamespaceSyncOutcome> push(
    SyncTransport transport,
    String deviceId,
  ) async =>
      NamespaceSyncOutcome.zero;
}
