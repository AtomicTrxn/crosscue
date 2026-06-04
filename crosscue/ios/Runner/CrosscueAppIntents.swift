// App Intents for Shortcuts / Spotlight / Siri (#115).
//
// Each intent opens the app and leaves a pending route *token* in the shared
// App Group; Flutter (`app.dart`) reads + clears it on launch/resume and
// navigates (`resolveAppIntentRoute`). Using the App Group rather than a method
// channel means it works even on a cold launch (Siri with the app closed),
// where no Flutter engine exists yet.
//
// Additive by design: to add an intent later (e.g. a leaderboard one), declare
// a new `AppIntent` that writes its own token and append it to
// `CrosscueShortcuts.appShortcuts` — no dispatch switch to migrate, and tokens
// are plain strings (a literal `/path` passes straight through on the Dart
// side).

import AppIntents
import Foundation

// Must match HomeWidgetService.appGroupId and kPendingIntentRouteKey on Dart.
private let appGroupId = "group.dev.tomhess.crosscue"
private let pendingRouteKey = "pendingIntentRoute"

@available(iOS 16.0, *)
private func setPendingRoute(_ token: String) {
  UserDefaults(suiteName: appGroupId)?.set(token, forKey: pendingRouteKey)
}

// MARK: - Intents

@available(iOS 16.0, *)
struct OpenTodaysPuzzleIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Today's Puzzle"
  static var description = IntentDescription("Jump straight to today's crossword.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    setPendingRoute("today")
    return .result()
  }
}

@available(iOS 16.0, *)
struct OpenStatsIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Stats"
  static var description = IntentDescription("Open your Crosscue stats.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    setPendingRoute("stats")
    return .result()
  }
}

@available(iOS 16.0, *)
struct ContinueLastSolveIntent: AppIntent {
  static var title: LocalizedStringResource = "Continue Last Puzzle"
  static var description = IntentDescription("Resume your most recent in-progress puzzle.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    setPendingRoute("continue")
    return .result()
  }
}

// MARK: - Shortcuts provider

@available(iOS 16.0, *)
struct CrosscueShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpenTodaysPuzzleIntent(),
      phrases: [
        "Open today's puzzle in \(.applicationName)",
        "Open today's \(.applicationName) puzzle",
      ],
      shortTitle: "Today's Puzzle",
      systemImageName: "puzzlepiece.fill"
    )
    AppShortcut(
      intent: OpenStatsIntent(),
      phrases: [
        "Open \(.applicationName) stats",
        "Show my \(.applicationName) stats",
      ],
      shortTitle: "Stats",
      systemImageName: "chart.bar.fill"
    )
    AppShortcut(
      intent: ContinueLastSolveIntent(),
      phrases: [
        "Continue my \(.applicationName) puzzle",
        "Resume \(.applicationName)",
      ],
      shortTitle: "Continue",
      systemImageName: "play.fill"
    )
  }
}
