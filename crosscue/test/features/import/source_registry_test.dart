import 'package:crosscue/features/import/data/sources/local_import_source.dart';
import 'package:crosscue/features/import/data/sources/source_registry.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub sources used by multiple tests
// ---------------------------------------------------------------------------

class _StubSource implements PuzzleSource {
  const _StubSource({
    required this.id,
    required this.licenseStatus,
    this.enabled = true,
  });

  @override
  final String id;

  @override
  String get displayName => id;

  @override
  final LicenseStatus licenseStatus;

  @override
  final bool enabled;

  @override
  bool get attributionRequired => false;

  @override
  bool get commercialUseAllowed => true;

  @override
  bool get rawPayloadRetention => false;
}

const _userImportSource = _StubSource(
  id: 'stub_user_import',
  licenseStatus: LicenseStatus.userImport,
);

const _openLicenseSource = _StubSource(
  id: 'stub_open_license',
  licenseStatus: LicenseStatus.openLicense,
);

const _explicitPermissionSource = _StubSource(
  id: 'stub_explicit',
  licenseStatus: LicenseStatus.explicitPermission,
);

const _needsReviewSource = _StubSource(
  id: 'stub_needs_review',
  licenseStatus: LicenseStatus.needsReview,
);

const _prohibitedSource = _StubSource(
  id: 'stub_prohibited',
  licenseStatus: LicenseStatus.prohibited,
);

const _disabledSource = _StubSource(
  id: 'stub_disabled',
  licenseStatus: LicenseStatus.openLicense,
  enabled: false,
);

// ---------------------------------------------------------------------------
// SourceRegistry tests
// ---------------------------------------------------------------------------

void main() {
  group('SourceRegistry', () {
    // ── Registration ──────────────────────────────────────────────────────

    group('register', () {
      test('accepts userImport source', () {
        final reg = SourceRegistry();
        expect(() => reg.register(_userImportSource), returnsNormally);
        expect(reg.getSource('stub_user_import'), equals(_userImportSource));
      });

      test('accepts openLicense source', () {
        final reg = SourceRegistry();
        expect(() => reg.register(_openLicenseSource), returnsNormally);
      });

      test('accepts explicitPermission source', () {
        final reg = SourceRegistry();
        expect(() => reg.register(_explicitPermissionSource), returnsNormally);
      });

      test('accepts needsReview source (tracked but not enabled)', () {
        final reg = SourceRegistry();
        expect(() => reg.register(_needsReviewSource), returnsNormally);
        expect(reg.getSource('stub_needs_review'), isNotNull);
      });

      test('throws SourceRegistrationException for prohibited source', () {
        final reg = SourceRegistry();
        expect(
          () => reg.register(_prohibitedSource),
          throwsA(isA<SourceRegistrationException>()),
        );
      });

      test('exception message names the offending source id', () {
        final reg = SourceRegistry();
        try {
          reg.register(_prohibitedSource);
          fail('Expected exception');
        } on SourceRegistrationException catch (e) {
          expect(e.message, contains('stub_prohibited'));
        }
      });
    });

    // ── getSource ─────────────────────────────────────────────────────────

    group('getSource', () {
      test('returns null for unknown id', () {
        final reg = SourceRegistry()..register(_userImportSource);
        expect(reg.getSource('unknown'), isNull);
      });

      test('returns the correct source for a known id', () {
        final reg = SourceRegistry()..register(_userImportSource);
        expect(reg.getSource('stub_user_import'), equals(_userImportSource));
      });
    });

    // ── allSources ────────────────────────────────────────────────────────

    group('allSources', () {
      test('includes needsReview sources', () {
        final reg = SourceRegistry()
          ..register(_userImportSource)
          ..register(_needsReviewSource);
        expect(reg.allSources.length, equals(2));
      });
    });

    // ── enabledSources ────────────────────────────────────────────────────

    group('enabledSources', () {
      test('empty when no sources registered', () {
        expect(SourceRegistry().enabledSources, isEmpty);
      });

      test('includes userImport when enabled', () {
        final reg = SourceRegistry()..register(_userImportSource);
        expect(reg.enabledSources, contains(_userImportSource));
      });

      test('includes openLicense when enabled', () {
        final reg = SourceRegistry()..register(_openLicenseSource);
        expect(reg.enabledSources, contains(_openLicenseSource));
      });

      test('includes explicitPermission when enabled', () {
        final reg = SourceRegistry()..register(_explicitPermissionSource);
        expect(reg.enabledSources, contains(_explicitPermissionSource));
      });

      test('excludes needsReview source', () {
        final reg = SourceRegistry()..register(_needsReviewSource);
        expect(reg.enabledSources, isEmpty);
      });

      test('excludes disabled source', () {
        final reg = SourceRegistry()..register(_disabledSource);
        expect(reg.enabledSources, isEmpty);
      });

      test('returns only cleared+enabled sources from a mixed registry', () {
        final reg = SourceRegistry()
          ..register(_userImportSource) // should be included
          ..register(_openLicenseSource) // should be included
          ..register(_needsReviewSource) // should be excluded
          ..register(_disabledSource); // should be excluded
        final ids = reg.enabledSources.map((s) => s.id).toSet();
        expect(ids, equals({'stub_user_import', 'stub_open_license'}));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // LocalImportSource
  // ---------------------------------------------------------------------------

  group('LocalImportSource', () {
    const source = LocalImportSource();

    test('id is "local_import"', () {
      expect(source.id, equals('local_import'));
    });

    test('licenseStatus is userImport', () {
      expect(source.licenseStatus, equals(LicenseStatus.userImport));
    });

    test('is enabled', () {
      expect(source.enabled, isTrue);
    });

    test('rawPayloadRetention is false', () {
      expect(source.rawPayloadRetention, isFalse);
    });

    test('can be registered without error', () {
      final reg = SourceRegistry();
      expect(() => reg.register(source), returnsNormally);
    });

    test('appears in enabledSources after registration', () {
      final reg = SourceRegistry()..register(source);
      expect(reg.enabledSources.map((s) => s.id), contains('local_import'));
    });
  });
}
