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

String _$appSettingsHash() => r'9296103eb8a4b2218e21bff404c929473c8d03c9';

/// The frozen boot-time snapshot of every sync-readable setting.
///
/// Must be overridden in `main()` (and in tests) with a value loaded from the
/// real repository. The sync notifiers below seed their initial state from
/// this provider — see `BootSettings`.

@ProviderFor(bootSettings)
final bootSettingsProvider = BootSettingsProvider._();

/// The frozen boot-time snapshot of every sync-readable setting.
///
/// Must be overridden in `main()` (and in tests) with a value loaded from the
/// real repository. The sync notifiers below seed their initial state from
/// this provider — see `BootSettings`.

final class BootSettingsProvider
    extends $FunctionalProvider<BootSettings, BootSettings, BootSettings>
    with $Provider<BootSettings> {
  /// The frozen boot-time snapshot of every sync-readable setting.
  ///
  /// Must be overridden in `main()` (and in tests) with a value loaded from the
  /// real repository. The sync notifiers below seed their initial state from
  /// this provider — see `BootSettings`.
  BootSettingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bootSettingsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bootSettingsHash();

  @$internal
  @override
  $ProviderElement<BootSettings> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BootSettings create(Ref ref) {
    return bootSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BootSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BootSettings>(value),
    );
  }
}

String _$bootSettingsHash() => r'559c90eb5d4b71abc7f70900f86ba9f85a32bc91';

@ProviderFor(HasSeenOnboarding)
final hasSeenOnboardingProvider = HasSeenOnboardingProvider._();

final class HasSeenOnboardingProvider
    extends $NotifierProvider<HasSeenOnboarding, bool> {
  HasSeenOnboardingProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'hasSeenOnboardingProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$hasSeenOnboardingHash();

  @$internal
  @override
  HasSeenOnboarding create() => HasSeenOnboarding();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasSeenOnboardingHash() => r'd54b5d0248238e9433df99f78fc58cc2dcb36dd4';

abstract class _$HasSeenOnboarding extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

final class ThemeModeNotifierProvider
    extends $NotifierProvider<ThemeModeNotifier, AppThemeMode> {
  ThemeModeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeModeProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeMode>(value),
    );
  }
}

String _$themeModeNotifierHash() => r'af067ee5047f32c8976564e55f310e87681e3289';

abstract class _$ThemeModeNotifier extends $Notifier<AppThemeMode> {
  AppThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppThemeMode, AppThemeMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AppThemeMode, AppThemeMode>,
        AppThemeMode,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(HapticsEnabled)
final hapticsEnabledProvider = HapticsEnabledProvider._();

final class HapticsEnabledProvider
    extends $NotifierProvider<HapticsEnabled, bool> {
  HapticsEnabledProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'hapticsEnabledProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$hapticsEnabledHash();

  @$internal
  @override
  HapticsEnabled create() => HapticsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hapticsEnabledHash() => r'231fe877583941bdd29525c3c548079a2e52deae';

abstract class _$HapticsEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SoundsEnabled)
final soundsEnabledProvider = SoundsEnabledProvider._();

final class SoundsEnabledProvider
    extends $NotifierProvider<SoundsEnabled, bool> {
  SoundsEnabledProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'soundsEnabledProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$soundsEnabledHash();

  @$internal
  @override
  SoundsEnabled create() => SoundsEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$soundsEnabledHash() => r'7bcfa56241c5ccc97a5606d33c4da2626279fc11';

abstract class _$SoundsEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ColorblindModeNotifier)
final colorblindModeProvider = ColorblindModeNotifierProvider._();

final class ColorblindModeNotifierProvider
    extends $NotifierProvider<ColorblindModeNotifier, ColorblindMode> {
  ColorblindModeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'colorblindModeProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$colorblindModeNotifierHash();

  @$internal
  @override
  ColorblindModeNotifier create() => ColorblindModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ColorblindMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ColorblindMode>(value),
    );
  }
}

String _$colorblindModeNotifierHash() =>
    r'8be276cfd678c6bd2f3acaada013e3d9610c1f7d';

abstract class _$ColorblindModeNotifier extends $Notifier<ColorblindMode> {
  ColorblindMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ColorblindMode, ColorblindMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ColorblindMode, ColorblindMode>,
        ColorblindMode,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SkipFilledCells)
final skipFilledCellsProvider = SkipFilledCellsProvider._();

final class SkipFilledCellsProvider
    extends $NotifierProvider<SkipFilledCells, bool> {
  SkipFilledCellsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'skipFilledCellsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$skipFilledCellsHash();

  @$internal
  @override
  SkipFilledCells create() => SkipFilledCells();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$skipFilledCellsHash() => r'abe81f610a94acb0a86d9348b88d1a06f65c86c1';

abstract class _$SkipFilledCells extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CrashReporting)
final crashReportingProvider = CrashReportingProvider._();

final class CrashReportingProvider
    extends $NotifierProvider<CrashReporting, bool> {
  CrashReportingProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crashReportingProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crashReportingHash();

  @$internal
  @override
  CrashReporting create() => CrashReporting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$crashReportingHash() => r'29e287d95f7182c39bb6eff5fc962f52d302e6a3';

abstract class _$CrashReporting extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CrosshareAutoDownload)
final crosshareAutoDownloadProvider = CrosshareAutoDownloadProvider._();

final class CrosshareAutoDownloadProvider
    extends $NotifierProvider<CrosshareAutoDownload, bool> {
  CrosshareAutoDownloadProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crosshareAutoDownloadProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crosshareAutoDownloadHash();

  @$internal
  @override
  CrosshareAutoDownload create() => CrosshareAutoDownload();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$crosshareAutoDownloadHash() =>
    r'e34e25c4190aaf10775f6c19632855f09496a00f';

abstract class _$CrosshareAutoDownload extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(crosshareLastDownloadedDate)
final crosshareLastDownloadedDateProvider =
    CrosshareLastDownloadedDateProvider._();

final class CrosshareLastDownloadedDateProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  CrosshareLastDownloadedDateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crosshareLastDownloadedDateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crosshareLastDownloadedDateHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return crosshareLastDownloadedDate(ref);
  }
}

String _$crosshareLastDownloadedDateHash() =>
    r'cf58c3867a7a18b9ecb88387e691a7d8a5c2eba4';

@ProviderFor(crosshareLastAttemptStatus)
final crosshareLastAttemptStatusProvider =
    CrosshareLastAttemptStatusProvider._();

final class CrosshareLastAttemptStatusProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  CrosshareLastAttemptStatusProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crosshareLastAttemptStatusProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crosshareLastAttemptStatusHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return crosshareLastAttemptStatus(ref);
  }
}

String _$crosshareLastAttemptStatusHash() =>
    r'1d8669b93d76b129265d5569303f1f2136f1099d';
