// CrosscueWidget — WidgetKit extension (#114).
//
// Renders glanceable state pushed from Dart (via the `home_widget` plugin) into
// the shared App Group container: the current streak and today's puzzle, with a
// leaderboard row that's deliberately optional so it can be filled in later
// (friend boards, #159) WITHOUT a widget rebuild or schema migration.

import SwiftUI
import UIKit
import WidgetKit

// Must match HomeWidgetService.appGroupId / dataKey on the Dart side.
private let appGroupId = "group.dev.tomhess.crosscue"
private let dataKey = "crosscue_widget_v1"

extension Color {
  /// Crosscue brand blue, adaptive: #1565C0 (light) / #7EB8F7 (dark) —
  /// matches CrosscueColors.primary / primaryLight in the app's theme.
  static let crosscueBrand = Color(UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0x7E / 255, green: 0xB8 / 255, blue: 0xF7 / 255, alpha: 1)
      : UIColor(red: 0x15 / 255, green: 0x65 / 255, blue: 0xC0 / 255, alpha: 1)
  })
}

// MARK: - Model

/// Solve state of today's puzzle (wire values match Dart's TodayStatus).
enum TodayStatus: String {
  case solved
  case inProgress
  case notStarted = "new"
}

struct CrosscueEntry: TimelineEntry {
  let date: Date
  let streakCurrent: Int
  let streakBest: Int
  let todayTitle: String?
  let todayRoute: String?
  let todayStatus: TodayStatus?
  /// Null today; becomes a real rank once friend boards ship (#159). The
  /// view treats it as an optional row — additive, no rebuild needed.
  let leaderboardRank: Int?

  static let placeholder = CrosscueEntry(
    date: Date(),
    streakCurrent: 7,
    streakBest: 30,
    todayTitle: "Today's Mini",
    todayRoute: nil,
    todayStatus: .notStarted,
    leaderboardRank: nil
  )

  static let empty = CrosscueEntry(
    date: Date(),
    streakCurrent: 0,
    streakBest: 0,
    todayTitle: nil,
    todayRoute: nil,
    todayStatus: nil,
    leaderboardRank: nil
  )
}

// MARK: - Timeline provider

struct CrosscueProvider: TimelineProvider {
  func placeholder(in context: Context) -> CrosscueEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (CrosscueEntry) -> Void) {
    completion(load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CrosscueEntry>) -> Void) {
    // One entry; the app pushes fresh state and reloads the timeline via
    // `home_widget`'s updateWidget, so we don't need a time-based refresh.
    completion(Timeline(entries: [load()], policy: .never))
  }

  private func load() -> CrosscueEntry {
    guard
      let defaults = UserDefaults(suiteName: appGroupId),
      let raw = defaults.string(forKey: dataKey),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return .empty }

    let streak = json["streak"] as? [String: Any]
    let today = json["today"] as? [String: Any]
    let leaderboard = json["leaderboard"] as? [String: Any]

    return CrosscueEntry(
      date: Date(),
      streakCurrent: streak?["current"] as? Int ?? 0,
      streakBest: streak?["best"] as? Int ?? 0,
      todayTitle: today?["title"] as? String,
      todayRoute: today?["route"] as? String,
      todayStatus: (today?["status"] as? String).flatMap(TodayStatus.init),
      leaderboardRank: leaderboard?["rank"] as? Int
    )
  }
}

// MARK: - Views

/// Deep link a widget tap into the app: `crosscue://widget?route=<encoded>`.
private func widgetDeepLink(_ route: String?) -> URL? {
  guard let route, !route.isEmpty,
        let encoded = route.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)
  else { return URL(string: "crosscue://widget") }
  return URL(string: "crosscue://widget?route=\(encoded)")
}

struct CrosscueWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: CrosscueEntry

  var body: some View {
    let content = Group {
      switch family {
      case .accessoryRectangular:
        rectangularBody
      default:
        smallBody
      }
    }
    .widgetURL(widgetDeepLink(entry.todayRoute))

    if #available(iOS 17.0, *) {
      content.containerBackground(.fill.tertiary, for: .widget)
    } else {
      content.padding()
    }
  }

  // Lock Screen (accessoryRectangular): compact, tint-friendly (monochrome).
  private var rectangularBody: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.streakCurrent > 0
        ? "🔥 \(entry.streakCurrent)-day streak"
        : "No streak yet")
        .font(.headline)
      if let title = entry.todayTitle {
        HStack(spacing: 4) {
          if let status = entry.todayStatus {
            Image(systemName: statusSymbol(status))
          }
          Text(title).lineLimit(1)
        }
        .font(.caption)
      } else {
        Text("No puzzle yet").font(.caption)
      }
      // Additive: shows only once a leaderboard rank exists (#159).
      if let rank = entry.leaderboardRank {
        Text("Rank #\(rank)").font(.caption2)
      }
    }
  }

  // Home Screen (systemSmall): stacked rows, any row may be absent.
  private var smallBody: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Streak — brand-blue number; 🔥 only once there's a streak going.
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        Text("\(entry.streakCurrent)")
          .font(.system(size: 38, weight: .bold, design: .rounded))
          .foregroundStyle(Color.crosscueBrand)
        if entry.streakCurrent > 0 {
          Text("🔥").font(.title3)
        }
      }
      Text("DAY STREAK")
        .font(.caption2.weight(.semibold))
        .tracking(0.5)
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
      VStack(alignment: .leading, spacing: 3) {
        Text("TODAY")
          .font(.caption2.weight(.semibold))
          .tracking(0.5)
          .foregroundStyle(.secondary)
        Text(entry.todayTitle ?? "No puzzle yet")
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
        if let status = entry.todayStatus {
          statusBadge(status)
        }
      }
      // Additive leaderboard row — renders only when present.
      if let rank = entry.leaderboardRank {
        Text("Rank #\(rank)").font(.caption).foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Solved / in-progress / "solve" badge for today's puzzle. The not-started
  /// case reads as a call to action in brand blue rather than a flat label.
  @ViewBuilder
  private func statusBadge(_ status: TodayStatus) -> some View {
    switch status {
    case .solved:
      Label("Solved", systemImage: "checkmark.circle.fill")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.green)
    case .inProgress:
      Label("In progress", systemImage: "ellipsis.circle.fill")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.orange)
    case .notStarted:
      Label("Solve", systemImage: "play.circle.fill")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(Color.crosscueBrand)
    }
  }

  private func statusSymbol(_ status: TodayStatus) -> String {
    switch status {
    case .solved: return "checkmark.circle.fill"
    case .inProgress: return "ellipsis.circle.fill"
    case .notStarted: return "play.circle.fill"
    }
  }
}

// MARK: - Widget

struct CrosscueWidget: Widget {
  let kind = "CrosscueWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CrosscueProvider()) { entry in
      CrosscueWidgetView(entry: entry)
    }
    .configurationDisplayName("Crosscue")
    .description("Your current streak and today's puzzle.")
    .supportedFamilies([.systemSmall, .accessoryRectangular])
  }
}

private extension CharacterSet {
  /// URL-query-safe set (excludes `&`, `=`, `?`, `/`, etc.).
  static let urlQueryValueAllowed: CharacterSet = {
    var set = CharacterSet.urlQueryAllowed
    set.remove(charactersIn: "&=?/+")
    return set
  }()
}
