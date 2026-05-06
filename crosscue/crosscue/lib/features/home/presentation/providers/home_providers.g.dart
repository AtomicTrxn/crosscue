// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(puzzleList)
final puzzleListProvider = PuzzleListProvider._();

final class PuzzleListProvider extends $FunctionalProvider<
        AsyncValue<List<PuzzleMetadata>>,
        List<PuzzleMetadata>,
        FutureOr<List<PuzzleMetadata>>>
    with
        $FutureModifier<List<PuzzleMetadata>>,
        $FutureProvider<List<PuzzleMetadata>> {
  PuzzleListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'puzzleListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$puzzleListHash();

  @$internal
  @override
  $FutureProviderElement<List<PuzzleMetadata>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<PuzzleMetadata>> create(Ref ref) {
    return puzzleList(ref);
  }
}

String _$puzzleListHash() => r'e78b241472a7887b9104b16d5eb7fe5e53452cdf';
