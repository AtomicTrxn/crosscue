// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_elapsed_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live, per-second elapsed clock for the solve screen, scoped to one
/// puzzle.
///
/// **Why this exists.** Before this provider, `SolveNotifier`'s state
/// included `elapsedSeconds` and incremented it once per second via
/// `state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1))`.
/// `SolveScreen.build` watches `solveProvider(...)`, so every tick
/// invalidated the entire screen: `CrosswordGrid`, `CluePanel`,
/// `CrosswordKeyboard`, the confetti widget, and the outer `LayoutBuilder`
/// all rebuilt every second on idle. `CustomPainter.shouldRepaint`
/// suppressed the actual paint, but the Element-tree rebuild and
/// `LayoutBuilder` re-measurement still ran every second — frame-budget
/// tax on lower-end Android devices for nothing user-visible except the
/// AppBar's seconds digit.
///
/// This provider holds the ticking value in isolation. `SolveAppBar` is
/// the only widget that watches it; everything else continues to watch
/// `solveProvider(...)` and rebuilds only on real state changes
/// (focus, progress, status). `SolveNotifier` still owns the canonical
/// elapsed-seconds for persistence — it reads from this provider when
/// it needs to save or persist a completion — but does not broadcast
/// per-tick state to its own watchers.
///
/// See issue #119.

@ProviderFor(SolveElapsedSeconds)
final solveElapsedSecondsProvider = SolveElapsedSecondsFamily._();

