import 'dart:async';
import 'dart:convert';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/sync/adapters/completions_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/namespace_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/puzzles_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/sessions_sync_adapter.dart';
import 'package:crosscue/core/sync/adapters/settings_sync_adapter.dart';
import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/models/sync_result.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/sync/transport/no_op_sync_transport.dart';
import 'package:crosscue/core/sync/transport/sync_transport.dart';
import 'package:crosscue/core/utils/uuid.dart';

/// Top-level facade exposed to the app. Owns the per-namespace adapters,
/// drives push-then-pull sync passes, and broadcasts lifecycle state to
/// the settings UI.
///
/// See `docs/architecture/sync-design.md` (High-level shape).
class SyncOrchestrator {
  SyncOrchestrator({
    required this.transport,
    required this.db,
    List<NamespaceSyncAdapter>? adapters,
  }) : adapters = adapters ??
            <NamespaceSyncAdapter>[
              PuzzlesSyncAdapter(db),
              SessionsSyncAdapter(db),
              CompletionsSyncAdapter(db),
              SettingsSyncAdapter(db),
            ];

  final SyncTransport transport;
  final AppDatabase db;
  final List<NamespaceSyncAdapter> adapters;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();
  SyncState _state = const SyncDisabled();
  DateTime? _lastSyncedAt;

  Stream<SyncState> get state => _stateController.stream;
  SyncState get currentState => _state;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<SyncAccount?> currentAccount() => transport.account();

  Future<void> enable() async {
    final account = await transport.account();
    _setState(
      account == null
          ? const SyncSignedOut()
          : SyncIdle(lastSyncedAt: _lastSyncedAt),
    );
  }

  Future<void> disable({bool wipeRemote = false}) async {
    if (wipeRemote) {
      for (final adapter in adapters) {
        final keys = await transport.list(adapter.namespace.prefix);
        for (final key in keys) {
          await transport.delete(key);
        }
      }
    }
    _setState(const SyncDisabled());
  }

  /// Runs a single push-then-pull pass across all namespaces. Safe to call
  /// when [SyncDisabled] or [SyncSignedOut] — it returns immediately with
  /// [SyncResult.zero] in those states.
  Future<SyncResult> syncNow() async {
    if (_state is SyncDisabled || _state is SyncSignedOut) {
      return SyncResult.zero;
    }
    // NoOp transports report no account but are wired in the local-only
    // build. Short-circuit to avoid spurious writes/reads.
    if (transport is NoOpSyncTransport) return SyncResult.zero;

    _setState(const SyncRunning());
    final start = DateTime.now();
    final deviceId = await _resolveDeviceId();

    NamespaceSyncOutcome total = NamespaceSyncOutcome.zero;
    try {
      // Pull first so per-namespace merge rules (best-progress override,
      // LWW) can fold remote state into ours before we push. Pushing first
      // would silently overwrite a remote completed session with a local
      // in-progress one when the in-progress row happens to be newer.
      // Puzzles must land before completions for FK satisfaction.
      for (final adapter in adapters) {
        total += await adapter.pull(transport);
      }
      for (final adapter in adapters) {
        total += await adapter.push(transport, deviceId);
      }
    } on Object catch (e) {
      _setState(SyncError(e.toString(), transient: true));
      rethrow;
    }

    final result = SyncResult(
      pushed: total.pushed,
      pulled: total.pulled,
      conflicts: total.conflicts,
      duration: DateTime.now().difference(start),
    );
    _lastSyncedAt = DateTime.now().toUtc();
    _setState(SyncIdle(lastSyncedAt: _lastSyncedAt));
    return result;
  }

  Future<void> dispose() async {
    await _stateController.close();
  }

  /// Reads or generates the stable per-install device id. Stored in
  /// `app_settings` under the `device_id` key (excluded from sync via
  /// [SettingsSyncAdapter.excludedKeys]).
  Future<String> _resolveDeviceId() async {
    final raw = await db.appSettingsDao.getValue('device_id');
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is String) return decoded;
    }
    final fresh = Uuid.v4();
    await db.appSettingsDao.setValue('device_id', jsonEncode(fresh));
    return fresh;
  }

  void _setState(SyncState next) {
    _state = next;
    _stateController.add(next);
  }
}
