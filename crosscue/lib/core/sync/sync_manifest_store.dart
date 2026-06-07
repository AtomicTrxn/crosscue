import 'package:crosscue/core/sync/models/sync_manifest.dart';
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
    final String? bytes;
    try {
      bytes = await transport.read(SyncManifest.manifestKey);
    } on SyncTransportException {
      // The manifest is an optimization index, not the source of truth. A
      // transient lock / I/O error reading it must not abort the whole sync —
      // degrade to the full namespace scan, which is always correct. If the
      // failure is real and persistent, the subsequent pull will surface it.
      return const SyncManifestReadResult.fallbackRequired();
    }
    if (bytes == null) return const SyncManifestReadResult.fallbackRequired();

    final manifest = SyncManifest.decode(bytes);
    if (manifest == null) {
      return const SyncManifestReadResult.fallbackRequired();
    }

    return SyncManifestReadResult.found(manifest);
  }

  Future<void> write(SyncTransport transport, SyncManifest manifest) {
    return transport.write(SyncManifest.manifestKey, manifest.encode());
  }
}
