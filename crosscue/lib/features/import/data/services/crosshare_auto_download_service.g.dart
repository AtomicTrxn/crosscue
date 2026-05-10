// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crosshare_auto_download_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'40f9fa8ada1903d81462b04fb3638b3b1998fa92';
