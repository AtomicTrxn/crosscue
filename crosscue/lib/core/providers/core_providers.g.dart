// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App version string in the form `v1.2.3`, derived from [PackageInfo].
///
/// Returns a fallback `'v—'` on platforms where [PackageInfo] is unavailable.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// App version string in the form `v1.2.3`, derived from [PackageInfo].
///
/// Returns a fallback `'v—'` on platforms where [PackageInfo] is unavailable.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// App version string in the form `v1.2.3`, derived from [PackageInfo].
  ///
  /// Returns a fallback `'v—'` on platforms where [PackageInfo] is unavailable.
  AppVersionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appVersionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'f828c62d453bc5def96d4002a8a3793f42dd82b8';

/// Shared [Dio] HTTP client for all network sources.

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Shared [Dio] HTTP client for all network sources.

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Shared [Dio] HTTP client for all network sources.
  DioProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'dioProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'c566f5406b2dcd58da3b88d9795cdd125d7bd74e';

/// The single shared [AppDatabase] instance for the app lifetime.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The single shared [AppDatabase] instance for the app lifetime.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The single shared [AppDatabase] instance for the app lifetime.
  AppDatabaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appDatabaseProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'98a09c6cfd43966155dfbdb0787fa18c85438e13';

/// Phase 1 sync adapter — no-op (local only).

@ProviderFor(syncAdapter)
final syncAdapterProvider = SyncAdapterProvider._();

/// Phase 1 sync adapter — no-op (local only).

final class SyncAdapterProvider
    extends $FunctionalProvider<SyncAdapter, SyncAdapter, SyncAdapter>
    with $Provider<SyncAdapter> {
  /// Phase 1 sync adapter — no-op (local only).
  SyncAdapterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'syncAdapterProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$syncAdapterHash();

  @$internal
  @override
  $ProviderElement<SyncAdapter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncAdapter create(Ref ref) {
    return syncAdapter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncAdapter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncAdapter>(value),
    );
  }
}

String _$syncAdapterHash() => r'a5c9e2e0cfa9f13076d953a7029eef2d423b81e5';

/// Phase 1 entitlement service — all features free.

@ProviderFor(entitlementService)
final entitlementServiceProvider = EntitlementServiceProvider._();

/// Phase 1 entitlement service — all features free.

final class EntitlementServiceProvider extends $FunctionalProvider<
    EntitlementService,
    EntitlementService,
    EntitlementService> with $Provider<EntitlementService> {
  /// Phase 1 entitlement service — all features free.
  EntitlementServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'entitlementServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$entitlementServiceHash();

  @$internal
  @override
  $ProviderElement<EntitlementService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EntitlementService create(Ref ref) {
    return entitlementService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntitlementService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntitlementService>(value),
    );
  }
}

String _$entitlementServiceHash() =>
    r'8b777f0857c0b0277e787bd83e737e8c2d1556d2';

/// Crash reporter — local-only in Phase 1; no data leaves the device.

@ProviderFor(crashReporter)
final crashReporterProvider = CrashReporterProvider._();

/// Crash reporter — local-only in Phase 1; no data leaves the device.

final class CrashReporterProvider
    extends $FunctionalProvider<CrashReporter, CrashReporter, CrashReporter>
    with $Provider<CrashReporter> {
  /// Crash reporter — local-only in Phase 1; no data leaves the device.
  CrashReporterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crashReporterProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crashReporterHash();

  @$internal
  @override
  $ProviderElement<CrashReporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CrashReporter create(Ref ref) {
    return crashReporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrashReporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrashReporter>(value),
    );
  }
}

String _$crashReporterHash() => r'c86a5ab1826f6068ee77a662ee3b040bdd1aa8fb';

@ProviderFor(soundPlayer)
final soundPlayerProvider = SoundPlayerProvider._();

final class SoundPlayerProvider
    extends $FunctionalProvider<SoundPlayer, SoundPlayer, SoundPlayer>
    with $Provider<SoundPlayer> {
  SoundPlayerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'soundPlayerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$soundPlayerHash();

  @$internal
  @override
  $ProviderElement<SoundPlayer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SoundPlayer create(Ref ref) {
    return soundPlayer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoundPlayer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoundPlayer>(value),
    );
  }
}

String _$soundPlayerHash() => r'e8a014932109bf01b02f58abdf475f9b2e7cc575';

/// Registers a [WidgetsBindingObserver] that triggers the Crosshare
/// auto-download whenever the app returns to the foreground.
///
/// Kept alive for the full app lifetime. Reads [crosshareAutoDownloadService]
/// (also keepAlive) rather than holding a direct reference, so the service
/// provider is only created once.
///
/// Must be eagerly initialised in [CrosscueApp] (via `ref.read`) so the
/// observer is registered before the first lifecycle event fires.

@ProviderFor(appLifecycleObserver)
final appLifecycleObserverProvider = AppLifecycleObserverProvider._();

/// Registers a [WidgetsBindingObserver] that triggers the Crosshare
/// auto-download whenever the app returns to the foreground.
///
/// Kept alive for the full app lifetime. Reads [crosshareAutoDownloadService]
/// (also keepAlive) rather than holding a direct reference, so the service
/// provider is only created once.
///
/// Must be eagerly initialised in [CrosscueApp] (via `ref.read`) so the
/// observer is registered before the first lifecycle event fires.

final class AppLifecycleObserverProvider
    extends $FunctionalProvider<void, void, void> with $Provider<void> {
  /// Registers a [WidgetsBindingObserver] that triggers the Crosshare
  /// auto-download whenever the app returns to the foreground.
  ///
  /// Kept alive for the full app lifetime. Reads [crosshareAutoDownloadService]
  /// (also keepAlive) rather than holding a direct reference, so the service
  /// provider is only created once.
  ///
  /// Must be eagerly initialised in [CrosscueApp] (via `ref.read`) so the
  /// observer is registered before the first lifecycle event fires.
  AppLifecycleObserverProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appLifecycleObserverProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appLifecycleObserverHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return appLifecycleObserver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$appLifecycleObserverHash() =>
    r'dfd253fa853b98e4c60f89d9a976da9265f3ac97';
