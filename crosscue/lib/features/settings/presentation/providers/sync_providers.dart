import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/sync/models/sync_account.dart';
import 'package:crosscue/core/sync/models/sync_result.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

/// View-model for the cross-device sync settings screen (iCloud on iOS,
/// Google Drive on Android).
class SyncViewState {
  const SyncViewState({
    required this.enabled,
    required this.available,
    required this.syncState,
    this.account,
    this.lastResult,
  });

  /// The persisted opt-in flag (survives launches).
  final bool enabled;

  /// Whether sync can be turned on from this device. True when a cloud account
  /// is already reachable (iCloud signed in), or when the transport drives its
  /// own sign-in prompt (Google Drive) — the toggle tap completes sign-in. When
  /// false, enabling is blocked and the UI tells the user to sign in first.
  /// Independent of [enabled].
  final bool available;

  /// Live orchestrator lifecycle state (disabled / signed-out / idle /
  /// running / error).
  final SyncState syncState;

  /// The linked cloud account, if any.
  final SyncAccount? account;

  /// Outcome of the most recent manual sync this session.
  final SyncResult? lastResult;

  SyncViewState copyWith({
    bool? enabled,
    bool? available,
    SyncState? syncState,
    SyncAccount? account,
    SyncResult? lastResult,
  }) {
    return SyncViewState(
      enabled: enabled ?? this.enabled,
      available: available ?? this.available,
      syncState: syncState ?? this.syncState,
      account: account ?? this.account,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// Drives the sync settings UI: exposes the live [SyncViewState] and the
/// enable / disable / sync-now actions, bridging the in-memory
/// [SyncOrchestrator] with the persisted `syncEnabled` flag.
@riverpod
class SyncController extends _$SyncController {
  @override
  Future<SyncViewState> build() async {
    final orchestrator = ref.watch(syncOrchestratorProvider);

    // Mirror the orchestrator's broadcast state into our view-model so the UI
    // reflects running / idle / error transitions as they happen.
    final sub = orchestrator.state.listen((next) {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(current.copyWith(syncState: next));
      }
    });
    ref.onDispose(sub.cancel);

    final enabled = await ref.read(appSettingsProvider).getSyncEnabled();
    final account = await orchestrator.currentAccount();
    return SyncViewState(
      enabled: enabled,
      available:
          account != null || orchestrator.transport.supportsInteractiveSignIn,
      syncState: orchestrator.currentState,
      account: account,
    );
  }

  /// Turns sync on: persists the flag, links the account (prompting interactive
  /// sign-in on transports that need it, e.g. Google Drive), and runs a first
  /// pass. If sign-in is declined / no cloud account is available the
  /// orchestrator lands in [SyncSignedOut] and the UI tells the user to sign in.
  Future<void> enable() async {
    final orchestrator = ref.read(syncOrchestratorProvider);
    await ref.read(appSettingsProvider).setSyncEnabled(true);
    await orchestrator.enable();
    final account = await orchestrator.currentAccount();
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          enabled: true,
          available: account != null ||
              orchestrator.transport.supportsInteractiveSignIn,
          account: account,
          syncState: orchestrator.currentState,
        ),
      );
    }
    await syncNow();
  }

  /// Turns sync off. [wipeRemote] also deletes this app's blobs from the cloud.
  Future<void> disable({bool wipeRemote = false}) async {
    final orchestrator = ref.read(syncOrchestratorProvider);
    await ref.read(appSettingsProvider).setSyncEnabled(false);
    await orchestrator.disable(wipeRemote: wipeRemote);
    // Re-query availability so the toggle can be turned back on — either the
    // device is still signed in (iCloud) or the transport can re-prompt (Drive).
    final available = (await orchestrator.currentAccount()) != null ||
        orchestrator.transport.supportsInteractiveSignIn;
    final current = state.asData?.value;
    if (current != null) {
      // Rebuild without an account (copyWith can't null it out).
      state = AsyncData(
        SyncViewState(
          enabled: false,
          available: available,
          syncState: orchestrator.currentState,
          lastResult: current.lastResult,
        ),
      );
    }
  }

  /// Runs a single push-then-pull pass. No-op (records nothing) when disabled
  /// or signed out; errors surface through the orchestrator's state stream.
  Future<void> syncNow() async {
    final orchestrator = ref.read(syncOrchestratorProvider);
    try {
      final result = await orchestrator.syncNow();
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            lastResult: result,
            syncState: orchestrator.currentState,
          ),
        );
      }
    } on Object {
      // The orchestrator already published a SyncError via its state stream,
      // which the listener in build() folds into the view-model.
    }
  }
}
