// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the solve session lifecycle: load/resume in [build], the elapsed-clock
/// boundaries, autosave/persistence, and completion. The interactive surface is
/// grouped by responsibility into part-file mixins applied below:
///
///   * [_SolveNavigation]   — tap / direction / focus movement
///   * [_SolveInput]        — keyboard letter / rebus / backspace entry
///   * [_SolveCheckReveal]  — check + reveal actions
///
/// Each mixin re-declares the private orchestration members it leans on
/// (`_s`, `_scheduleSave`, `_checkCompletion`, …) as abstract; this class is
/// their single concrete implementation. See #183.

@ProviderFor(SolveNotifier)
final solveProvider = SolveNotifierFamily._();

/// Owns the solve session lifecycle: load/resume in [build], the elapsed-clock
/// boundaries, autosave/persistence, and completion. The interactive surface is
/// grouped by responsibility into part-file mixins applied below:
///
///   * [_SolveNavigation]   — tap / direction / focus movement
///   * [_SolveInput]        — keyboard letter / rebus / backspace entry
///   * [_SolveCheckReveal]  — check + reveal actions
///
/// Each mixin re-declares the private orchestration members it leans on
/// (`_s`, `_scheduleSave`, `_checkCompletion`, …) as abstract; this class is
/// their single concrete implementation. See #183.
final class SolveNotifierProvider
    extends $AsyncNotifierProvider<SolveNotifier, SolveState> {
  /// Owns the solve session lifecycle: load/resume in [build], the elapsed-clock
  /// boundaries, autosave/persistence, and completion. The interactive surface is
  /// grouped by responsibility into part-file mixins applied below:
  ///
  ///   * [_SolveNavigation]   — tap / direction / focus movement
  ///   * [_SolveInput]        — keyboard letter / rebus / backspace entry
  ///   * [_SolveCheckReveal]  — check + reveal actions
  ///
  /// Each mixin re-declares the private orchestration members it leans on
  /// (`_s`, `_scheduleSave`, `_checkCompletion`, …) as abstract; this class is
  /// their single concrete implementation. See #183.
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

String _$solveNotifierHash() => r'018eca40977298d9db5af0aa1e2c6d4d9f0db549';

/// Owns the solve session lifecycle: load/resume in [build], the elapsed-clock
/// boundaries, autosave/persistence, and completion. The interactive surface is
/// grouped by responsibility into part-file mixins applied below:
///
///   * [_SolveNavigation]   — tap / direction / focus movement
///   * [_SolveInput]        — keyboard letter / rebus / backspace entry
///   * [_SolveCheckReveal]  — check + reveal actions
///
/// Each mixin re-declares the private orchestration members it leans on
/// (`_s`, `_scheduleSave`, `_checkCompletion`, …) as abstract; this class is
/// their single concrete implementation. See #183.

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

  /// Owns the solve session lifecycle: load/resume in [build], the elapsed-clock
  /// boundaries, autosave/persistence, and completion. The interactive surface is
  /// grouped by responsibility into part-file mixins applied below:
  ///
  ///   * [_SolveNavigation]   — tap / direction / focus movement
  ///   * [_SolveInput]        — keyboard letter / rebus / backspace entry
  ///   * [_SolveCheckReveal]  — check + reveal actions
  ///
  /// Each mixin re-declares the private orchestration members it leans on
  /// (`_s`, `_scheduleSave`, `_checkCompletion`, …) as abstract; this class is
  /// their single concrete implementation. See #183.

  SolveNotifierProvider call(
    String puzzleId,
  ) =>
      SolveNotifierProvider._(argument: puzzleId, from: this);

  @override
  String toString() => r'solveProvider';
}

/// Owns the solve session lifecycle: load/resume in [build], the elapsed-clock
/// boundaries, autosave/persistence, and completion. The interactive surface is
/// grouped by responsibility into part-file mixins applied below:
///
///   * [_SolveNavigation]   — tap / direction / focus movement
///   * [_SolveInput]        — keyboard letter / rebus / backspace entry
///   * [_SolveCheckReveal]  — check + reveal actions
///
/// Each mixin re-declares the private orchestration members it leans on
/// (`_s`, `_scheduleSave`, `_checkCompletion`, …) as abstract; this class is
/// their single concrete implementation. See #183.

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
