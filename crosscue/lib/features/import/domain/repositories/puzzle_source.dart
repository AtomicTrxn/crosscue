import 'package:crosscue/core/domain/models/enums.dart';

/// Describes a puzzle source and its legal / capability metadata.
///
/// Every source that can provide puzzles to the app must be registered in
/// [SourceRegistry].  The registry enforces that only sources with a safe
/// [LicenseStatus] can be activated at runtime
///
///
/// Phase 1 only has [LocalImportSource].  Future network sources (e.g.
/// licensed daily feeds) will implement this interface and be gated behind
/// [LicenseStatus.explicitPermission] or [LicenseStatus.openLicense].
abstract class PuzzleSource {
  /// Stable identifier that must match the `source_id` column in the DB.
  String get id;

  /// Human-readable name shown in attribution and settings UI.
  String get displayName;

  /// Legal status of this source guardrails.
  LicenseStatus get licenseStatus;

  /// Public terms or license URL reviewed for this source, when applicable.
  String? get licenseUrl;

  /// Permission contact, agreement reference, or owner contact for review.
  String? get permissionContact;

  /// Human-readable cache policy for puzzle bodies and downloaded payloads.
  String get cachePolicy;

  /// ISO-8601 date of the latest human legal review, or null if unreviewed.
  String? get lastLegalReviewAt;

  /// Human notes, unresolved risks, or source-specific implementation limits.
  String? get reviewNotes;

  /// Whether the source is currently active.  Disabled sources are not
  /// offered to the user even if their [licenseStatus] is cleared.
  bool get enabled;

  /// Whether the source/constructor copyright line must be shown to the user.
  bool get attributionRequired;

  /// Whether commercial-use app monetization is compatible with this source.
  bool get commercialUseAllowed;

  /// Whether raw downloaded payload bytes may be retained in the database.
  /// Set to false for sources whose terms prohibit caching beyond display.
  bool get rawPayloadRetention;
}
