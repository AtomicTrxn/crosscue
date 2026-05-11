import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';

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
  static const _keyCrosshareAutoDownload = 'crosshare_auto_download_enabled';
  static const _keyCrosshareLastDownloadedDate =
      'crosshare_last_downloaded_date';
  static const _keyCrosshareLastAttemptStatus = 'crosshare_last_attempt_status';

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
  Future<AppThemeMode> getThemeMode() async {
    final v = await dao.getValue(_keyThemeMode);
    return switch (v) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) =>
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
  Future<ColorblindMode> getColorblindMode() async {
    final v = await dao.getValue(_keyColorblindMode);
    return switch (v) {
      'deuteranopia' || 'true' => ColorblindMode.deuteranopia,
      _ => ColorblindMode.none,
    };
  }

  @override
  Future<void> setColorblindMode(ColorblindMode value) =>
      dao.setValue(_keyColorblindMode, value.name);

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

  // ---------------------------------------------------------------------------
  // Crosshare auto-download settings
  // ---------------------------------------------------------------------------

  @override
  Future<bool> getCrosshareAutoDownload() async {
    final v = await dao.getValue(_keyCrosshareAutoDownload);
    if (v == null) return false; // Default: disabled (opt-in)
    return v == 'true';
  }

  @override
  Future<void> setCrosshareAutoDownload(bool value) =>
      dao.setValue(_keyCrosshareAutoDownload, value.toString());

  @override
  Future<String> getCrosshareLastDownloadedDate() async {
    return await dao.getValue(_keyCrosshareLastDownloadedDate) ?? '';
  }

  @override
  Future<void> setCrosshareLastDownloadedDate(String date) =>
      dao.setValue(_keyCrosshareLastDownloadedDate, date);

  @override
  Future<String> getCrosshareLastAttemptStatus() async {
    return await dao.getValue(_keyCrosshareLastAttemptStatus) ?? '';
  }

  @override
  Future<void> setCrosshareLastAttemptStatus(String status) =>
      dao.setValue(_keyCrosshareLastAttemptStatus, status);

  Future<bool> _getBool(String key) async {
    final v = await dao.getValue(key);
    return v == 'true';
  }

  Future<void> _setBool(String key, bool value) =>
      dao.setValue(key, value.toString());
}
