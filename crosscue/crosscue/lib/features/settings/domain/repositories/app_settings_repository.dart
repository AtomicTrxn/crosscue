import 'package:flutter/material.dart';

/// Abstract interface for persisted user settings.
///
/// Implemented by [AppSettingsRepositoryImpl] (data layer).
/// Declared here (domain layer) so presentation providers depend only on the
/// interface, keeping the data layer replaceable and settings mockable in tests.
abstract interface class AppSettingsRepository {
  Future<bool> getHasSeenOnboarding();
  Future<void> setHasSeenOnboarding(bool value);

  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  Future<bool> getHapticsEnabled();
  Future<void> setHapticsEnabled(bool value);

  Future<bool> getColorblindMode();
  Future<void> setColorblindMode(bool value);

  Future<bool> getSoundsEnabled();
  Future<void> setSoundsEnabled(bool value);

  Future<bool> getSkipFilledCells();
  Future<void> setSkipFilledCells(bool value);

  Future<bool> getPuzzleReminder();
  Future<void> setPuzzleReminder(bool value);

  Future<bool> getStreakReminder();
  Future<void> setStreakReminder(bool value);

  Future<bool> getCrashReporting();
  Future<void> setCrashReporting(bool value);
}
