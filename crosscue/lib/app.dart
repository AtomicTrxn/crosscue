import 'dart:async';
import 'dart:ui';

import 'package:crosscue/core/background/widget_refresh_scheduler.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/app_router.dart';
import 'package:crosscue/core/routing/pending_share_route.dart';
import 'package:crosscue/core/theme/app_theme.dart';
import 'package:crosscue/features/archive/presentation/providers/archive_providers.dart';
import 'package:crosscue/features/home/data/services/app_intent_router.dart';
import 'package:crosscue/features/home/data/services/home_widget_service.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:crosscue/features/import/data/services/shared_puzzle_import_service.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:share_handler/share_handler.dart';

/// Debug-only, one-shot log of what `dynamic_color` actually returns on this
/// platform. Lets us verify on a device/simulator whether iOS 16+ surfaces a
/// system scheme (issue #112) without shipping any logging in release builds.
bool _dynamicSchemesLogged = false;
void _logDynamicSchemesOnce(ColorScheme? light, ColorScheme? dark) {
  if (!kDebugMode || _dynamicSchemesLogged) return;
  _dynamicSchemesLogged = true;
  String describe(ColorScheme? s) =>
      s == null ? 'null' : 'primary=${s.primary}, surface=${s.surface}';
  debugPrint('[dynamic_color] lightDynamic: ${describe(light)}');
  debugPrint('[dynamic_color] darkDynamic:  ${describe(dark)}');
}

/// Reads a pending route token left by an iOS App Intent
/// (`CrosscueAppIntents.swift`) in the shared App Group, clears it, resolves it
/// to a go_router path, and navigates. Called on launch and on resume. No-op
/// (swallowed) when the App Group / widget extension isn't configured, or when
/// nothing is pending. See issue #115.
Future<void> _consumePendingIntentRoute(WidgetRef ref) async {
  try {
    await HomeWidget.setAppGroupId(HomeWidgetService.appGroupId);
    final token =
        await HomeWidget.getWidgetData<String>(kPendingIntentRouteKey);
    if (token == null || token.isEmpty) return;
    // Clear first so a token is consumed exactly once.
    await HomeWidget.saveWidgetData<String>(kPendingIntentRouteKey, '');
    final route = await resolveAppIntentRoute(
      token,
      archive: ref.read(archiveRepositoryProvider),
    );
    if (route != null && route.isNotEmpty) {
      ref.read(appRouterProvider).go(route);
    }
  } on Object {
    // App Group not configured (non-iOS / pre-setup) — nothing to route.
  }
}

/// Imports a puzzle file shared in from another app via the OS share sheet
/// (`share_handler`) and either navigates to its solve screen or surfaces a
/// message. Called for both the cold-start accessor and each warm-start
/// stream event — see `_CrosscueAppState._initSharedMediaHandling`. No-op
/// (swallowed) when there's no file attachment, the shared file isn't a
/// puzzle, or the plugin/import pipeline fails for any reason — a bad share
/// must never crash launch or the app. See issue #296 Phase 3.
Future<void> _handleSharedMedia(WidgetRef ref, SharedMedia media) async {
  try {
    // Single-file only — matches the Android intent-filter (ACTION_SEND, no
    // ACTION_SEND_MULTIPLE) and iOS's single-attachment Share Extension
    // activation rule. Don't loop over multiple attachments and fire
    // multiple navigations in one frame.
    final attachments = media.attachments;
    if (attachments == null || attachments.isEmpty) return;
    final attachment = attachments.first;
    if (attachment == null) return;

    final service = ref.read(sharedPuzzleImportServiceProvider);
    final result = await service.importAttachment(attachment);
    switch (result) {
      case SharedImportSuccess(:final route):
        // Stash the target before navigating — see pending_share_route.dart.
        // On a cold launch, iOS's own stray platform-route delivery for the
        // Share Extension's redirect URL can land after this `.go()` call
        // and silently bounce navigation back to `/`; the router's redirect
        // re-asserts this value if that happens.
        setPendingShareRoute(route);
        ref.read(appRouterProvider).go(route);
      case SharedImportDuplicate():
        _showSharedImportMessage('Already in your library.');
      case SharedImportFailure(:final error):
        _showSharedImportMessage(error.userMessage);
    }
  } on Object {
    // Plugin unavailable on this platform, unreadable file, etc.
  }
}

/// Shows a brief message for a duplicate/failed share import via the
/// app-level [ScaffoldMessengerState], since a share can be handled before
/// any screen has built (cold start) or while routing is mid-flight.
void _showSharedImportMessage(String message) {
  CrosscueApp.scaffoldMessengerKey.currentState
      ?.showSnackBar(SnackBar(content: Text(message)));
}

ThemeMode _toFlutterThemeMode(AppThemeMode m) => switch (m) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

