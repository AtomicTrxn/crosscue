import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:crosscue/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:crosscue/features/settings/domain/models/boot_settings.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AppSettingsRepository appSettings(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AppSettingsRepositoryImpl(dao: db.appSettingsDao);
}

// ---------------------------------------------------------------------------
// Boot snapshot
// ---------------------------------------------------------------------------

/// The frozen boot-time snapshot of every sync-readable setting.
///
/// Must be overridden in `main()` (and in tests) with a value loaded from the
/// real repository. The sync notifiers below seed their initial state from
/// this provider — see `BootSettings`.
@Riverpod(keepAlive: true)
BootSettings bootSettings(Ref ref) {
  throw StateError(
    'bootSettingsProvider was not overridden. Call '
    'AppSettingsRepository.loadBootSettings() in main() and pass the result '
    'via ProviderScope(overrides: [bootSettingsProvider.overrideWithValue(...)]).',
  );
}

// ---------------------------------------------------------------------------
// Sync notifiers — one per setting
//
// Each notifier seeds `state` from `bootSettingsProvider` and writes through
// to `appSettingsProvider` on mutation. Reads are synchronous: no AsyncValue
// unwrap, no fallback dance at the call site.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class HasSeenOnboarding extends _$HasSeenOnboarding {
  @override
  bool build() => ref.watch(bootSettingsProvider).hasSeenOnboarding;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    await ref.read(appSettingsProvider).setHasSeenOnboarding(true);
  }

  Future<void> reset() async {
    state = BootSettings.defaults.hasSeenOnboarding;
    await ref.read(appSettingsProvider).setHasSeenOnboarding(state);
  }
}

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  AppThemeMode build() => ref.watch(bootSettingsProvider).themeMode;

  Future<void> setMode(AppThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ref.read(appSettingsProvider).setThemeMode(mode);
  }

  Future<void> reset() async {
    state = BootSettings.defaults.themeMode;
    await ref.read(appSettingsProvider).setThemeMode(state);
  }
}

@Riverpod(keepAlive: true)
class HapticsEnabled extends _$HapticsEnabled {
  @override
  bool build() => ref.watch(bootSettingsProvider).hapticsEnabled;

  Future<void> toggle() async {
    state = !state;
    await ref.read(appSettingsProvider).setHapticsEnabled(state);
  }

  Future<void> reset() async {
    state = BootSettings.defaults.hapticsEnabled;
    await ref.read(appSettingsProvider).setHapticsEnabled(state);
  }
}

@Riverpod(keepAlive: true)
class SoundsEnabled extends _$SoundsEnabled {
  @override
  bool build() => ref.watch(bootSettingsProvider).soundsEnabled;

  Future<void> toggle() async {
    state = !state;
    await ref.read(appSettingsProvider).setSoundsEnabled(state);
  }

  Future<void> reset() async {
    state = BootSettings.defaults.soundsEnabled;
    await ref.read(appSettingsProvider).setSoundsEnabled(state);
  }
}

@Riverpod(keepAlive: true)
class ColorblindModeNotifier extends _$ColorblindModeNotifier {
  @override
  ColorblindMode build() => ref.watch(bootSettingsProvider).colorblindMode;

  Future<void> toggle() async {
    state = state == ColorblindMode.none
        ? ColorblindMode.deuteranopia
        : ColorblindMode.none;
    await ref.read(appSettingsProvider).setColorblindMode(state);
  }

  Future<void> reset() async {
    state = BootSettings.defaults.colorblindMode;
    await ref.read(appSettingsProvider).setColorblindMode(state);
  }
}

@Riverpod(keepAlive: true)
class SkipFilledCells extends _$SkipFilledCells {
  @override
  bool build() => ref.watch(bootSettingsProvider).skipFilledCells;

  Future<void> toggle() async {
    state = !state;
    await ref.read(appSettingsProvider).setSkipFilledCells(state);
  }

  Future<void> reset() async {
    state = BootSettings.defaults.skipFilledCells;
    await ref.read(appSettingsProvider).setSkipFilledCells(state);
  }
}

@Riverpod(keepAlive: true)
class CrashReporting extends _$CrashReporting {
  @override
  bool build() => ref.watch(bootSettingsProvider).crashReporting;

  Future<void> toggle() async {
    state = !state;
    await ref.read(appSettingsProvider).setCrashReporting(state);
  }

  Future<void> reset() async {
    state = BootSettings.defaults.crashReporting;
    await ref.read(appSettingsProvider).setCrashReporting(state);
  }
}

@Riverpod(keepAlive: true)
class CrosshareAutoDownload extends _$CrosshareAutoDownload {
  @override
  bool build() => ref.watch(bootSettingsProvider).crosshareAutoDownload;

  Future<void> toggle() async {
    state = !state;
    await ref.read(appSettingsProvider).setCrosshareAutoDownload(state);
    if (state) {
      // Trigger today's download immediately so the user sees the puzzle
      // appear without waiting for the next app launch / resume.
      await ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded();
    }
  }

  Future<void> reset() async {
    state = BootSettings.defaults.crosshareAutoDownload;
    await ref.read(appSettingsProvider).setCrosshareAutoDownload(state);
  }
}

// ---------------------------------------------------------------------------
// Async-by-nature providers (Crosshare runtime status)
//
// These change at runtime from external events (downloader writes the date /
// status after a fetch). Kept as Future providers because invalidating them
// is the simplest way to re-read the freshly-written DB row — they're only
// displayed in settings screens, so loading flicker is acceptable.
// ---------------------------------------------------------------------------

@riverpod
Future<String> crosshareLastDownloadedDate(Ref ref) =>
    ref.read(appSettingsProvider).getCrosshareLastDownloadedDate();

@riverpod
Future<String> crosshareLastAttemptStatus(Ref ref) =>
    ref.read(appSettingsProvider).getCrosshareLastAttemptStatus();

// ---------------------------------------------------------------------------
// Clear-all orchestration
// ---------------------------------------------------------------------------

/// Resets every sync notifier above to its default value AND writes the
/// default back to the DB. Called after `clearAllUserData()` so the UI
/// reflects the wiped state without having to invalidate boot settings.
Future<void> resetAllSettings(WidgetRef ref) async {
  await Future.wait<void>([
    ref.read(hasSeenOnboardingProvider.notifier).reset(),
    ref.read(themeModeProvider.notifier).reset(),
    ref.read(hapticsEnabledProvider.notifier).reset(),
    ref.read(soundsEnabledProvider.notifier).reset(),
    ref.read(colorblindModeProvider.notifier).reset(),
    ref.read(skipFilledCellsProvider.notifier).reset(),
    ref.read(crashReportingProvider.notifier).reset(),
    ref.read(crosshareAutoDownloadProvider.notifier).reset(),
  ]);
  ref.invalidate(crosshareLastDownloadedDateProvider);
  ref.invalidate(crosshareLastAttemptStatusProvider);
}
