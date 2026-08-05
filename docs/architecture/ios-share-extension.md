# iOS Share Extension — share-to-Crosscue puzzle import

> **Status:** Living. Cold-start and warm-start delivery verified on the
> iPhone 17 Simulator (share a `.puz`/`.ipuz` file → app imports it and
> lands on the solve screen, both from a terminated and a running app).
> **Release signing is not yet configured** — see "One-time setup remaining"
> below; Debug/Simulator builds work today, App Store builds will fail to
> export until that's done.

Lets a user share a `.puz`/`.ipuz` file into Crosscue from any app's OS
share sheet (Files, Mail, a browser download, etc.) via a real iOS Share
Extension target, backed by the [`share_handler`](https://pub.dev/packages/share_handler)
plugin. Android's counterpart is a plain `ACTION_SEND` intent-filter on
`MainActivity` — no separate native target needed there.

Like the widget setup this file mirrors, **the code ships first and stays
inert** for release builds until the one-time provisioning below is done;
Debug builds already work end-to-end in the Simulator.

## What's already in the repo (no action needed)

- **iOS Share Extension target** — `CrosscueShareExtension` in
  `ios/Runner.xcodeproj/project.pbxproj`, added via a scripted `xcodeproj`
  gem edit (not the Xcode GUI — verified as a clean, purely-additive diff
  against the existing `CrosscueWidgetExtension` target's shape). Sources
  under `ios/CrosscueShareExtension/`: `Info.plist` (storyboard-based,
  broad `NSExtensionActivationRule` matching any single file/image/text/
  movie/url attachment — narrowed server-side, see below), a minimal
  `MainInterface.storyboard`, and a two-line `ShareViewController.swift`
  subclassing `share_handler_ios_models`'s `ShareHandlerIosViewController`
  (does all the work — no compose/caption UI, automatic hand-off).
  Entitlements: `ios/CrosscueShareExtension.entitlements`, reusing the
  **existing** App Group `group.dev.tomhess.crosscue` (the same one the
  widget extension already uses — no new group was registered).
- **`Runner/Info.plist`** — `AppGroupId` added, plus a second
  `CFBundleURLTypes` entry for the `ShareMedia-dev.tomhess.crosscue`
  redirect scheme the extension uses to relaunch the host app (additive —
  the widget's `crosscue` scheme entry is untouched).
- **`Runner/SceneDelegate.swift`** — forwards cold-start
  (`willConnectTo:options:`) and warm-start (`openURLContexts:`) scene
  events to `share_handler_ios`'s `SwiftShareHandlerIosPlatform` singleton.
  This repo uses Scene-based lifecycle, but `share_handler_ios` registers
  itself the classic pre-Scene `UIApplicationDelegate` way
  (`addApplicationDelegate`) — without this forwarding, the plugin would
  never see the redirect URL under Scene lifecycle. The warm-start override
  returns early (doesn't call `super`) once the plugin claims the URL, or
  go_router would receive it as a garbage location.
- **`android/app/src/main/AndroidManifest.xml`** — a single-file
  `ACTION_SEND` intent-filter on `MainActivity`, scoped to
  `application/octet-stream` + `application/json` rather than `*/*` (an
  `ACTION_SEND` MIME filter controls whether Crosscue shows up in *every*
  user's share sheet for every photo/link/text snippet on their device, not
  just our own import-picker dialog — deliberately narrower). Content is
  still verified server-side regardless of the claimed MIME type.
- **Dart** — `lib/features/import/data/services/shared_puzzle_import_service.dart`
  reads the shared attachment, defers to the existing
  `ImportRepositoryImpl` (same magic-byte content-sniffing the manual
  import flow uses — extension/MIME filtering upstream is a cheap
  early-out, not the source of truth) and returns a route or a
  user-facing message. `app.dart` wires the plugin's cold-start accessor
  and warm-start stream into this — no new `WidgetsBindingObserver` (see
  `test/architecture/lifecycle_observers_test.dart`); the stream is
  push-based and doesn't need one.
- **`lib/core/routing/pending_share_route.dart`** — a small,
  time-bounded (5s) holder consumed by `appRouter`'s `redirect`. Needed
  because Flutter's engine *also* delivers the Share Extension's redirect
  URL to go_router as a platform-provided initial route (since
  `FlutterDeepLinkingEnabled` is on), which resolves to `/` and can — on
  cold start — land *after* the app's own explicit navigation to the
  solve screen, silently bouncing the user back to home. The router
  re-asserts the correct destination the same declarative way it already
  handles the onboarding gate, regardless of which async event lands last.

## One-time setup remaining (Apple Developer portal + CI secret)

Not agent-doable — needs a human with access to the Apple Developer account
and this repo's GitHub Actions secrets. Debug/Simulator builds work without
this; **release/App Store builds will fail to export until it's done**
(`.github/workflows/release.yml`'s `ExportOptions.plist` only lists the
Runner and widget bundle ids today).

1. Register a new App ID for `dev.tomhess.crosscue.CrosscueShareExtension`
   in the Apple Developer portal (mirroring how
   `dev.tomhess.crosscue.CrosscueWidget` is set up).
2. Enable the App Groups capability on it, attached to the **existing**
   `group.dev.tomhess.crosscue` group — no new group needed.
3. Generate and download a Distribution provisioning profile for it
   (mirrors "Crosscue Widget App Store" — the pbxproj's Release config
   already expects a profile named `"Crosscue Share Extension App Store"`,
   adjust if a different name is chosen).
4. Base64-encode it, add it as a new GitHub Actions secret, following the
   existing widget-profile secret's naming convention in `release.yml`.
5. Update `release.yml`'s profile-writing steps and `ExportOptions.plist`
   generation to include the new bundle id/profile.

## Verify

1. `flutter build ios --debug --simulator`, install on a Simulator, share
   a `.puz`/`.ipuz` file to Crosscue from the Simulator's Files app.
2. Confirm both cold start (app not running) and warm start (app already
   foregrounded) land on the solve screen for the shared puzzle, not home.
   Cold start specifically exercises the `pending_share_route` race-guard
   above — don't consider this verified from warm start alone.
3. Confirm the pre-existing `CrosscueWidgetExtension` and the unrelated
   outbound-branded-share class (`ios/Runner/ShareHandler.swift`, issue
   #147) still build and work — same App Group, similarly-named class,
   different mechanisms; verified via symbol inspection (`nm` shows the
   outbound class mangled under the `Runner` module, no collision) plus a
   successful combined build.

## Notes

- **Single-file only, deliberately.** No `ACTION_SEND_MULTIPLE` on Android,
  no multi-attachment support in the iOS activation rule. A multi-file
  share simply won't offer Crosscue as a target on either platform — clean,
  not a partial/confusing result.
- **Broad activation rule, narrow server-side filter.** Both platforms
  accept a wider set of shares than just puzzle files (any single
  file/image/text/url on iOS; two specific MIME types on Android) and rely
  on `ImportRepositoryImpl`'s existing content-sniffing to reject anything
  that isn't actually a `.puz`/`.ipuz`, with a user-facing message. A
  UTI-scoped iOS activation rule would be more precise but fails silently
  if misconfigured (extension just doesn't appear) — not worth the risk
  for v1.
- **Duplicate shares** show a snackbar and land on home rather than
  jumping straight to the already-imported puzzle's solve screen — the
  same "already imported" outcome the manual import flow has today.
  Surfacing the existing puzzle's id for a direct jump would need a small
  `ImportRepository` change affecting both flows; left as a follow-up.
