// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(importRepository)
final importRepositoryProvider = ImportRepositoryProvider._();

final class ImportRepositoryProvider extends $FunctionalProvider<
    ImportRepositoryImpl,
    ImportRepositoryImpl,
    ImportRepositoryImpl> with $Provider<ImportRepositoryImpl> {
  ImportRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'importRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$importRepositoryHash();

  @$internal
  @override
  $ProviderElement<ImportRepositoryImpl> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportRepositoryImpl create(Ref ref) {
    return importRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportRepositoryImpl>(value),
    );
  }
}

String _$importRepositoryHash() => r'84f819d4937e1a4447b94796add4b62b4cbab13f';
