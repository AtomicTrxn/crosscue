// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'past_puzzles_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads and manages the "Past puzzles" listing on the Today screen.
///
/// Walks Crosshare's monthly archive pages backward from the current month,
/// excludes today and any future-scheduled days, and joins each archive entry
/// with the local puzzle list so the UI can show download/solve state.

@ProviderFor(PastPuzzlesNotifier)
final pastPuzzlesProvider = PastPuzzlesNotifierProvider._();

/// Loads and manages the "Past puzzles" listing on the Today screen.
///
/// Walks Crosshare's monthly archive pages backward from the current month,
/// excludes today and any future-scheduled days, and joins each archive entry
/// with the local puzzle list so the UI can show download/solve state.
final class PastPuzzlesNotifierProvider
    extends $AsyncNotifierProvider<PastPuzzlesNotifier, PastPuzzlesState> {
  /// Loads and manages the "Past puzzles" listing on the Today screen.
  ///
  /// Walks Crosshare's monthly archive pages backward from the current month,
  /// excludes today and any future-scheduled days, and joins each archive entry
  /// with the local puzzle list so the UI can show download/solve state.
  PastPuzzlesNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pastPuzzlesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pastPuzzlesNotifierHash();

  @$internal
  @override
  PastPuzzlesNotifier create() => PastPuzzlesNotifier();
}

String _$pastPuzzlesNotifierHash() =>
    r'0465753d8afb536de5235e0e51bfd374bf9a1c6d';

/// Loads and manages the "Past puzzles" listing on the Today screen.
///
/// Walks Crosshare's monthly archive pages backward from the current month,
/// excludes today and any future-scheduled days, and joins each archive entry
/// with the local puzzle list so the UI can show download/solve state.

abstract class _$PastPuzzlesNotifier extends $AsyncNotifier<PastPuzzlesState> {
  FutureOr<PastPuzzlesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PastPuzzlesState>, PastPuzzlesState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PastPuzzlesState>, PastPuzzlesState>,
        AsyncValue<PastPuzzlesState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
