// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the iCloud sync settings UI: exposes the live [SyncViewState] and the
/// enable / disable / sync-now actions, bridging the in-memory
/// [SyncOrchestrator] with the persisted `syncEnabled` flag.

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// Drives the iCloud sync settings UI: exposes the live [SyncViewState] and the
/// enable / disable / sync-now actions, bridging the in-memory
/// [SyncOrchestrator] with the persisted `syncEnabled` flag.
final class SyncControllerProvider
    extends $AsyncNotifierProvider<SyncController, SyncViewState> {
  /// Drives the iCloud sync settings UI: exposes the live [SyncViewState] and the
  /// enable / disable / sync-now actions, bridging the in-memory
  /// [SyncOrchestrator] with the persisted `syncEnabled` flag.
  SyncControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'syncControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();
}

String _$syncControllerHash() => r'f51e7a7b1a73e0c62550d2e77321a8f50a509a56';

/// Drives the iCloud sync settings UI: exposes the live [SyncViewState] and the
/// enable / disable / sync-now actions, bridging the in-memory
/// [SyncOrchestrator] with the persisted `syncEnabled` flag.

abstract class _$SyncController extends $AsyncNotifier<SyncViewState> {
  FutureOr<SyncViewState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SyncViewState>, SyncViewState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SyncViewState>, SyncViewState>,
        AsyncValue<SyncViewState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
