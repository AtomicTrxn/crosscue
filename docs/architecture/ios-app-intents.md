# iOS App Intents (Shortcuts / Spotlight / Siri)

> **Status:** Living — as-built reference + verification runbook. Android
> parity (App Shortcuts) is tracked under
> [ADR-0015](decisions/0015-platform-parity-policy.md) / P2.

Three intents shipped in #115, no third-party packages (iOS 16 App Intents).

| Intent | Token written | Resolves to |
|---|---|---|
| `OpenTodaysPuzzleIntent` | `today` | today's puzzle solve screen |
| `OpenStatsIntent` | `stats` | `/stats` |
| `ContinueLastSolveIntent` | `continue` | most-recently-played in-progress puzzle |

## How it works

`ios/Runner/CrosscueAppIntents.swift` declares the three `AppIntent`s and a
single `CrosscueShortcuts: AppShortcutsProvider`. Each intent sets
`openAppWhenRun = true` and writes a route **token** into the shared App Group
(`group.dev.tomhess.crosscue`, key `pendingIntentRoute`).

Flutter (`app.dart` → `_consumePendingIntentRoute`) reads + clears that token on
**launch** and **resume**, resolves it via `resolveAppIntentRoute`
(`lib/features/home/data/services/app_intent_router.dart`), and navigates with
go_router. The App Group (rather than a method channel) is deliberate — it works
on a **cold launch** from Siri/Shortcuts when no Flutter engine exists yet.

The file is already added to the **Runner** target in the Xcode project, so it
builds with the app — no extra entitlement or capability is needed (App Intents
auto-register from the app bundle). It reuses the App Group the widget already
set up (see `ios-widget-setup.md`).

## Additive by design

To add an intent later (e.g. a leaderboard one once #111 lands):
- declare a new `AppIntent` that writes its own token and append it to
  `CrosscueShortcuts.appShortcuts` — no dispatch switch to migrate;
- the Dart resolver is **not a closed enum**: any token starting with `/` is
  treated as a literal go_router path and passes straight through (e.g. a future
  `/leaderboard/daily`), so new *static* routes need no resolver change at all.

## Verifying (needs a device or simulator)

- **Mechanism:** write a token into the App Group container and cold-launch —
  e.g. `pendingIntentRoute = "stats"` lands the app on the Stats tab. (Verified
  on the iPhone 17 simulator.)
- **Shortcuts/Spotlight/Siri:** install the app, then check the **Shortcuts**
  app lists "Today's Puzzle / Stats / Continue", Spotlight surfaces them, and
  "Hey Siri, open today's puzzle" triggers the intent. These need a real
  device/simulator with Siri and can't be unit-tested.
