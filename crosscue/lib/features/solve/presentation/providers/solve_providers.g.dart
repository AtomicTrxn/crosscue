// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(solveRepository)
final solveRepositoryProvider = SolveRepositoryProvider._();

final class SolveRepositoryProvider extends $FunctionalProvider<SolveRepository,
    SolveRepository, SolveRepository> with $Provider<SolveRepository> {
  SolveRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'solveRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$solveRepositoryHash();

  @$internal
  @override
  $ProviderElement<SolveRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SolveRepository create(Ref ref) {
    return solveRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SolveRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SolveRepository>(value),
    );
  }
}

String _$solveRepositoryHash() => r'4af135f18403bcc231534b1ba16c49414960cb38';
