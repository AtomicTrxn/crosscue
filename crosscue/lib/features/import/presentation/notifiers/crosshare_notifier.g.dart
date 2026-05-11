// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crosshare_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CrosshareNotifier)
final crosshareProvider = CrosshareNotifierProvider._();

final class CrosshareNotifierProvider
    extends $NotifierProvider<CrosshareNotifier, CrosshareState> {
  CrosshareNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crosshareProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crosshareNotifierHash();

  @$internal
  @override
  CrosshareNotifier create() => CrosshareNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrosshareState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrosshareState>(value),
    );
  }
}

String _$crosshareNotifierHash() => r'a2d0b67db412b785602f6c2fda9fa90a9124e369';

abstract class _$CrosshareNotifier extends $Notifier<CrosshareState> {
  CrosshareState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CrosshareState, CrosshareState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CrosshareState, CrosshareState>,
        CrosshareState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
