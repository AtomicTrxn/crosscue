import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/settings/domain/models/boot_settings.dart';

/// Abstract interface for persisted user settings.
///
/// Implemented by [AppSettingsRepositoryImpl] (data layer).
/// Declared here (domain layer) so presentation providers depend only on the
/// interface, keeping the data layer replaceable and settings mockable in tests.
abstract interface class AppSettingsRepository {
  /// Loads every sync-readable setting in a single pass so `main()` can
  /// seed the in-memory cache before the first frame. See
  /// `lib/features/settings/domain/models/boot_settings.dart`.
  Future<BootSettings> loadBootSettings();

  Future<bool> getHasSeenOnboarding();
  Future<void> setHasSeenOnboarding(bool value);

  Future<AppThemeMode> getThemeMode();
  Future<void> setThemeMode(AppThemeMode mode);

  Future<bool> getHapticsEnabled();
  Future<void> setHapticsEnabled(bool value);

  Future<ColorblindMode> getColorblindMode();
  Future<void> setColorblindMode(ColorblindMode value);

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

  /// Whether to automatically download the Crosshare daily mini on launch/foreground.
  /// Defaults to false when no value is stored — the user must explicitly opt in.
  Future<bool> getCrosshareAutoDownload();
  Future<void> setCrosshareAutoDownload(bool value);

  /// The date (YYYY-MM-DD) on which the Crosshare puzzle was last successfully
  /// downloaded. Empty string means never downloaded.
  Future<String> getCrosshareLastDownloadedDate();
  Future<void> setCrosshareLastDownloadedDate(String date);

  /// Human-readable status of the last Crosshare download attempt.
  /// One of: '', 'success', 'duplicate', 'not_found', 'network_error'.
  Future<String> getCrosshareLastAttemptStatus();
  Future<void> setCrosshareLastAttemptStatus(String status);
}
