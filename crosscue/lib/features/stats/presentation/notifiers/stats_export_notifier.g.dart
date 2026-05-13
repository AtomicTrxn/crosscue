// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_export_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StatsExportNotifier)
final statsExportProvider = StatsExportNotifierProvider._();

final class StatsExportNotifierProvider
    extends $NotifierProvider<StatsExportNotifier, StatsExportState> {
  StatsExportNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'statsExportProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$statsExportNotifierHash();

  @$internal
  @override
  StatsExportNotifier create() => StatsExportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsExportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsExportState>(value),
    );
  }
}

String _$statsExportNotifierHash() =>
    r'2fab130531d9bd022bd2676b64e99e497614fb43';

abstract class _$StatsExportNotifier extends $Notifier<StatsExportState> {
  StatsExportState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<StatsExportState, StatsExportState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<StatsExportState, StatsExportState>,
        StatsExportState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
