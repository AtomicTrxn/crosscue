import '../../../solve/domain/models/enums.dart';
import '../../domain/repositories/puzzle_source.dart';

/// The built-in source representing user-supplied local files (.puz / .ipuz).
///
/// This source wraps the existing [PuzParser] and [IpuzParser] via the import
/// pipeline.  It is the only Phase 1 source and is always enabled.
///
/// License status: [LicenseStatus.userImport] — the user owns the file they
/// import, so the app is not redistributing any publisher-owned content.
class LocalImportSource implements PuzzleSource {
  const LocalImportSource();

  @override
  String get id => 'local_import';

  @override
  String get displayName => 'Local Import';

  @override
  LicenseStatus get licenseStatus => LicenseStatus.userImport;

  @override
  bool get enabled => true;

  /// Attribution is not required for user-imported files in the aggregate UI,
  /// but parsed author/copyright metadata is preserved and shown per puzzle.
  @override
  bool get attributionRequired => false;

  /// User-imported files are private to the device; commercial use of the app
  /// does not involve redistribution, so commercial use is compatible.
  @override
  bool get commercialUseAllowed => true;

  /// Raw .puz / .ipuz bytes are not retained — only the canonical JSON and
  /// parsed metadata are stored.
  @override
  bool get rawPayloadRetention => false;
}