/// Root application widget. Reads the router and theme mode from Riverpod
/// and wraps MaterialApp.router with Material You dynamic color support.
class CrosscueApp extends ConsumerStatefulWidget {
  const CrosscueApp({super.key});

  /// Lets code outside the widget tree (share-sheet import handling — see
  /// `_handleSharedMedia`) show a SnackBar without a `BuildContext`, since a
  /// share can be handled before any screen has built or while routing is
  /// mid-flight.
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  ConsumerState<CrosscueApp> createState() => _CrosscueAppState();
}

class _CrosscueAppState extends ConsumerState<CrosscueApp> {
  late final _CrosshareLifecycleObserver _lifecycleObserver;
  Timer? _crosshareUtcMidnightTimer;
  StreamSubscription<SharedMedia>? _sharedMediaSub;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _CrosshareLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _installCrashHandlers();
    ref.listenManual(
      crashReportingProvider,
      (_, enabled) {
        ref.read(crashReporterProvider).init(enabled: enabled);
      },
      fireImmediately: true,
    );
    // Keep the Home/Lock-screen widget in sync with the streak + today's solve
    // state. statsData is invalidated after a completion is persisted
    // (solve_notifier), so reacting to it here pushes *fresh* data — unlike a
    // fire-and-forget refresh at completion time, which races the DB write.
    ref.listenManual(statsDataProvider, (_, next) {
      if (next is AsyncData) {
        unawaited(ref.read(homeWidgetServiceProvider).refresh());
      }
    });
    _scheduleCrosshareUtcMidnightTimer();
    // Trigger auto-download on first launch (post-frame so providers are ready).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(
        ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded(),
      );
      // Re-enable sync if the user previously opted in (the orchestrator is
      // in-memory and starts disabled each launch). Best-effort: a missing
      // iCloud account leaves it SyncSignedOut and writes nothing.
      if (await ref.read(appSettingsProvider).getSyncEnabled()) {
        final orchestrator = ref.read(syncOrchestratorProvider);
        // Silent restore — launch must never pop a sign-in sheet. The user
        // signs in interactively only via the Settings/onboarding toggle.
        await orchestrator.enableSilently();
        await orchestrator.syncNow();
      }
      // Push current streak + today's puzzle to the home-screen widgets (#114
      // iOS, #204 Android). Inert until a widget is placed. iOS widget taps
      // deep-link via the widget's path-form `crosscue://<route>` URL, which
      // FlutterDeepLinkingEnabled routes with no app-side wiring; Android taps
      // arrive via home_widget's click stream — see _initAndroidWidgetTaps.
      unawaited(ref.read(homeWidgetServiceProvider).refresh());
      _initAndroidWidgetTaps();
      // Route a pending iOS App Intent (Shortcuts/Siri/Spotlight) if one is
      // waiting from a cold launch. No-op otherwise.
      unawaited(_consumePendingIntentRoute(ref));
      // Handle a puzzle file shared in from another app via the OS share
      // sheet (share_handler; #296 Phase 3). Push-based (native →
      // MethodChannel → Dart stream), not a poll-on-resume pattern, so this
      // needs no lifecycle observer — just a one-time cold-start check plus
      // a stream subscription set up here and cancelled in dispose().
      unawaited(_initSharedMediaHandling());
      // Register the best-effort daily background refresh so the widget's
      // "today" tile stays current even for users who don't open the app
      // (#175). Idempotent; no-op off-device. iOS controls actual cadence.
      unawaited(const WidgetRefreshScheduler().initializeAndSchedule());
    });
  }

  /// Sets up puzzle-file share handling: resolves the cold-start share (if
  /// any) once, then starts listening for warm-start shares. Swallows any
  /// failure — the plugin being unavailable on this platform (or under
  /// `flutter_test`, see `test/widget_test.dart`) must never crash launch.
  Future<void> _initSharedMediaHandling() async {
    try {
      final handler = ShareHandler.instance;
      final initial = await handler.getInitialSharedMedia();
      if (initial != null) {
        await _handleSharedMedia(ref, initial);
        // Clear so this cold-start share isn't reprocessed on next launch —
        // consume-once, matching _consumePendingIntentRoute's pattern above.
        await handler.resetInitialSharedMedia();
      }
      _sharedMediaSub = handler.sharedMediaStream.listen(
        (media) => unawaited(_handleSharedMedia(ref, media)),
        onError: (Object _, StackTrace __) {
          // Required, not optional: flutter_test runs this init code with
          // the plugin unavailable, and a stream *error* (unlike a thrown
          // exception) escapes the surrounding try/catch and fails the test
          // suite without this callback. See Hard Constraint #9.
        },
      );
    } on Object {
      // Plugin unavailable on this platform — nothing to route.
    }
  }

  void _scheduleCrosshareUtcMidnightTimer() {
    _crosshareUtcMidnightTimer?.cancel();
    _crosshareUtcMidnightTimer = Timer(
      _durationUntilNextUtcMidnight(),
      () {
        unawaited(
          ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded(),
        );
        if (mounted) {
          _scheduleCrosshareUtcMidnightTimer();
        }
      },
    );
  }

  Duration _durationUntilNextUtcMidnight() {
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    final delay = tomorrow.difference(now);
    return delay.isNegative ? Duration.zero : delay;
  }

  /// Routes Android home-screen widget (#204) and App Shortcut (#205) taps into
  /// the app. Both launch MainActivity via home_widget's launch intent, so they
  /// arrive on the same `widgetClicked` / `initiallyLaunchedFromHomeWidget`
  /// stream:
  ///   - widget tap  → `crosscue://<go_router path>` (e.g. `/solve/<id>`)
  ///   - shortcut    → `crosscue://intent/<token>` (today / continue / stats),
  ///                   resolved the same way the iOS App Intents are.
  ///
  /// iOS uses its own surfaces instead (the widget's `widgetURL` +
  /// FlutterDeepLinkingEnabled; App Intents via the pending-route token), since
  /// home_widget's click stream doesn't fire under the iOS scene lifecycle — so
  /// this is effectively Android-only and a harmless no-op elsewhere.
  void _initAndroidWidgetTaps() {
    void go(Uri? uri) {
      if (uri == null) return;
      // App Shortcut (#205): resolve the semantic token, then navigate.
      if (uri.host == 'intent') {
        final token = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
        if (token.isEmpty) return;
        unawaited(() async {
          final route = await resolveAppIntentRoute(
            token,
            archive: ref.read(archiveRepositoryProvider),
          );
          if (route != null && route.isNotEmpty) {
            ref.read(appRouterProvider).go(route);
          }
        }());
        return;
      }
      // Widget tap (#204): the URI path is a literal go_router location.
      final location =
          uri.query.isEmpty ? uri.path : '${uri.path}?${uri.query}';
      // An empty / root path is the no-puzzle tap — just open the app.
      if (location.isEmpty || location == '/') return;
      ref.read(appRouterProvider).go(location);
    }

    unawaited(() async {
      try {
        // Cold launch from a widget / shortcut tap.
        go(await HomeWidget.initiallyLaunchedFromHomeWidget());
        // Taps while the app is already running.
        HomeWidget.widgetClicked.listen(go);
      } on Object {
        // No widget placed / platform without one — nothing to route.
      }
    }());
  }

  void _installCrashHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      ref
          .read(crashReporterProvider)
          .reportError(details.exception, details.stack ?? StackTrace.current);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      ref.read(crashReporterProvider).reportError(error, stack);
      return false;
    };
  }

  @override
  void dispose() {
    _crosshareUtcMidnightTimer?.cancel();
    unawaited(_sharedMediaSub?.cancel());
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = _toFlutterThemeMode(ref.watch(themeModeProvider));

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        _logDynamicSchemesOnce(lightDynamic, darkDynamic);
        return MaterialApp.router(
          title: 'Crosscue',
          scaffoldMessengerKey: CrosscueApp.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dynamicScheme: lightDynamic),
          darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}

