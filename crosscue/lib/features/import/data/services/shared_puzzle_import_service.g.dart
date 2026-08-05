// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_puzzle_import_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedPuzzleImportService)
final sharedPuzzleImportServiceProvider = SharedPuzzleImportServiceProvider._();

final class SharedPuzzleImportServiceProvider extends $FunctionalProvider<
    SharedPuzzleImportService,
    SharedPuzzleImportService,
    SharedPuzzleImportService> with $Provider<SharedPuzzleImportService> {
  SharedPuzzleImportServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sharedPuzzleImportServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sharedPuzzleImportServiceHash();

  @$internal
  @override
  $ProviderElement<SharedPuzzleImportService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharedPuzzleImportService create(Ref ref) {
    return sharedPuzzleImportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPuzzleImportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPuzzleImportService>(value),
    );
  }
}

String _$sharedPuzzleImportServiceHash() =>
    r'6780ebb19150ad550b330e45ad38dd406e14e2e2';
