// Tests for AppSettingsRepositoryImpl — round-trips for every setting,
// default values, and toggle behaviour.
//
// C4 coverage also lives here (getCrosshareAutoDownload defaults to false).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/settings/data/repositories/app_settings_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AppSettingsRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = AppSettingsRepositoryImpl(dao: db.appSettingsDao);
  });
  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------------

  group('hasSeenOnboarding', () {
    test('returns false when not set', () async {
      expect(await repo.getHasSeenOnboarding(), isFalse);
    });

    test('returns true after set', () async {
      await repo.setHasSeenOnboarding(true);
      expect(await repo.getHasSeenOnboarding(), isTrue);
    });

    test('returns false after explicit false', () async {
      await repo.setHasSeenOnboarding(true);
      await repo.setHasSeenOnboarding(false);
      expect(await repo.getHasSeenOnboarding(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Theme mode
  // ---------------------------------------------------------------------------

  group('themeMode', () {
    test('returns system by default', () async {
      expect(await repo.getThemeMode(), equals(AppThemeMode.system));
    });

    test('persists light', () async {
      await repo.setThemeMode(AppThemeMode.light);
      expect(await repo.getThemeMode(), equals(AppThemeMode.light));
    });

    test('persists dark', () async {
      await repo.setThemeMode(AppThemeMode.dark);
      expect(await repo.getThemeMode(), equals(AppThemeMode.dark));
    });

    test('returns system after resetting to system', () async {
      await repo.setThemeMode(AppThemeMode.dark);
      await repo.setThemeMode(AppThemeMode.system);
      expect(await repo.getThemeMode(), equals(AppThemeMode.system));
    });
  });

  // ---------------------------------------------------------------------------
  // Haptics
  // ---------------------------------------------------------------------------

  group('hapticsEnabled', () {
    test('defaults to true when not set', () async {
      expect(await repo.getHapticsEnabled(), isTrue);
    });

    test('persists false', () async {
      await repo.setHapticsEnabled(false);
      expect(await repo.getHapticsEnabled(), isFalse);
    });

    test('returns true after re-enabling', () async {
      await repo.setHapticsEnabled(false);
      await repo.setHapticsEnabled(true);
      expect(await repo.getHapticsEnabled(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Colorblind mode
  // ---------------------------------------------------------------------------

  group('colorblindMode', () {
    test('defaults to none', () async {
      expect(await repo.getColorblindMode(), equals(ColorblindMode.none));
    });

    test('persists deuteranopia', () async {
      await repo.setColorblindMode(ColorblindMode.deuteranopia);
      expect(
          await repo.getColorblindMode(), equals(ColorblindMode.deuteranopia));
    });

    test('returns none after resetting', () async {
      await repo.setColorblindMode(ColorblindMode.deuteranopia);
      await repo.setColorblindMode(ColorblindMode.none);
      expect(await repo.getColorblindMode(), equals(ColorblindMode.none));
    });
  });

  // ---------------------------------------------------------------------------
  // Boolean toggle settings (sounds, skip, reminders, crash reporting)
  // ---------------------------------------------------------------------------

  group('sounds / skip / reminders / crash (bool toggles)', () {
    final boolGetters = <String, Future<bool> Function()>{
      'sounds': () => repo.getSoundsEnabled(),
      'skip': () => repo.getSkipFilledCells(),
      'puzzleReminder': () => repo.getPuzzleReminder(),
      'streakReminder': () => repo.getStreakReminder(),
      'crashReporting': () => repo.getCrashReporting(),
    };
    final boolSetters = <String, Future<void> Function(bool)>{
      'sounds': (v) => repo.setSoundsEnabled(v),
      'skip': (v) => repo.setSkipFilledCells(v),
      'puzzleReminder': (v) => repo.setPuzzleReminder(v),
      'streakReminder': (v) => repo.setStreakReminder(v),
      'crashReporting': (v) => repo.setCrashReporting(v),
    };

    for (final key in boolGetters.keys) {
      test('$key defaults to false', () async {
        expect(await boolGetters[key]!(), isFalse);
      });

      test('$key round-trips true', () async {
        await boolSetters[key]!(true);
        expect(await boolGetters[key]!(), isTrue);
      });

      test('$key round-trips false after true', () async {
        await boolSetters[key]!(true);
        await boolSetters[key]!(false);
        expect(await boolGetters[key]!(), isFalse);
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Crosshare auto-download (C4)
  // ---------------------------------------------------------------------------

  group('crosshareAutoDownload (C4)', () {
    test('returns false when not set (opt-in required)', () async {
      expect(await repo.getCrosshareAutoDownload(), isFalse);
    });

    test('returns true after opt-in', () async {
      await repo.setCrosshareAutoDownload(true);
      expect(await repo.getCrosshareAutoDownload(), isTrue);
    });

    test('returns false after opt-out', () async {
      await repo.setCrosshareAutoDownload(true);
      await repo.setCrosshareAutoDownload(false);
      expect(await repo.getCrosshareAutoDownload(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Crosshare last-downloaded date / attempt status
  // ---------------------------------------------------------------------------

  group('crosshareLastDownloadedDate', () {
    test('returns empty string when not set', () async {
      expect(await repo.getCrosshareLastDownloadedDate(), equals(''));
    });

    test('persists and retrieves date string', () async {
      await repo.setCrosshareLastDownloadedDate('2025-06-15');
      expect(await repo.getCrosshareLastDownloadedDate(), equals('2025-06-15'));
    });
  });

  group('crosshareLastAttemptStatus', () {
    test('returns empty string when not set', () async {
      expect(await repo.getCrosshareLastAttemptStatus(), equals(''));
    });

    test('persists status string', () async {
      await repo.setCrosshareLastAttemptStatus('success');
      expect(await repo.getCrosshareLastAttemptStatus(), equals('success'));
    });
  });
}