/// App-level lifecycle observer — one of exactly two observers in the app.
///
/// Responsibility split:
///   - This observer handles [AppLifecycleState.resumed] only, to retrigger
///     the Crosshare auto-download and a sync pass when the app returns to
///     the foreground.
///   - The solve screen's [WidgetsBindingObserver] mixin handles
///     `paused` / `hidden` (auto-pause timer) and `detached` (flush save).
///
/// Do not add a third observer. If you need to react to a lifecycle event,
/// extend one of these two. The architectural rule is enforced by
/// `test/architecture/lifecycle_observers_test.dart` — if you genuinely
/// need a new owner, update its allowlist with a written justification.
class _CrosshareLifecycleObserver extends WidgetsBindingObserver {
  _CrosshareLifecycleObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        _ref.read(crosshareAutoDownloadServiceProvider).attemptIfNeeded(),
      );
      // Pull in changes made on other devices while we were backgrounded.
      // No-op unless sync is enabled and signed in (orchestrator self-guards).
      unawaited(_ref.read(syncOrchestratorProvider).syncNow());
      // Refresh the Home/Lock-screen widget (streak may have changed, e.g. a
      // missed-day reset). No-op until the widget extension is configured.
      unawaited(_ref.read(homeWidgetServiceProvider).refresh());
      // An App Intent (Shortcuts/Siri) triggered while we were backgrounded
      // opens the app; route it now. No-op when nothing is pending.
      unawaited(_consumePendingIntentRoute(_ref));
    }
  }
}
