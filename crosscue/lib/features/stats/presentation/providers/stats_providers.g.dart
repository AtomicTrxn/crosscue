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

final class StatsRepositoryProvider extends $FunctionalProvider<StatsRepository,
    StatsRepository, StatsRepository> with $Provider<StatsRepository> {
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
  $ProviderElement<StatsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatsRepository create(Ref ref) {
    return statsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsRepository>(value),
    );
  }
}

String _$statsRepositoryHash() => r'c9fab6d45f2922cf29c95d00f482084b62035d54';

/// Singleton export service — generates/parses JSON only; no file system.

@ProviderFor(statsExportService)
final statsExportServiceProvider = StatsExportServiceProvider._();

/// Singleton export service — generates/parses JSON only; no file system.

final class StatsExportServiceProvider extends $FunctionalProvider<
    StatsExportService,
    StatsExportService,
    StatsExportService> with $Provider<StatsExportService> {
  /// Singleton export service — generates/parses JSON only; no file system.
  StatsExportServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'statsExportServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$statsExportServiceHash();

  @$internal
  @override
  $ProviderElement<StatsExportService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatsExportService create(Ref ref) {
    return statsExportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsExportService>(value),
    );
  }
}

String _$statsExportServiceHash() =>
    r'4d80683fb5dcaaac6ad9bf0065c7039b4b2f1694';

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
