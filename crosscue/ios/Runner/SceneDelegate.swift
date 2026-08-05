import Flutter
import UIKit
import share_handler_ios

// share_handler_ios registers itself the classic (pre-Scene) way —
// `registrar.addApplicationDelegate(instance)` — not as a
// `FlutterSceneLifeCycleDelegate`. Under this app's Scene-based lifecycle
// (see Runner/Info.plist's `UIApplicationSceneManifest`), iOS delivers URL
// opens to `scene(_:openURLContexts:)` / `scene(_:willConnectTo:options:)`,
// not to `AppDelegate.application(_:open:options:)` — so without the
// forwarding below, share_handler would never see the redirect URL its own
// Share Extension hands back. See docs/architecture/ios-share-extension.md
// and the plan's Hard Constraint #1.
//
// (The Flutter engine does have a built-in same-purpose fallback —
// `FlutterPluginAppLifeCycleDelegate.sceneFallbackOpenURLContexts:` /
// `sceneWillConnectFallback:`, which re-dispatches to classic
// `addApplicationDelegate`-registered plugins that don't conform to
// `FlutterSceneLifeCycleDelegate` when no scene-aware plugin has claimed the
// event — see FlutterSceneLifeCycle.mm / FlutterPluginAppLifeCycleDelegate.mm
// in the engine source. Calling `super` below already exercises that path.
// The explicit calls here are kept anyway so delivery does not depend on an
// internal fallback we don't control the presence/behavior of across engine
// versions, and so the warm-start case can deterministically skip Flutter's
// normal deep-link routing for a URL share_handler already claimed — see the
// early-return note below. Worst case this causes a harmless duplicate
// initial-share event on cold start; Phase 3's consume-once handling
// (`resetInitialSharedMedia()`) absorbs that.)
class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let url = connectionOptions.urlContexts.first?.url {
      _ = SwiftShareHandlerIosPlatform.instance.application(
        UIApplication.shared,
        didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey.url: url]
      )
    }
    // Always forward to super regardless of the above: this is what sets up
    // the FlutterViewController/window on cold start, share or not.
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url,
      SwiftShareHandlerIosPlatform.instance.application(
        UIApplication.shared, open: url, options: [:])
    {
      // share_handler claimed this URL (its "ShareMedia-<bundle id>" redirect
      // scheme) — do not forward to super/Flutter's deep-link routing, or
      // go_router would receive it as a garbage location.
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
