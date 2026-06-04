import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
