import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../entitlement/entitlement_service.dart';
import '../entitlement/free_entitlement_service.dart';
import '../sync/no_op_sync_adapter.dart';
import '../sync/sync_adapter.dart';
import '../telemetry/crash_reporter.dart';

part 'core_providers.g.dart';

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

/// Crash reporter — no-op until Sentry is wired (post-MVP).
@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) => const NoOpCrashReporter();
