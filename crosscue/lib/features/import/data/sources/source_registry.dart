import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';

/// Thrown by [SourceRegistry.register] when a caller attempts to register a
/// source whose [LicenseStatus] is [LicenseStatus.prohibited].
class SourceRegistrationException implements Exception {
  const SourceRegistrationException(this.message);

  final String message;

  @override
  String toString() => 'SourceRegistrationException: $message';
}

/// Registry of all [PuzzleSource] instances known to the app.
///
/// Enforces the legal guardrail
/// - [LicenseStatus.prohibited] sources cannot be registered at all.
/// - [LicenseStatus.needsReview] sources can be registered (for tracking)
///   but are excluded from [enabledSources].
/// - Only [LicenseStatus.userImport], [LicenseStatus.explicitPermission], and
///   [LicenseStatus.openLicense] sources appear in [enabledSources].
class SourceRegistry {
  SourceRegistry();

  final _sources = <String, PuzzleSource>{};

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Registers [source] with the registry.
  ///
  /// Throws [SourceRegistrationException] if [source.licenseStatus] is
  /// [LicenseStatus.prohibited] — prohibited sources must never be registered
  /// as that would make their ID available to storage / download code.
  void register(PuzzleSource source) {
    if (source.licenseStatus == LicenseStatus.prohibited) {
      throw SourceRegistrationException(
        'Cannot register prohibited source "${source.id}". '
        'Only userImport, openLicense, explicitPermission, or needsReview '
        'sources may be registered.',
      );
    }
    _sources[source.id] = source;
  }

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------

  /// Returns the source with [id], or null if not registered.
  PuzzleSource? getSource(String id) => _sources[id];

  /// All registered sources (regardless of status or enabled flag).
  List<PuzzleSource> get allSources =>
      List.unmodifiable(_sources.values.toList());

  /// Registered sources that are both [enabled] and legally cleared for use.
  ///
  /// Excludes [LicenseStatus.prohibited] (can't be registered anyway) and
  /// [LicenseStatus.needsReview] (pending legal sign-off).
  List<PuzzleSource> get enabledSources => _sources.values
      .where(
        (s) =>
            s.enabled &&
            s.licenseStatus != LicenseStatus.prohibited &&
            s.licenseStatus != LicenseStatus.needsReview,
      )
      .toList();
}
