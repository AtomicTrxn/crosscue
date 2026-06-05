import 'dart:io' show Platform;

import 'package:crosscue/features/home/data/services/home_widget_service.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

/// Reverse-DNS identifier for the daily widget-refresh background task (#175).
///
/// On iOS this MUST stay in sync with:
///   - the entry in `ios/Runner/Info.plist`
///     `BGTaskSchedulerPermittedIdentifiers`, and
///   - the `WorkmanagerPlugin.registerPeriodicTask(withIdentifier:...)` call in
///     `ios/Runner/AppDelegate.swift`.
/// On Android it is the WorkManager unique work name.
const String widgetRefreshTaskId = 'dev.tomhess.crosscue.refresh';

/// Best-effort cadence.
///
/// Android honours this directly (WorkManager floors it at 15 min). iOS treats
/// it as the *earliest* begin date and decides the real cadence from the user's
/// app-usage pattern — it may fire rarely, or never, for low-engagement users.
/// This is a polish feature, not a guarantee. See
/// `docs/qa/ios-release-checklist.md`.
const Duration widgetRefreshFrequency = Duration(hours: 6);

/// Background-isolate entry point invoked by the OS (Android WorkManager /
/// iOS `BGAppRefreshTask`). Must be top-level and `@pragma('vm:entry-point')`
/// so tree-shaking keeps it in release builds.
@pragma('vm:entry-point')
void widgetRefreshCallbackDispatcher() {
  Workmanager().executeTask((_, __) => runWidgetBackgroundRefresh());
}

/// Runs one best-effort refresh from a headless isolate: download today's
/// puzzle if it's missing (and auto-download is enabled), then push the latest
/// streak + today snapshot to the home-screen widget so the tile is current
/// even for a user who hasn't opened the app in a day or two.
///
/// Stands up its own [ProviderContainer] — there is no app or UI in this
/// isolate. The dependency chain ([CrosshareAutoDownloadService] +
/// [HomeWidgetService]) reads settings through the repository, never the
/// boot-time notifiers, so no `bootSettingsProvider` override is required.
///
/// Always returns `true`. Background refresh is polish; reporting failure to
/// the OS risks getting the task throttled. A transient error (offline, or the
/// database momentarily locked because the app is also foregrounded) just
/// retries on the next cycle.
Future<bool> runWidgetBackgroundRefresh() async {
  final container = ProviderContainer();
  try {
    await container
        .read(crosshareAutoDownloadServiceProvider)
        .attemptIfNeeded();
    await container.read(homeWidgetServiceProvider).refresh();
  } on Object {
    // Best-effort — swallow so the OS doesn't penalise future scheduling.
  } finally {
    container.dispose();
  }
  return true;
}

/// Registers the recurring widget-refresh task.
///
/// Safe to call on every launch: scheduling is idempotent
/// ([ExistingPeriodicWorkPolicy.update]) and a no-op on platforms without
/// WorkManager / BGTaskScheduler (web, desktop, and host-VM unit tests, where
/// [Platform.isIOS] / [Platform.isAndroid] are both false).
class WidgetRefreshScheduler {
  const WidgetRefreshScheduler();

  /// True only where workmanager has a platform implementation.
  bool get _isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Initialises the workmanager isolate hook and enqueues the daily task.
  /// Errors are swallowed — background refresh must never block or crash
  /// launch, and an unconfigured BGTask identifier should fail quietly.
  Future<void> initializeAndSchedule() async {
    if (!_isSupported) return;
    try {
      await Workmanager().initialize(widgetRefreshCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        widgetRefreshTaskId,
        widgetRefreshTaskId,
        frequency: widgetRefreshFrequency,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } on Object {
      // Plugin missing (tests) or scheduling refused — ignore.
    }
  }
}
