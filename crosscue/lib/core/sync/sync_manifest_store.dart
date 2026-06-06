import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_blob.dart';
import 'package:crosscue/core/sync/models/sync_manifest.dart';
import 'package:crosscue/core/sync/models/sync_namespace.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';

enum SyncManifestReadStatus { found, fallbackRequired }

class SyncManifestReadResult {
  const SyncManifestReadResult._(this.status, this.manifest);

  const SyncManifestReadResult.found(SyncManifest manifest)
      : this._(SyncManifestReadStatus.found, manifest);

  const SyncManifestReadResult.fallbackRequired()
      : this._(SyncManifestReadStatus.fallbackRequired, null);

  final SyncManifestReadStatus status;
  final SyncManifest? manifest;

  bool get requiresFallback =>
      status == SyncManifestReadStatus.fallbackRequired;
}

class SyncManifestStore {
  const SyncManifestStore();

  Future<SyncManifestReadResult> read(SyncTransport transport) async {
    final bytes = await transport.read(SyncManifest.key);
    if (bytes == null) return const SyncManifestReadResult.fallbackRequired();

    final manifest = SyncManifest.decode(bytes);
    if (manifest == null) {
      return const SyncManifestReadResult.fallbackRequired();
    }

    return SyncManifestReadResult.found(manifest);
  }

  Future<void> write(SyncTransport transport, SyncManifest manifest) {
    return transport.write(SyncManifest.key, manifest.encode());
  }

  Future<SyncManifest> rebuildFromRemote({
    required SyncTransport transport,
    required List<NamespaceSyncAdapter> adapters,
    DateTime? now,
  }) async {
    final namespaces = <SyncNamespace, Map<String, SyncManifestEntry>>{};

    for (final adapter in adapters) {
      final entries = <String, SyncManifestEntry>{};
      final keys = await transport.list(adapter.namespace.prefix);
      for (final key in keys) {
        final bytes = await transport.read(key);
        if (bytes == null) continue;

        final blob = SyncBlob.decode(bytes);
        if (blob == null) continue;

        entries[key] = SyncManifestEntry(
          syncVersion: blob.syncVersion,
          updatedAt: blob.updatedAt,
          deviceId: blob.deviceId,
        );
      }
      namespaces[adapter.namespace] = entries;
    }

    return SyncManifest(
      schemaVersion: SyncManifest.currentSchemaVersion,
      updatedAt: now?.toUtc() ?? DateTime.now().toUtc(),
      namespaces: namespaces,
    );
  }
}
