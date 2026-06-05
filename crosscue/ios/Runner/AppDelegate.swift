import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register the daily widget-refresh BGAppRefreshTask handler (#175) BEFORE
    // the app finishes launching — BGTaskScheduler requires all launch handlers
    // to be registered by then. The identifier matches `widgetRefreshTaskId`
    // (lib/core/background/widget_refresh_scheduler.dart) and Info.plist's
    // `BGTaskSchedulerPermittedIdentifiers`. The frequency is the earliest-begin
    // interval iOS uses when it reschedules the task from its own completion
    // handler; iOS ultimately decides the real cadence (best-effort).
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "dev.tomhess.crosscue.refresh",
      frequency: NSNumber(value: 6 * 60 * 60)
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register sync transport handlers. Safe before any iCloud entitlement
    // is configured — the handler returns nil from `account()` until
    // ubiquityIdentityToken becomes non-nil. See
    // `docs/architecture/sync-icloud-setup.md`.
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "ICloudSyncHandler"
    ) {
      ICloudSyncHandler.register(with: registrar.messenger())
    }

    // Branded share sheet (#147): present a text-only share whose preview
    // thumbnail shows the Crosscue icon via LPLinkMetadata.iconProvider —
    // something share_plus can't do without putting the image in the payload.
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "ShareHandler"
    ) {
      ShareHandler.register(with: registrar.messenger())
    }
  }
}
