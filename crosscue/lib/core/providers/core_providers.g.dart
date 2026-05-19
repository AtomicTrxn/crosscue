// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App version string in the form `v1.2.3`, derived from [PackageInfo].
///
/// Returns a fallback `'vunknown'` on platforms where [PackageInfo] is
/// unavailable.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// App version string in the form `v1.2.3`, derived from [PackageInfo].
///
/// Returns a fallback `'vunknown'` on platforms where [PackageInfo] is
/// unavailable.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// App version string in the form `v1.2.3`, derived from [PackageInfo].
  ///
  /// Returns a fallback `'vunknown'` on platforms where [PackageInfo] is
  /// unavailable.
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

String _$appVersionHash() => r'68c7de8153f7d44e856313643ce74079bcd8c045';

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

/// Cloud transport for sync. Resolves to:
/// - [ICloudSyncTransport] on iOS — safe even when the iCloud entitlement
///   isn't configured yet (the native handler returns nil from `account()`,
///   so [SyncOrchestrator] stays in `SyncSignedOut` and writes nothing).
/// - [NoOpSyncTransport] everywhere else, until the Google Drive transport
///   lands as Phase 3 (see `docs/architecture/sync-progress.md`).
///
/// Skipped during Flutter unit tests (`kIsWeb` check covers web; the
/// `Platform.isIOS` branch reads from `dart:io` which is unavailable on web
/// but works fine in vm-based tests — those override the provider directly).

@ProviderFor(syncTransport)
final syncTransportProvider = SyncTransportProvider._();

/// Cloud transport for sync. Resolves to:
/// - [ICloudSyncTransport] on iOS — safe even when the iCloud entitlement
///   isn't configured yet (the native handler returns nil from `account()`,
///   so [SyncOrchestrator] stays in `SyncSignedOut` and writes nothing).
/// - [NoOpSyncTransport] everywhere else, until the Google Drive transport
///   lands as Phase 3 (see `docs/architecture/sync-progress.md`).
///
/// Skipped during Flutter unit tests (`kIsWeb` check covers web; the
/// `Platform.isIOS` branch reads from `dart:io` which is unavailable on web
/// but works fine in vm-based tests — those override the provider directly).

final class SyncTransportProvider
    extends $FunctionalProvider<SyncTransport, SyncTransport, SyncTransport>
    with $Provider<SyncTransport> {
  /// Cloud transport for sync. Resolves to:
  /// - [ICloudSyncTransport] on iOS — safe even when the iCloud entitlement
  ///   isn't configured yet (the native handler returns nil from `account()`,
  ///   so [SyncOrchestrator] stays in `SyncSignedOut` and writes nothing).
  /// - [NoOpSyncTransport] everywhere else, until the Google Drive transport
  ///   lands as Phase 3 (see `docs/architecture/sync-progress.md`).
  ///
  /// Skipped during Flutter unit tests (`kIsWeb` check covers web; the
  /// `Platform.isIOS` branch reads from `dart:io` which is unavailable on web
  /// but works fine in vm-based tests — those override the provider directly).
  SyncTransportProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'syncTransportProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$syncTransportHash();

  @$internal
  @override
  $ProviderElement<SyncTransport> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncTransport create(Ref ref) {
    return syncTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncTransport>(value),
    );
  }
}

String _$syncTransportHash() => r'97b8dbb02800be63f339327995de880e8fd811e1';

/// Sync orchestrator. Reads the current [syncTransport] and wires up the
/// per-namespace adapters against the shared [appDatabase].

@ProviderFor(syncOrchestrator)
final syncOrchestratorProvider = SyncOrchestratorProvider._();

/// Sync orchestrator. Reads the current [syncTransport] and wires up the
/// per-namespace adapters against the shared [appDatabase].

final class SyncOrchestratorProvider extends $FunctionalProvider<
    SyncOrchestrator,
    SyncOrchestrator,
    SyncOrchestrator> with $Provider<SyncOrchestrator> {
  /// Sync orchestrator. Reads the current [syncTransport] and wires up the
  /// per-namespace adapters against the shared [appDatabase].
  SyncOrchestratorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'syncOrchestratorProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$syncOrchestratorHash();

  @$internal
  @override
  $ProviderElement<SyncOrchestrator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncOrchestrator create(Ref ref) {
    return syncOrchestrator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncOrchestrator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncOrchestrator>(value),
    );
  }
}

String _$syncOrchestratorHash() => r'2a33ae58d6e8985111a731a040986bedcc7c567b';

/// Entitlement service — all features free.

@ProviderFor(entitlementService)
final entitlementServiceProvider = EntitlementServiceProvider._();

/// Entitlement service — all features free.

final class EntitlementServiceProvider extends $FunctionalProvider<
    EntitlementService,
    EntitlementService,
    EntitlementService> with $Provider<EntitlementService> {
  /// Entitlement service — all features free.
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

/// Crash reporter — local-only; no data leaves the device.

@ProviderFor(crashReporter)
final crashReporterProvider = CrashReporterProvider._();

/// Crash reporter — local-only; no data leaves the device.

final class CrashReporterProvider
    extends $FunctionalProvider<CrashReporter, CrashReporter, CrashReporter>
    with $Provider<CrashReporter> {
  /// Crash reporter — local-only; no data leaves the device.
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

String _$soundPlayerHash() => r'1e95e0f94bea2129637316e22403fd134eabe3d8';
