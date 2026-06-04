# iOS Home/Lock-screen widget — one-time setup

The WidgetKit widget for streak + today's puzzle ([#114](https://github.com/AtomicTrxn/crosscue/issues/114)).
Like the iCloud and Google Drive setups, the **code ships first and stays
inert** until the one-time Xcode + Apple-portal wiring below is done:
`HomeWidgetService.refresh()` swallows every failure, so the app behaves
identically whether or not the widget extension exists.

## What's already in the repo (no action needed)

- **Dart push** — `lib/features/home/data/services/home_widget_service.dart`
  composes a versioned JSON payload and writes it to the App Group container via
  the `home_widget` plugin. Triggered on launch, on resume, and after every
  solve (`app.dart`, `solve_screen.dart`).
- **Deep-link** — `app.dart` listens for widget taps (`crosscue://widget?route=…`)
  and forwards the route to go_router. The `crosscue` URL scheme is registered
  in `ios/Runner/Info.plist`.
- **Widget sources** — `ios/CrosscueWidget/` (`CrosscueWidget.swift`,
  `Info.plist`, `CrosscueWidget.entitlements`). Stacked rows (streak / today /
  leaderboard) where any row may be absent; families `systemSmall` +
  `accessoryRectangular`.

## Shared payload schema (App Group container)

Key `crosscue_widget_v1`, JSON:

```json
{
  "version": 1,
  "streak": { "current": 42, "best": 90 },
  "today": { "puzzleId": "local:…", "title": "…", "route": "/solve/…" },
  "leaderboard": null
}
```

`leaderboard` is `null` today. When the leaderboard work lands it becomes
`{ "rank": 142, "total": 5102, "percentile": 97 }` — **same key, new shape**.
The widget reads it as an optional row, so no migration and no widget rebuild
are needed. Keep this additive: don't repurpose `version` for additive fields.

## One-time setup

### 1. Register the App Group (Apple Developer portal)

1. developer.apple.com → **Identifiers** → **App Groups** → **+**.
2. Identifier: `group.dev.tomhess.crosscue` (must match
   `HomeWidgetService.appGroupId` and the two `.entitlements` files).
3. Attach the group to **both** App IDs:
   - `dev.tomhess.crosscue` (Runner)
   - `dev.tomhess.crosscue.CrosscueWidget` (widget — create this App ID too).
4. Regenerate the App Store provisioning profile for the Runner **and** create a
   profile for the widget bundle id, both carrying the App Group capability.
   Update `APPLE_PROVISIONING_PROFILE_BASE64` (and add the widget profile to the
   release signing setup — see `DEPLOYMENT.md`).

### 2. Add the widget extension target (Xcode)

`home_widget` requires a real Xcode-created target — it can't be added by
hand-editing `project.pbxproj` safely.

1. Open `ios/Runner.xcworkspace`.
2. **File → New → Target → Widget Extension.** Name it **`CrosscueWidget`**,
   uncheck "Include Live Activity" and "Include Configuration App Intent".
3. Set the target's **Team** to `ZS9BL7472D` (same as Runner) and minimum
   deployment to **iOS 16.0**.
   (Xcode names the target `CrosscueWidgetExtension`, bundle id
   `dev.tomhess.crosscue.CrosscueWidget`.)
4. **Replace the generated sources with the real widget code.** Xcode generates
   a sample emoji widget (`CrosscueWidget.swift`), a `CrosscueWidgetBundle.swift`
   (the `@main` entry), and a sample Control widget (`CrosscueWidgetControl.swift`).
   Keep the bundle's `@main`; put the streak/today widget code in
   `CrosscueWidget.swift` (as a plain `struct CrosscueWidget: Widget`, no
   `@main`); trim the bundle to list only `CrosscueWidget()`; and empty out /
   delete `CrosscueWidgetControl.swift` (we don't ship a Control widget). The
   final sources are committed under `ios/CrosscueWidget/`.
5. **Signing & Capabilities → + App Groups** on **both** the `Runner` and
   `CrosscueWidgetExtension` targets; check `group.dev.tomhess.crosscue`. Xcode
   writes `Runner.entitlements` and `CrosscueWidgetExtension.entitlements`.
6. **Fix the "Cycle inside Runner" build error.** Embedding an app extension in
   a Flutter app creates a build-phase cycle. In **Runner → Build Phases**, drag
   the **"Embed Foundation Extensions"** phase to run **before** the
   **"Thin Binary"** phase. (Without this, `flutter run` fails with
   `Cycle inside Runner; building could produce unreliable results`.)

### 3. Verify

1. `flutter run -d <ios-device-or-sim>`, finish a puzzle (or just launch).
2. Add the **Crosscue** widget to the Home screen (and the rectangular one to
   the Lock screen). It should show the current streak + today's puzzle within
   ~1 puzzle finish.
3. Tap the widget → the app opens to today's puzzle (the `route` from the
   payload).
4. With an empty library, the widget reads "No puzzle yet" and doesn't crash
   (verifies the optional-row contract, incl. the still-null `leaderboard`).

> **Status: ✅ verified on the iPhone 17 simulator (2026-06).** Target builds +
> embeds, the app writes the versioned payload to the App Group, and the
> `systemSmall` widget renders the streak + today's puzzle. Remaining: re-issue
> the App Store provisioning profile with the App Group capability (+ a widget
> profile) before a device/TestFlight build — simulator needs no provisioning.

## Notes

- **Inert before setup:** until the App Group + target exist, `home_widget`
  calls throw and are swallowed — the app is unaffected.
- **Android Glance parity** is intentionally out of scope (separate issue), as
  are Live Activities and the `accessoryCircular`/`accessoryInline` families.
- The leaderboard row is added as a follow-on once the leaderboard implementation
  lands — by populating the existing `leaderboard` slot, not by changing the
  widget contract.
