// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton repository for the Archive feature.

@ProviderFor(archiveRepository)
final archiveRepositoryProvider = ArchiveRepositoryProvider._();

/// Singleton repository for the Archive feature.

final class ArchiveRepositoryProvider extends $FunctionalProvider<
    ArchiveRepository,
    ArchiveRepository,
    ArchiveRepository> with $Provider<ArchiveRepository> {
  /// Singleton repository for the Archive feature.
  ArchiveRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'archiveRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$archiveRepositoryHash();

  @$internal
  @override
  $ProviderElement<ArchiveRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveRepository create(Ref ref) {
    return archiveRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveRepository>(value),
    );
  }
}

String _$archiveRepositoryHash() => r'bdb7747e7fb12f4a230ef450d0ce022de5bc0752';

/// All archive entries (puzzles + their latest session status), import-date desc.
/// Invalidated by the archive screen after a delete, and by ImportNotifier after
/// a successful import.

@ProviderFor(archiveEntries)
final archiveEntriesProvider = ArchiveEntriesProvider._();

/// All archive entries (puzzles + their latest session status), import-date desc.
/// Invalidated by the archive screen after a delete, and by ImportNotifier after
/// a successful import.

final class ArchiveEntriesProvider extends $FunctionalProvider<
        AsyncValue<List<ArchiveEntry>>,
        List<ArchiveEntry>,
        FutureOr<List<ArchiveEntry>>>
    with
        $FutureModifier<List<ArchiveEntry>>,
        $FutureProvider<List<ArchiveEntry>> {
  /// All archive entries (puzzles + their latest session status), import-date desc.
  /// Invalidated by the archive screen after a delete, and by ImportNotifier after
  /// a successful import.
  ArchiveEntriesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'archiveEntriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$archiveEntriesHash();

  @$internal
  @override
  $FutureProviderElement<List<ArchiveEntry>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<ArchiveEntry>> create(Ref ref) {
    return archiveEntries(ref);
  }
}

String _$archiveEntriesHash() => r'b28f0e7cb40360a2cf8a33617dc74308a184f2a4';
