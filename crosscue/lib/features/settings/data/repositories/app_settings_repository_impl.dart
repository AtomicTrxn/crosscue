import 'package:flutter/material.dart';

import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';

/// Typed wrapper around [AppSettingsDao].
/// All values are JSON-encoded strings in the DB; this class handles conversion.
class AppSettingsRepositoryImpl implements AppSettingsRepository {
  const AppSettingsRepositoryImpl({required this.dao});

  final AppSettingsDao dao;

  // ---------------------------------------------------------------------------
  // Key constants
  // ---------------------------------------------------------------------------

  static const _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const _keyThemeMode = 'theme_mode';
  static const _keyHapticsEnabled = 'haptics_enabled';
  static const _keyColorblindMode = 'colorblind_mode';
  static const _keySoundsEnabled = 'sounds_enabled';
  static const _keySkipFilledCells = 'skip_filled_cells';
  static const _keyPuzzleReminder = 'puzzle_reminder';
  static const _keyStreakReminder = 'streak_reminder';
  static const _keyCrashReporting = 'crash_reporting';

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  @override
  Future<bool> getHasSeenOnboarding() async {
    final v = await dao.getValue(_keyHasSeenOnboarding);
    return v == 'true';
  }

  @override
  Future<void> setHasSeenOnboarding(bool value) =>
      dao.setValue(_keyHasSeenOnboarding, value.toString());

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  @override
  Future<ThemeMode> getThemeMode() async {
    final v = await dao.getValue(_keyThemeMode);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      dao.setValue(_keyThemeMode, mode.name);

  // ---------------------------------------------------------------------------
  // Haptics
  // ---------------------------------------------------------------------------

  /// Defaults to true if not set.
  @override
  Future<bool> getHapticsEnabled() async {
    final v = await dao.getValue(_keyHapticsEnabled);
    return v != 'false';
  }

  @override
  Future<void> setHapticsEnabled(bool value) =>
      dao.setValue(_keyHapticsEnabled, value.toString());

  // ---------------------------------------------------------------------------
  // Sprint 14 settings
  // ---------------------------------------------------------------------------

  @override
  Future<bool> getColorblindMode() => _getBool(_keyColorblindMode);
  @override
  Future<void> setColorblindMode(bool value) =>
      _setBool(_keyColorblindMode, value);

  @override
  Future<bool> getSoundsEnabled() => _getBool(_keySoundsEnabled);
  @override
  Future<void> setSoundsEnabled(bool value) =>
      _setBool(_keySoundsEnabled, value);

  @override
  Future<bool> getSkipFilledCells() => _getBool(_keySkipFilledCells);
  @override
  Future<void> setSkipFilledCells(bool value) =>
      _setBool(_keySkipFilledCells, value);

  @override
  Future<bool> getPuzzleReminder() => _getBool(_keyPuzzleReminder);
  @override
  Future<void> setPuzzleReminder(bool value) =>
      _setBool(_keyPuzzleReminder, value);

  @override
  Future<bool> getStreakReminder() => _getBool(_keyStreakReminder);
  @override
  Future<void> setStreakReminder(bool value) =>
      _setBool(_keyStreakReminder, value);

  @override
  Future<bool> getCrashReporting() => _getBool(_keyCrashReporting);
  @override
  Future<void> setCrashReporting(bool value) =>
      _setBool(_keyCrashReporting, value);

  Future<bool> _getBool(String key) async {
    final v = await dao.getValue(key);
    return v == 'true';
  }

  Future<void> _setBool(String key, bool value) =>
      dao.setValue(key, value.toString());
}
