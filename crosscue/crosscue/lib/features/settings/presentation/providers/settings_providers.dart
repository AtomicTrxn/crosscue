import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';

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
// Onboarding
// ---------------------------------------------------------------------------

/// Whether the user has seen the onboarding flow.
/// Used by the router redirect; invalidated after onboarding completes.
@riverpod
Future<bool> hasSeenOnboarding(Ref ref) =>
    ref.read(appSettingsProvider).getHasSeenOnboarding();

// ---------------------------------------------------------------------------
// Theme mode
// ---------------------------------------------------------------------------

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<ThemeMode> build() => ref.read(appSettingsProvider).getThemeMode();

  Future<void> setMode(ThemeMode mode) async {
    await ref.read(appSettingsProvider).setThemeMode(mode);
    state = AsyncData(mode);
  }
}

// ---------------------------------------------------------------------------
// Haptics
// ---------------------------------------------------------------------------

@riverpod
class HapticsEnabledNotifier extends _$HapticsEnabledNotifier {
  @override
  Future<bool> build() => ref.read(appSettingsProvider).getHapticsEnabled();

  Future<void> toggle() async {
    final current = switch (state) {
      AsyncData(:final value) => value,
      _ => true,
    };
    final next = !current;
    await ref.read(appSettingsProvider).setHapticsEnabled(next);
    state = AsyncData(next);
  }
}

@riverpod
class ColorblindModeNotifier extends _$ColorblindModeNotifier {
  @override
  Future<bool> build() => ref.read(appSettingsProvider).getColorblindMode();

  Future<void> toggle() async {
    final next = _nextBool(state);
    await ref.read(appSettingsProvider).setColorblindMode(next);
    state = AsyncData(next);
  }
}

@riverpod
class SoundsEnabledNotifier extends _$SoundsEnabledNotifier {
  @override
  Future<bool> build() => ref.read(appSettingsProvider).getSoundsEnabled();

  Future<void> toggle() async {
    final next = _nextBool(state);
    await ref.read(appSettingsProvider).setSoundsEnabled(next);
    state = AsyncData(next);
  }
}

@riverpod
class SkipFilledCellsNotifier extends _$SkipFilledCellsNotifier {
  @override
  Future<bool> build() => ref.read(appSettingsProvider).getSkipFilledCells();

  Future<void> toggle() async {
    final next = _nextBool(state);
    await ref.read(appSettingsProvider).setSkipFilledCells(next);
    state = AsyncData(next);
  }
}

@riverpod
class PuzzleReminderNotifier extends _$PuzzleReminderNotifier {
  @override
  Future<bool> build() => ref.read(appSettingsProvider).getPuzzleReminder();

  Future<void> toggle() async {
    final next = _nextBool(state);
    await ref.read(appSettingsProvider).setPuzzleReminder(next);
    state = AsyncData(next);
  }
}

@riverpod
class StreakReminderNotifier extends _$StreakReminderNotifier {
  @override
  Future<bool> build() => ref.read(appSettingsProvider).getStreakReminder();

  Future<void> toggle() async {
    final next = _nextBool(state);
    await ref.read(appSettingsProvider).setStreakReminder(next);
    state = AsyncData(next);
  }
}

@riverpod
class CrashReportingNotifier extends _$CrashReportingNotifier {
  @override
  Future<bool> build() => ref.read(appSettingsProvider).getCrashReporting();

  Future<void> toggle() async {
    final next = _nextBool(state);
    await ref.read(appSettingsProvider).setCrashReporting(next);
    state = AsyncData(next);
  }
}

bool _nextBool(AsyncValue<bool> current) {
  return switch (current) {
    AsyncData(:final value) => !value,
    _ => true,
  };
}
