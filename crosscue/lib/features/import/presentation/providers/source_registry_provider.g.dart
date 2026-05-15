// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_registry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide registry of puzzle sources that are known to Crosscue.
///
/// Sources are registered here only after their license status is cleared by
/// the source-review process in [SourceRegistry].

@ProviderFor(sourceRegistry)
final sourceRegistryProvider = SourceRegistryProvider._();

/// App-wide registry of puzzle sources that are known to Crosscue.
///
/// Sources are registered here only after their license status is cleared by
/// the source-review process in [SourceRegistry].

final class SourceRegistryProvider
    extends $FunctionalProvider<SourceRegistry, SourceRegistry, SourceRegistry>
    with $Provider<SourceRegistry> {
  /// App-wide registry of puzzle sources that are known to Crosscue.
  ///
  /// Sources are registered here only after their license status is cleared by
  /// the source-review process in [SourceRegistry].
  SourceRegistryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sourceRegistryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sourceRegistryHash();

  @$internal
  @override
  $ProviderElement<SourceRegistry> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SourceRegistry create(Ref ref) {
    return sourceRegistry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceRegistry value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceRegistry>(value),
    );
  }
}

String _$sourceRegistryHash() => r'1a9107747cb738b36ec10d20170af989f50bbc14';
