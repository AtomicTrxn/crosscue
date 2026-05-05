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
