// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crosshare_auto_download_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the current [CrosshareAutoDownloadPhase] for the UI to watch.
///
/// [CrosshareAutoDownloadService] is the only writer, via the `onPhase`
/// callback wired up in [crosshareAutoDownloadServiceProvider].

@ProviderFor(CrosshareAutoDownloadProgress)
final crosshareAutoDownloadProgressProvider =
    CrosshareAutoDownloadProgressProvider._();

/// Holds the current [CrosshareAutoDownloadPhase] for the UI to watch.
///
/// [CrosshareAutoDownloadService] is the only writer, via the `onPhase`
/// callback wired up in [crosshareAutoDownloadServiceProvider].
final class CrosshareAutoDownloadProgressProvider extends $NotifierProvider<
    CrosshareAutoDownloadProgress, CrosshareAutoDownloadPhase> {
  /// Holds the current [CrosshareAutoDownloadPhase] for the UI to watch.
  ///
  /// [CrosshareAutoDownloadService] is the only writer, via the `onPhase`
  /// callback wired up in [crosshareAutoDownloadServiceProvider].
  CrosshareAutoDownloadProgressProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crosshareAutoDownloadProgressProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crosshareAutoDownloadProgressHash();

  @$internal
  @override
  CrosshareAutoDownloadProgress create() => CrosshareAutoDownloadProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrosshareAutoDownloadPhase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrosshareAutoDownloadPhase>(value),
    );
  }
}

String _$crosshareAutoDownloadProgressHash() =>
    r'5c95877387857793ffa3aceab2cb35cf387c40ef';

/// Holds the current [CrosshareAutoDownloadPhase] for the UI to watch.
///
/// [CrosshareAutoDownloadService] is the only writer, via the `onPhase`
/// callback wired up in [crosshareAutoDownloadServiceProvider].

abstract class _$CrosshareAutoDownloadProgress
    extends $Notifier<CrosshareAutoDownloadPhase> {
  CrosshareAutoDownloadPhase build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<CrosshareAutoDownloadPhase, CrosshareAutoDownloadPhase>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CrosshareAutoDownloadPhase, CrosshareAutoDownloadPhase>,
        CrosshareAutoDownloadPhase,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(crosshareAutoDownloadService)
final crosshareAutoDownloadServiceProvider =
    CrosshareAutoDownloadServiceProvider._();

final class CrosshareAutoDownloadServiceProvider extends $FunctionalProvider<
    CrosshareAutoDownloadService,
    CrosshareAutoDownloadService,
    CrosshareAutoDownloadService> with $Provider<CrosshareAutoDownloadService> {
  CrosshareAutoDownloadServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crosshareAutoDownloadServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crosshareAutoDownloadServiceHash();

  @$internal
  @override
  $ProviderElement<CrosshareAutoDownloadService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CrosshareAutoDownloadService create(Ref ref) {
    return crosshareAutoDownloadService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrosshareAutoDownloadService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrosshareAutoDownloadService>(value),
    );
  }
}

String _$crosshareAutoDownloadServiceHash() =>
    r'3ab90ed0916606eb49284e8c00fee53a4e8054fb';
