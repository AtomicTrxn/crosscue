// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-memory onboarding flag. Sprint 5 replaces this with the AppSettingsDao.

@ProviderFor(OnboardingCompleted)
final onboardingCompletedProvider = OnboardingCompletedProvider._();

/// In-memory onboarding flag. Sprint 5 replaces this with the AppSettingsDao.
final class OnboardingCompletedProvider
    extends $NotifierProvider<OnboardingCompleted, bool> {
  /// In-memory onboarding flag. Sprint 5 replaces this with the AppSettingsDao.
  OnboardingCompletedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'onboardingCompletedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  OnboardingCompleted create() => OnboardingCompleted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingCompletedHash() =>
    r'4fdfcb45229215b4ec77b380c867ec24ef14bb99';

/// In-memory onboarding flag. Sprint 5 replaces this with the AppSettingsDao.

abstract class _$OnboardingCompleted extends $Notifier<bool> {
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

/// Reads whether the user has completed onboarding.
/// Sprint 5: replace body with a real AppSettingsDao read.

@ProviderFor(hasSeenOnboarding)
final hasSeenOnboardingProvider = HasSeenOnboardingProvider._();

/// Reads whether the user has completed onboarding.
/// Sprint 5: replace body with a real AppSettingsDao read.

final class HasSeenOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Reads whether the user has completed onboarding.
  /// Sprint 5: replace body with a real AppSettingsDao read.
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

String _$hasSeenOnboardingHash() => r'1fb2ff611f93d6e0c511373c09be2a82c7f46b08';

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  AppRouterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appRouterProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'0e445be04148bf6f2186faf4633fe94372545c2e';
