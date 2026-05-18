import 'package:crosscue/core/audio/sound_player.dart';
import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/entitlement/entitlement_service.dart';
import 'package:crosscue/core/entitlement/free_entitlement_service.dart';
import 'package:crosscue/core/sync/sync_orchestrator.dart';
import 'package:crosscue/core/sync/transport/no_op_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:crosscue/core/telemetry/crash_reporter.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'core_providers.g.dart';

/// App version string in the form `v1.2.3`, derived from [PackageInfo].
///
/// Returns a fallback `'vunknown'` on platforms where [PackageInfo] is
/// unavailable.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version}';
  } on Object {
    return 'vunknown';
  }
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

/// Cloud transport for sync. Defaults to [NoOpSyncTransport] so the
/// local-only build keeps working; the iCloud / Drive transports replace
/// this provider once those land (see `docs/architecture/sync-progress.md`).
@Riverpod(keepAlive: true)
SyncTransport syncTransport(Ref ref) => const NoOpSyncTransport();

/// Sync orchestrator. Reads the current [syncTransport] and wires up the
/// per-namespace adapters against the shared [appDatabase].
@Riverpod(keepAlive: true)
SyncOrchestrator syncOrchestrator(Ref ref) {
  final orchestrator = SyncOrchestrator(
    transport: ref.watch(syncTransportProvider),
    db: ref.watch(appDatabaseProvider),
  );
  ref.onDispose(orchestrator.dispose);
  return orchestrator;
}

/// Entitlement service — all features free.
@Riverpod(keepAlive: true)
EntitlementService entitlementService(Ref ref) =>
    const FreeEntitlementService();

/// Crash reporter — local-only; no data leaves the device.
@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) => LocalCrashReporter();

@Riverpod(keepAlive: true)
SoundPlayer soundPlayer(Ref ref) {
  final player = SoundPlayer(crashReporter: ref.read(crashReporterProvider));
  ref.onDispose(player.dispose);
  return player;
}
