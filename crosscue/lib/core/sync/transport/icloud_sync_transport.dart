import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:flutter/services.dart';

/// iCloud Documents transport for iOS.
///
/// Communicates with the native side over [MethodChannel]. The Swift handler
/// uses the app's iCloud Documents container (entitlement
/// `com.apple.developer.icloud-container-identifiers`) and `NSFileCoordinator`
/// for safe reads/writes. When the user hasn't enabled iCloud Drive for the
/// app — or the developer hasn't yet attached the entitlement — every method
/// fails gracefully: [account] returns null (orchestrator stays in
/// [SyncSignedOut]) and the CRUD methods become no-ops.
///
/// See `docs/architecture/sync-icloud-setup.md` for the one-time Xcode
/// configuration the developer needs to do before this transport activates.
class ICloudSyncTransport implements SyncTransport {
  ICloudSyncTransport({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'crosscue.sync.icloud';

  final MethodChannel _channel;

  @override
  Future<SyncAccount?> account() async {
    final result = await _safeInvoke<Map<Object?, Object?>?>('account');
    if (result == null) return null;
    return SyncAccount(
      provider: SyncProvider.iCloud,
      displayName: (result['displayName'] as String?) ?? 'iCloud',
      id: result['id'] as String?,
    );
  }

  @override
  Future<List<String>> list(String prefix) async {
    final result = await _safeInvoke<List<Object?>>('list', {'prefix': prefix});
    if (result == null) return const [];
    return result.whereType<String>().toList();
  }

  @override
  Future<String?> read(String key) async {
    return _safeInvoke<String?>('read', {'key': key});
  }

  @override
  Future<String?> write(String key, String bytes, {String? ifMatch}) async {
    return _safeInvoke<String?>('write', {
      'key': key,
      'bytes': bytes,
      if (ifMatch != null) 'ifMatch': ifMatch,
    });
  }

  @override
  Future<void> delete(String key) async {
    await _safeInvoke<void>('delete', {'key': key});
  }

  /// Swallows [MissingPluginException] (channel not registered on the running
  /// platform, e.g. unit tests or Android) and [PlatformException] (handler
  /// reported an iCloud-side error). Returning null is the documented
  /// "transport unavailable" signal that [SyncOrchestrator] interprets as
  /// [SyncSignedOut] / [SyncError] depending on context.
  Future<T?> _safeInvoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
