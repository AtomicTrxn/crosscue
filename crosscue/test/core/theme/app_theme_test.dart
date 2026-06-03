// Verifies the dynamic-color reconciliation from issue #112: Crosscue's brand
// identity is applied on top of a system dynamic scheme, not just on the
// seeded fallback — so the system accent can never replace brand blue on the
// key roles, while the dynamic base still harmonizes the roles we don't
// override.

import 'package:crosscue/core/theme/app_theme.dart';
import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Stand-in for what dynamic_color returns on Android 12+ / iOS 16+ —
  // deliberately a non-brand (orange) accent so brand overrides are provable.
  final systemLight = ColorScheme.fromSeed(seedColor: Colors.orange);
  final systemDark = ColorScheme.fromSeed(
    seedColor: Colors.orange,
    brightness: Brightness.dark,
  );

  group('brand identity over a dynamic scheme (#112)', () {
    test('light: brand roles applied on top of a dynamic scheme', () {
      final scheme = AppTheme.light(dynamicScheme: systemLight).colorScheme;
      expect(scheme.primary, CrosscueColors.primary);
      expect(scheme.surface, CrosscueColors.surfaceLight);
      expect(scheme.error, CrosscueColors.incorrectLight);
      expect(scheme.brightness, Brightness.light);
    });

    test('dark: brand roles applied on top of a dynamic scheme', () {
      final scheme = AppTheme.dark(dynamicScheme: systemDark).colorScheme;
      expect(scheme.primary, CrosscueColors.primaryLight);
      expect(scheme.surface, CrosscueColors.surfaceDark);
      expect(scheme.error, CrosscueColors.incorrectDark);
      expect(scheme.brightness, Brightness.dark);
    });

    test('fallback (no dynamic scheme) yields the same brand roles', () {
      expect(AppTheme.light().colorScheme.primary, CrosscueColors.primary);
      expect(AppTheme.dark().colorScheme.primary, CrosscueColors.primaryLight);
    });

    test('non-overridden roles still come from the dynamic base', () {
      // `secondary` isn't a brand-overridden role, so supplying a dynamic base
      // should change it relative to the seeded fallback — proving we layer
      // brand on top of the dynamic scheme rather than discarding it (option a,
      // not c).
      final withDynamic =
          AppTheme.light(dynamicScheme: systemLight).colorScheme;
      final fallback = AppTheme.light().colorScheme;
      expect(withDynamic.secondary, isNot(fallback.secondary));
    });
  });
}
