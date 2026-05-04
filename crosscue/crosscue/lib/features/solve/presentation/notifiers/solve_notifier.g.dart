// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SolveNotifier)
final solveProvider = SolveNotifierFamily._();

final class SolveNotifierProvider
    extends $AsyncNotifierProvider<SolveNotifier, SolveState> {
  SolveNotifierProvider._(
      {required SolveNotifierFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'solveProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$solveNotifierHash();

  @override
  String toString() {
    return r'solveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SolveNotifier create() => SolveNotifier();

  @override
  bool operator ==(Object other) {
    return other is SolveNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$solveNotifierHash() => r'b8926630ae53c7eba1aa602dc8328e1088583c5c';

final class SolveNotifierFamily extends $Family
    with
        $ClassFamilyOverride<SolveNotifier, AsyncValue<SolveState>, SolveState,
            FutureOr<SolveState>, String> {
  SolveNotifierFamily._()
      : super(
          retry: null,
          name: r'solveProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SolveNotifierProvider call(
    String puzzleId,
  ) =>
      SolveNotifierProvider._(argument: puzzleId, from: this);

  @override
  String toString() => r'solveProvider';
}

abstract class _$SolveNotifier extends $AsyncNotifier<SolveState> {
  late final _$args = ref.$arg as String;
  String get puzzleId => _$args;

  FutureOr<SolveState> build(
    String puzzleId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SolveState>, SolveState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SolveState>, SolveState>,
        AsyncValue<SolveState>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
