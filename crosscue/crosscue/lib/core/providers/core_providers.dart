import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/entitlement/entitlement_service.dart';
import 'package:crosscue/core/entitlement/free_entitlement_service.dart';
import 'package:crosscue/core/sync/no_op_sync_adapter.dart';
import 'package:crosscue/core/sync/sync_adapter.dart';
import 'package:crosscue/core/telemetry/crash_reporter.dart';

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
