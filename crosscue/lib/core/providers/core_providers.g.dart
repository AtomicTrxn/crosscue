// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

/// Crash reporter — no-op until Sentry is wired (post-MVP).

@ProviderFor(crashReporter)
final crashReporterProvider = CrashReporterProvider._();

/// Crash reporter — no-op until Sentry is wired (post-MVP).

final class CrashReporterProvider
    extends $FunctionalProvider<CrashReporter, CrashReporter, CrashReporter>
    with $Provider<CrashReporter> {
  /// Crash reporter — no-op until Sentry is wired (post-MVP).
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

String _$crashReporterHash() => r'62ef201ad5b6fd2a7a8e5b4f178a352463c998dd';
