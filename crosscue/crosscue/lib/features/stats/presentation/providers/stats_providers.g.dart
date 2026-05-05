// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton repository for the Stats feature.

@ProviderFor(statsRepository)
final statsRepositoryProvider = StatsRepositoryProvider._();

/// Singleton repository for the Stats feature.

final class StatsRepositoryProvider extends $FunctionalProvider<
    StatsRepositoryImpl,
    StatsRepositoryImpl,
    StatsRepositoryImpl> with $Provider<StatsRepositoryImpl> {
  /// Singleton repository for the Stats feature.
  StatsRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'statsRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$statsRepositoryHash();

  @$internal
  @override
  $ProviderElement<StatsRepositoryImpl> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatsRepositoryImpl create(Ref ref) {
    return statsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsRepositoryImpl>(value),
    );
  }
}

String _$statsRepositoryHash() => r'36990c0d3d040b3294c42f19bb0997e4979f9ab0';

/// Aggregated stats derived from all solve sessions.
/// Re-fetched each time the provider is watched (no keepAlive),
/// so opening the Stats tab always shows fresh data.

@ProviderFor(statsData)
final statsDataProvider = StatsDataProvider._();

/// Aggregated stats derived from all solve sessions.
/// Re-fetched each time the provider is watched (no keepAlive),
/// so opening the Stats tab always shows fresh data.

final class StatsDataProvider extends $FunctionalProvider<AsyncValue<StatsData>,
        StatsData, FutureOr<StatsData>>
    with $FutureModifier<StatsData>, $FutureProvider<StatsData> {
  /// Aggregated stats derived from all solve sessions.
  /// Re-fetched each time the provider is watched (no keepAlive),
  /// so opening the Stats tab always shows fresh data.
  StatsDataProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'statsDataProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$statsDataHash();

  @$internal
  @override
  $FutureProviderElement<StatsData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StatsData> create(Ref ref) {
    return statsData(ref);
  }
}

String _$statsDataHash() => r'e1d2c75b1cff911faec14ab8f8b407a2a9638160';
