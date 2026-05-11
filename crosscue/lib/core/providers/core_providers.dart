import 'package:crosscue/core/audio/sound_player.dart';
import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/entitlement/entitlement_service.dart';
import 'package:crosscue/core/entitlement/free_entitlement_service.dart';
import 'package:crosscue/core/sync/no_op_sync_adapter.dart';
import 'package:crosscue/core/sync/sync_adapter.dart';
import 'package:crosscue/core/telemetry/crash_reporter.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'core_providers.g.dart';

/// App version string in the form `v1.2.3`, derived from [PackageInfo].
///
/// Returns a fallback `'v—'` on platforms where [PackageInfo] is unavailable.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
}

/// Shared [Dio] HTTP client for all network sources.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

/// The single shared [AppDatabase] instance for the app lifetime.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => AppDatabase();

/// Phase 1 sync adapter — no-op (local only).
@Riverpod(keepAlive: true)
SyncAdapter syncAdapter(Ref ref) => const NoOpSyncAdapter();

/// Phase 1 entitlement service — all features free.
@Riverpod(keepAlive: true)
EntitlementService entitlementService(Ref ref) =>
    const FreeEntitlementService();

/// Crash reporter — local-only in Phase 1; no data leaves the device.
@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) => LocalCrashReporter();

@Riverpod(keepAlive: true)
SoundPlayer soundPlayer(Ref ref) {
  final player = SoundPlayer();
  ref.onDispose(player.dispose);
  return player;
}

/// Registers a [WidgetsBindingObserver] that triggers the Crosshare
/// auto-download whenever the app returns to the foreground.
///
/// Kept alive for the full app lifetime. Reads [crosshareAutoDownloadService]
/// (also keepAlive) rather than holding a direct reference, so the service
/// provider is only created once.
///
/// Must be eagerly initialised in [CrosscueApp] (via `ref.read`) so the
/// observer is registered before the first lifecycle event fires.
@Riverpod(keepAlive: true)
void appLifecycleObserver(Ref ref) {
  final observer = _CrosshareLifecycleObserver(ref);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
}

class _CrosshareLifecycleObserver extends WidgetsBindingObserver {
  _CrosshareLifecycleObserver(this._ref);

  final Ref _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded();
    }
  }
}
