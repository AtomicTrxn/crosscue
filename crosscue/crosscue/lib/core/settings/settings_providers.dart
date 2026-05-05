import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/core_providers.dart';
import 'app_settings_repository.dart';

part 'settings_providers.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AppSettingsRepository appSettings(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AppSettingsRepository(dao: db.appSettingsDao);
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
  Future<ThemeMode> build() =>
      ref.read(appSettingsProvider).getThemeMode();

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
  Future<bool> build() =>
      ref.read(appSettingsProvider).getHapticsEnabled();

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
