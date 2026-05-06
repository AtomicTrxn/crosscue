// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appSettings)
final appSettingsProvider = AppSettingsProvider._();

final class AppSettingsProvider extends $FunctionalProvider<
    AppSettingsRepository,
    AppSettingsRepository,
    AppSettingsRepository> with $Provider<AppSettingsRepository> {
  AppSettingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appSettingsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appSettingsHash();

  @$internal
  @override
  $ProviderElement<AppSettingsRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppSettingsRepository create(Ref ref) {
    return appSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettingsRepository>(value),
    );
  }
}

String _$appSettingsHash() => r'26d85c18a53425b14f17ad7f511d20952773f871';

/// Whether the user has seen the onboarding flow.
/// Used by the router redirect; invalidated after onboarding completes.

@ProviderFor(hasSeenOnboarding)
final hasSeenOnboardingProvider = HasSeenOnboardingProvider._();

/// Whether the user has seen the onboarding flow.
/// Used by the router redirect; invalidated after onboarding completes.

final class HasSeenOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the user has seen the onboarding flow.
  /// Used by the router redirect; invalidated after onboarding completes.
  HasSeenOnboardingProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'hasSeenOnboardingProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$hasSeenOnboardingHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasSeenOnboarding(ref);
  }
}

String _$hasSeenOnboardingHash() => r'6b6f4c7214866437766731a72259ee43661c1acb';

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

final class ThemeModeNotifierProvider
    extends $AsyncNotifierProvider<ThemeModeNotifier, ThemeMode> {
  ThemeModeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeModeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();
}

String _$themeModeNotifierHash() => r'5ae7518f6a9c8ee6de8b16585eebbd5995ddbc1c';

abstract class _$ThemeModeNotifier extends $AsyncNotifier<ThemeMode> {
  FutureOr<ThemeMode> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ThemeMode>, ThemeMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<ThemeMode>, ThemeMode>,
        AsyncValue<ThemeMode>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(HapticsEnabledNotifier)
final hapticsEnabledProvider = HapticsEnabledNotifierProvider._();

final class HapticsEnabledNotifierProvider
    extends $AsyncNotifierProvider<HapticsEnabledNotifier, bool> {
  HapticsEnabledNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'hapticsEnabledProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$hapticsEnabledNotifierHash();

  @$internal
  @override
  HapticsEnabledNotifier create() => HapticsEnabledNotifier();
}

String _$hapticsEnabledNotifierHash() =>
    r'69a2b830d5aa06b1841fe1446400bbb582872330';

abstract class _$HapticsEnabledNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ColorblindModeNotifier)
final colorblindModeProvider = ColorblindModeNotifierProvider._();

final class ColorblindModeNotifierProvider
    extends $AsyncNotifierProvider<ColorblindModeNotifier, bool> {
  ColorblindModeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'colorblindModeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$colorblindModeNotifierHash();

  @$internal
  @override
  ColorblindModeNotifier create() => ColorblindModeNotifier();
}

String _$colorblindModeNotifierHash() =>
    r'25d28a29bd03f1df4926de9944387f186e94e466';

abstract class _$ColorblindModeNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SoundsEnabledNotifier)
final soundsEnabledProvider = SoundsEnabledNotifierProvider._();

final class SoundsEnabledNotifierProvider
    extends $AsyncNotifierProvider<SoundsEnabledNotifier, bool> {
  SoundsEnabledNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'soundsEnabledProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$soundsEnabledNotifierHash();

  @$internal
  @override
  SoundsEnabledNotifier create() => SoundsEnabledNotifier();
}

String _$soundsEnabledNotifierHash() =>
    r'fe828fed6f4edfb587c86d13fa2ed17485932ceb';

abstract class _$SoundsEnabledNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SkipFilledCellsNotifier)
final skipFilledCellsProvider = SkipFilledCellsNotifierProvider._();

final class SkipFilledCellsNotifierProvider
    extends $AsyncNotifierProvider<SkipFilledCellsNotifier, bool> {
  SkipFilledCellsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'skipFilledCellsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$skipFilledCellsNotifierHash();

  @$internal
  @override
  SkipFilledCellsNotifier create() => SkipFilledCellsNotifier();
}

String _$skipFilledCellsNotifierHash() =>
    r'1e90978d21c9a19c0b47dd38ec2177813f337928';

abstract class _$SkipFilledCellsNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(PuzzleReminderNotifier)
final puzzleReminderProvider = PuzzleReminderNotifierProvider._();

final class PuzzleReminderNotifierProvider
    extends $AsyncNotifierProvider<PuzzleReminderNotifier, bool> {
  PuzzleReminderNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'puzzleReminderProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$puzzleReminderNotifierHash();

  @$internal
  @override
  PuzzleReminderNotifier create() => PuzzleReminderNotifier();
}

String _$puzzleReminderNotifierHash() =>
    r'302f752eb3932a5c589d1be7893ff8711f6bfff4';

abstract class _$PuzzleReminderNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(StreakReminderNotifier)
final streakReminderProvider = StreakReminderNotifierProvider._();

final class StreakReminderNotifierProvider
    extends $AsyncNotifierProvider<StreakReminderNotifier, bool> {
  StreakReminderNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'streakReminderProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$streakReminderNotifierHash();

  @$internal
  @override
  StreakReminderNotifier create() => StreakReminderNotifier();
}

String _$streakReminderNotifierHash() =>
    r'204c1db39aa43bddb5cd62b11695b9885bb852c9';

abstract class _$StreakReminderNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CrashReportingNotifier)
final crashReportingProvider = CrashReportingNotifierProvider._();

final class CrashReportingNotifierProvider
    extends $AsyncNotifierProvider<CrashReportingNotifier, bool> {
  CrashReportingNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crashReportingProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crashReportingNotifierHash();

  @$internal
  @override
  CrashReportingNotifier create() => CrashReportingNotifier();
}

String _$crashReportingNotifierHash() =>
    r'06ff5b4d225d0362d8ea92552f56d3409da3dc83';

abstract class _$CrashReportingNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
