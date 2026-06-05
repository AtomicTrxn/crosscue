// Tests for the best-effort widget background-refresh coordinator (#175).
//
// The actual BGAppRefreshTask / WorkManager scheduling and the headless
// download+refresh need a real device (and the iOS widget extension + App
// Group). What's verifiable host-side is the contract that keeps the feature
// safe: the identifier/cadence constants stay in sync with the native config,
// and neither scheduling nor a background run ever throws — both must degrade
// quietly when platform services are unavailable.

import 'package:crosscue/core/background/widget_refresh_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // HomeWidget / path_provider channel calls need a binding to resolve to the
  // "no plugin" path rather than crashing.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('constants', () {
    test('task id matches the native registration (Info.plist + AppDelegate)',
        () {
      // If this literal changes, ios/Runner/Info.plist
      // (BGTaskSchedulerPermittedIdentifiers) and AppDelegate.swift
      // (registerPeriodicTask) must change too, or iOS silently never runs it.
      expect(widgetRefreshTaskId, 'dev.tomhess.crosscue.refresh');
    });

    test('cadence is a sane best-effort interval (>= WorkManager 15 min floor)',
        () {
      expect(widgetRefreshFrequency, const Duration(hours: 6));
      expect(
        widgetRefreshFrequency.inMinutes,
        greaterThanOrEqualTo(15),
        reason: 'Android WorkManager floors periodic work at 15 minutes.',
      );
    });
  });

  group('WidgetRefreshScheduler', () {
    test('initializeAndSchedule is a no-op on unsupported hosts (no throw)',
        () async {
      // On the test VM (not iOS/Android) the guard short-circuits before any
      // plugin call. Must complete cleanly so launch is never blocked.
      await expectLater(
        const WidgetRefreshScheduler().initializeAndSchedule(),
        completes,
      );
    });
  });

  group('runWidgetBackgroundRefresh', () {
    test('always returns true and never throws when services are unavailable',
        () async {
      // Stands up its own ProviderContainer; the DB/path_provider/home_widget
      // plugins are absent in the test VM, so the inner work fails — the
      // coordinator must swallow it and still report success so the OS does
      // not throttle future scheduling.
      expect(await runWidgetBackgroundRefresh(), isTrue);
    });
  });
}
