import 'package:flutter/material.dart';

import 'app_settings_dao.dart';

/// Typed wrapper around [AppSettingsDao].
/// All values are JSON-encoded strings in the DB; this class handles conversion.
class AppSettingsRepository {
  const AppSettingsRepository({required this.dao});

  final AppSettingsDao dao;

  // ---------------------------------------------------------------------------
  // Key constants
  // ---------------------------------------------------------------------------

  static const _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const _keyThemeMode = 'theme_mode';
  static const _keyHapticsEnabled = 'haptics_enabled';

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  Future<bool> getHasSeenOnboarding() async {
    final v = await dao.getValue(_keyHasSeenOnboarding);
    return v == 'true';
  }

  Future<void> setHasSeenOnboarding(bool value) =>
      dao.setValue(_keyHasSeenOnboarding, value.toString());

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  Future<ThemeMode> getThemeMode() async {
    final v = await dao.getValue(_keyThemeMode);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      dao.setValue(_keyThemeMode, mode.name);

  // ---------------------------------------------------------------------------
  // Haptics
  // ---------------------------------------------------------------------------

  /// Defaults to true if not set.
  Future<bool> getHapticsEnabled() async {
    final v = await dao.getValue(_keyHapticsEnabled);
    return v != 'false';
  }

  Future<void> setHapticsEnabled(bool value) =>
      dao.setValue(_keyHapticsEnabled, value.toString());
}
