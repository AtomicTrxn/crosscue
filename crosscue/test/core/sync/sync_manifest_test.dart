import 'dart:convert';

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

  group('SyncManifest helpers', () {
    SyncManifestEntry entry({
      int syncVersion = 1,
      String deviceId = 'device-a',
      DateTime? updatedAt,
    }) =>
        SyncManifestEntry(
          syncVersion: syncVersion,
          updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1, 12),
          deviceId: deviceId,
        );

    test('empty() has every namespace present but bare', () {
      final manifest = SyncManifest.empty();
      for (final namespace in SyncNamespace.values) {
        expect(manifest.entriesFor(namespace), isEmpty);
      }
      expect(manifest.schemaVersion, SyncManifest.currentSchemaVersion);
    });

    test('entriesFor / entryFor read namespace entries', () {
      final manifest = SyncManifest.empty().withEntry(
        SyncNamespace.puzzles,
        'puzzles/p-1.json',
        entry(syncVersion: 4),
      );

      expect(
        manifest.entriesFor(SyncNamespace.puzzles).keys,
        ['puzzles/p-1.json'],
      );
      expect(
        manifest
            .entryFor(SyncNamespace.puzzles, 'puzzles/p-1.json')!
            .syncVersion,
        4,
      );
      expect(manifest.entryFor(SyncNamespace.puzzles, 'missing.json'), isNull);
      expect(manifest.entriesFor(SyncNamespace.sessions), isEmpty);
    });

    test('withEntry returns a copy without mutating the receiver', () {
      final original = SyncManifest.empty();
      final next = original.withEntry(
        SyncNamespace.settings,
        'settings/theme.json',
        entry(),
      );

      expect(original.entriesFor(SyncNamespace.settings), isEmpty);
      expect(
        next.entryFor(SyncNamespace.settings, 'settings/theme.json'),
        isNotNull,
      );
    });

    test('manifestKey does not collide with any namespace prefix', () {
      for (final namespace in SyncNamespace.values) {
        expect(
          SyncManifest.manifestKey.startsWith(namespace.prefix),
          isFalse,
        );
      }
    });

    test('entryCount sums entries across all namespaces (#207)', () {
      expect(SyncManifest.empty().entryCount, 0);
      final manifest = SyncManifest.empty()
          .withEntry(SyncNamespace.puzzles, 'puzzles/a.json', entry())
          .withEntry(SyncNamespace.puzzles, 'puzzles/b.json', entry())
          .withEntry(SyncNamespace.sessions, 'sessions/a.json', entry());
      expect(manifest.entryCount, 3);
    });
  });

  group('SyncManifestStore', () {
    test('missing, corrupt, and newer-schema manifests require fallback',
        () async {
      final store = <String, String>{};
      final transport = FakeSyncTransport(store: store);
      const manifestStore = SyncManifestStore();

      expect((await manifestStore.read(transport)).requiresFallback, isTrue);

      store[SyncManifest.manifestKey] = 'not-json';
      expect((await manifestStore.read(transport)).requiresFallback, isTrue);

      store[SyncManifest.manifestKey] = jsonEncode({
        'schemaVersion': SyncManifest.currentSchemaVersion + 1,
        'updatedAt': DateTime.utc(2026).toIso8601String(),
        'namespaces': <String, Object?>{},
      });
      expect((await manifestStore.read(transport)).requiresFallback, isTrue);
    });

    test('a transport error reading the manifest degrades to fallback',
        () async {
      // The manifest is just an optimization index — a transient lock/IO error
      // reading it must not abort the sync; it falls back to a full scan.
      final transport = _ThrowingReadTransport(
        store: {},
        kind: SyncTransportErrorKind.locked,
      );

      final result = await const SyncManifestStore().read(transport);

      expect(result.requiresFallback, isTrue);
    });

    test('valid manifest is found', () async {
      final manifest = SyncManifest(
        schemaVersion: SyncManifest.currentSchemaVersion,
        updatedAt: DateTime.utc(2026),
        namespaces: const {},
      );
      final transport = FakeSyncTransport(
        store: {SyncManifest.manifestKey: manifest.encode()},
      );

      final result = await const SyncManifestStore().read(transport);

      expect(result.requiresFallback, isFalse);
      expect(result.manifest, isNotNull);
    });

    test('write returns the encoded byte length and stores the manifest (#207)',
        () async {
      final manifest = SyncManifest.empty();
      final store = <String, String>{};
      final transport = FakeSyncTransport(store: store);

      final bytes = await const SyncManifestStore().write(transport, manifest);

      expect(bytes, manifest.encode().length);
      expect(store[SyncManifest.manifestKey], manifest.encode());
    });
  });
}

/// Fake transport whose [read] always throws, to exercise the store's
/// degrade-to-fallback behavior on a transient manifest read failure.
class _ThrowingReadTransport extends FakeSyncTransport {
  _ThrowingReadTransport({
    required super.store,
    required this.kind,
  });

  final SyncTransportErrorKind kind;

  @override
  Future<String?> read(String key) async => throw SyncTransportException(kind);
}