/// Live, per-second elapsed clock for the solve screen, scoped to one
/// puzzle.
///
/// **Why this exists.** Before this provider, `SolveNotifier`'s state
/// included `elapsedSeconds` and incremented it once per second via
/// `state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1))`.
/// `SolveScreen.build` watches `solveProvider(...)`, so every tick
/// invalidated the entire screen: `CrosswordGrid`, `CluePanel`,
/// `CrosswordKeyboard`, the confetti widget, and the outer `LayoutBuilder`
/// all rebuilt every second on idle. `CustomPainter.shouldRepaint`
/// suppressed the actual paint, but the Element-tree rebuild and
/// `LayoutBuilder` re-measurement still ran every second — frame-budget
/// tax on lower-end Android devices for nothing user-visible except the
/// AppBar's seconds digit.
///
/// This provider holds the ticking value in isolation. `SolveAppBar` is
/// the only widget that watches it; everything else continues to watch
/// `solveProvider(...)` and rebuilds only on real state changes
/// (focus, progress, status). `SolveNotifier` still owns the canonical
/// elapsed-seconds for persistence — it reads from this provider when
/// it needs to save or persist a completion — but does not broadcast
/// per-tick state to its own watchers.
///
/// See issue #119.
final class SolveElapsedSecondsProvider
    extends $NotifierProvider<SolveElapsedSeconds, int> {
  /// Live, per-second elapsed clock for the solve screen, scoped to one
  /// puzzle.
  ///
  /// **Why this exists.** Before this provider, `SolveNotifier`'s state
  /// included `elapsedSeconds` and incremented it once per second via
  /// `state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1))`.
  /// `SolveScreen.build` watches `solveProvider(...)`, so every tick
  /// invalidated the entire screen: `CrosswordGrid`, `CluePanel`,
  /// `CrosswordKeyboard`, the confetti widget, and the outer `LayoutBuilder`
  /// all rebuilt every second on idle. `CustomPainter.shouldRepaint`
  /// suppressed the actual paint, but the Element-tree rebuild and
  /// `LayoutBuilder` re-measurement still ran every second — frame-budget
  /// tax on lower-end Android devices for nothing user-visible except the
  /// AppBar's seconds digit.
  ///
  /// This provider holds the ticking value in isolation. `SolveAppBar` is
  /// the only widget that watches it; everything else continues to watch
  /// `solveProvider(...)` and rebuilds only on real state changes
  /// (focus, progress, status). `SolveNotifier` still owns the canonical
  /// elapsed-seconds for persistence — it reads from this provider when
  /// it needs to save or persist a completion — but does not broadcast
  /// per-tick state to its own watchers.
  ///
  /// See issue #119.
  SolveElapsedSecondsProvider._(
      {required SolveElapsedSecondsFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'solveElapsedSecondsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$solveElapsedSecondsHash();

  @override
  String toString() {
    return r'solveElapsedSecondsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SolveElapsedSeconds create() => SolveElapsedSeconds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SolveElapsedSecondsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$solveElapsedSecondsHash() =>
    r'ba984067afdbf814b4d05d339ee8f12c241ba23d';

/// Live, per-second elapsed clock for the solve screen, scoped to one
/// puzzle.
///
/// **Why this exists.** Before this provider, `SolveNotifier`'s state
/// included `elapsedSeconds` and incremented it once per second via
/// `state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1))`.
/// `SolveScreen.build` watches `solveProvider(...)`, so every tick
/// invalidated the entire screen: `CrosswordGrid`, `CluePanel`,
/// `CrosswordKeyboard`, the confetti widget, and the outer `LayoutBuilder`
/// all rebuilt every second on idle. `CustomPainter.shouldRepaint`
/// suppressed the actual paint, but the Element-tree rebuild and
/// `LayoutBuilder` re-measurement still ran every second — frame-budget
/// tax on lower-end Android devices for nothing user-visible except the
/// AppBar's seconds digit.
///
/// This provider holds the ticking value in isolation. `SolveAppBar` is
/// the only widget that watches it; everything else continues to watch
/// `solveProvider(...)` and rebuilds only on real state changes
/// (focus, progress, status). `SolveNotifier` still owns the canonical
/// elapsed-seconds for persistence — it reads from this provider when
/// it needs to save or persist a completion — but does not broadcast
/// per-tick state to its own watchers.
///
/// See issue #119.

final class SolveElapsedSecondsFamily extends $Family
    with $ClassFamilyOverride<SolveElapsedSeconds, int, int, int, String> {
  SolveElapsedSecondsFamily._()
      : super(
          retry: null,
          name: r'solveElapsedSecondsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Live, per-second elapsed clock for the solve screen, scoped to one
  /// puzzle.
  ///
  /// **Why this exists.** Before this provider, `SolveNotifier`'s state
  /// included `elapsedSeconds` and incremented it once per second via
  /// `state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1))`.
  /// `SolveScreen.build` watches `solveProvider(...)`, so every tick
  /// invalidated the entire screen: `CrosswordGrid`, `CluePanel`,
  /// `CrosswordKeyboard`, the confetti widget, and the outer `LayoutBuilder`
  /// all rebuilt every second on idle. `CustomPainter.shouldRepaint`
  /// suppressed the actual paint, but the Element-tree rebuild and
  /// `LayoutBuilder` re-measurement still ran every second — frame-budget
  /// tax on lower-end Android devices for nothing user-visible except the
  /// AppBar's seconds digit.
  ///
  /// This provider holds the ticking value in isolation. `SolveAppBar` is
  /// the only widget that watches it; everything else continues to watch
  /// `solveProvider(...)` and rebuilds only on real state changes
  /// (focus, progress, status). `SolveNotifier` still owns the canonical
  /// elapsed-seconds for persistence — it reads from this provider when
  /// it needs to save or persist a completion — but does not broadcast
  /// per-tick state to its own watchers.
  ///
  /// See issue #119.

  SolveElapsedSecondsProvider call(
    String puzzleId,
  ) =>
      SolveElapsedSecondsProvider._(argument: puzzleId, from: this);

  @override
  String toString() => r'solveElapsedSecondsProvider';
}

/// Live, per-second elapsed clock for the solve screen, scoped to one
/// puzzle.
///
/// **Why this exists.** Before this provider, `SolveNotifier`'s state
/// included `elapsedSeconds` and incremented it once per second via
/// `state = AsyncData(s.copyWith(elapsedSeconds: s.elapsedSeconds + 1))`.
/// `SolveScreen.build` watches `solveProvider(...)`, so every tick
/// invalidated the entire screen: `CrosswordGrid`, `CluePanel`,
/// `CrosswordKeyboard`, the confetti widget, and the outer `LayoutBuilder`
/// all rebuilt every second on idle. `CustomPainter.shouldRepaint`
/// suppressed the actual paint, but the Element-tree rebuild and
/// `LayoutBuilder` re-measurement still ran every second — frame-budget
/// tax on lower-end Android devices for nothing user-visible except the
/// AppBar's seconds digit.
///
/// This provider holds the ticking value in isolation. `SolveAppBar` is
/// the only widget that watches it; everything else continues to watch
/// `solveProvider(...)` and rebuilds only on real state changes
/// (focus, progress, status). `SolveNotifier` still owns the canonical
/// elapsed-seconds for persistence — it reads from this provider when
/// it needs to save or persist a completion — but does not broadcast
/// per-tick state to its own watchers.
///
/// See issue #119.

abstract class _$SolveElapsedSeconds extends $Notifier<int> {
  late final _$args = ref.$arg as String;
  String get puzzleId => _$args;

  int build(
    String puzzleId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
