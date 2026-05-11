import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/import/data/sources/crosshare_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Source Policy Regression Tests', () {
    test('Crosshare source status matches CONVENTIONS.md approval', () {
      // CONVENTIONS.md line ~356 documents Crosshare as:
      // "Approved 2026-05-10. Each puzzle author-attributed on Crosshare;
      // app links to source. User-generated content with perpetual offline
      // storage accepted per legal review."
      //
      // This test ensures code and docs cannot drift:
      const source = CrosshareSource();

      expect(
        source.licenseStatus,
        LicenseStatus.openLicense,
        reason: 'Crosshare is legally approved as openLicense. '
            'If this fails, CONVENTIONS.md and source code must be re-aligned. '
            'See CONVENTIONS.md "Source approval documentation" section.',
      );

      expect(
        source.enabled,
        isTrue,
        reason: 'Approved sources must be enabled in SourceRegistry. '
            'Disabling requires updating CONVENTIONS.md approval status and '
            'adding user-facing consent flow (privacy/opt-in).',
      );

      expect(
        source.attributionRequired,
        isTrue,
        reason: 'Crosshare requires attribution per Terms of Service. '
            'Must be displayed in puzzle subtitle or share result.',
      );
    });
  });
}
