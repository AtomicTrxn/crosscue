import 'package:crosscue/core/domain/models/enums.dart';

/// A frozen snapshot of every user setting that is safe to read synchronously
/// for the lifetime of the app.
///
/// Loaded once in `main()` via [AppSettingsRepository.loadBootSettings] and
/// surfaced through `bootSettingsProvider`. Sync notifiers (haptics, theme,
/// etc.) seed their initial state from this value instead of returning
/// `AsyncValue<T>` and forcing every call site to write a loading fallback.
///
/// This is *not* the live source of truth — toggles update the corresponding
/// notifier's state and write through to the DB. The boot value only matters
/// at startup and as the post-clear-all reset target (see [defaults]).
class BootSettings {
  const BootSettings({
    required this.hasSeenOnboarding,
    required this.themeMode,
    required this.hapticsEnabled,
    required this.soundsEnabled,
    required this.colorblindMode,
    required this.skipFilledCells,
    required this.crashReporting,
    required this.crosshareAutoDownload,
  });

  /// The values a fresh install boots with (and the values clear-all resets to).
  /// Keep in sync with the per-getter defaults in
  /// `AppSettingsRepositoryImpl` — those are the on-disk fallbacks for keys
  /// that have never been written.
  static const BootSettings defaults = BootSettings(
    hasSeenOnboarding: false,
    themeMode: AppThemeMode.system,
    hapticsEnabled: true,
    soundsEnabled: false,
    colorblindMode: ColorblindMode.none,
    skipFilledCells: false,
    crashReporting: false,
    crosshareAutoDownload: false,
  );

  final bool hasSeenOnboarding;
  final AppThemeMode themeMode;
  final bool hapticsEnabled;
  final bool soundsEnabled;
  final ColorblindMode colorblindMode;
  final bool skipFilledCells;
  final bool crashReporting;
  final bool crosshareAutoDownload;
}
