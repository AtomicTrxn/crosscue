import 'dart:async';
import 'dart:ui';

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/routing/app_router.dart';
import 'package:crosscue/core/theme/app_theme.dart';
import 'package:crosscue/features/home/data/services/home_widget_service.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

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

ThemeMode _toFlutterThemeMode(AppThemeMode m) => switch (m) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

/// Root application widget. Reads the router and theme mode from Riverpod
/// and wraps MaterialApp.router with Material You dynamic color support.
class CrosscueApp extends ConsumerStatefulWidget {
  const CrosscueApp({super.key});

  @override
  ConsumerState<CrosscueApp> createState() => _CrosscueAppState();
}

class _CrosscueAppState extends ConsumerState<CrosscueApp> {
  late final _CrosshareLifecycleObserver _lifecycleObserver;

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
      // Push current streak + today's puzzle to the Home/Lock-screen widget,
      // and wire widget taps to deep-link into the app. Both no-op until the
      // widget extension + App Group are configured (ios-widget-setup.md).
      unawaited(ref.read(homeWidgetServiceProvider).refresh());
      _initWidgetDeepLinks();
    });
  }

  /// Routes a Home/Lock-screen widget tap into the app. The widget encodes its
  /// target as `crosscue://widget?route=<encoded go_router path>`; we forward
  /// that path to the router. Safe no-op when nothing launched us from a widget.
  void _initWidgetDeepLinks() {
    void go(Uri? uri) {
      if (uri == null) return;
      final route = uri.queryParameters['route'];
      if (route == null || route.isEmpty) return;
      ref.read(appRouterProvider).go(route);
    }

    unawaited(() async {
      try {
        // The App Group id must be set before querying widget launches,
        // otherwise home_widget throws "AppGroupId not set".
        await HomeWidget.setAppGroupId(HomeWidgetService.appGroupId);
        // Cold launch from a widget tap.
        go(await HomeWidget.initiallyLaunchedFromHomeWidget());
        // Taps while the app is already running.
        HomeWidget.widgetClicked.listen(go);
      } on Object {
        // Widget extension / App Group not configured — nothing to route.
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
    }
  }
}
