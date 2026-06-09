# Issue #204: Android Home-Screen Widget (Glance) — Implementation Plan

## Context & Goal

The iOS app already ships a WidgetKit extension (Swift, see `ios/CrosscueWidget/`) that renders:

- Current streak (bold number + 🔥 + "DAY STREAK" label)
- Today's puzzle (title + solved/in-progress/solve status)
- Optional leaderboard rank (additive, `null` today — reserved for #159)

Data flows from Dart (`HomeWidgetService.refresh()`) → JSON payload → shared iOS App Group container → WidgetKit reads on every timeline reload. A daily WorkManager/BGAppRefreshTask background refresh (`WidgetRefreshScheduler`) keeps the widget current when the app isn't foregrounded.

**Goal:** Ship Android widget parity using **Jetpack Glance** (Compose-based AppWidgets), reading the same JSON from `SharedPreferences` and mirroring the iOS visual design & interaction model.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Dart (Flutter app)                                     │
│                                                          │
│  HomeWidgetService.refresh()                             │
│    → home_widget plugin → SharedPreferences (Android)    │
├───────────────────────────┬─────────────────────────────┤
│                           │                             │
│  WorkManager daily task   │  Glance AppWidget            │
│  (WidgetRefreshScheduler  │  (CrosscueWidget)            │
│   → same prefs key)       └───────────┬─────────────────┤
│                                       │                 │
│                                       ▼                 │
│                             CrosscueWidget.kt           │
│                               │     │                   │
│                               ▼     ▼                   │
│                        Streak UI  Today/Status UI       │
└────────────────────────────────────────────────────────┘
```

**Key design decisions:**

- On Android, `home_widget` writes to the app's default `SharedPreferences` — the Glance widget reads from the same prefs (same package, no cross-process IPC needed, unlike iOS App Groups).
- Background WorkManager refresh (`WidgetRefreshScheduler`) already runs on Android and will continue to write data while the app is backgrounded.
- Widget tap deep-linking reuses the existing `HomeWidget.widgetClicked` stream on Android, which fires a `crosscue://widget?route=...` intent that the Dart app already handles in `lib/app.dart` (line 156-177) via go_router.

---

## Implementation Steps

### 1. Add Glance Dependencies

**File:** `android/app/build.gradle.kts`

Add under existing `dependencies { }`:

```kotlin
// Glance (Compose-based AppWidgets) — parity with iOS WidgetKit (#204)
implementation("androidx.glance:glance:1.1.0")
implementation("androidx.glance:glance-appwidget:1.1.0")
```

### 2. Create the Glance Widget Class

**File:** `android/app/src/main/kotlin/dev/tomhess/crosscue/CrosscueWidget.kt`

A single Kotlin file containing:

- **`CrosscueWidget : GlanceAppWidget()`** — override the `Content` block
- Data read: `sharedPreferences.getString("crosscue_widget_v1", null)` (matches Dart's `HomeWidgetService.dataKey` on line 93)
- JSON parsing: extract `streak.current`, `streak.best`, `today.title`, `today.status`, `leaderboard.rank`
- Render a `Column` inside a `Box` with rounded-corner `Background`:
  - **Streak row:** bold `Text` (size ~36.sp, brand blue `#1565C0` light / `#7EB8F7` dark), fire emoji only when `current > 0`, `"DAY STREAK"` caption in secondary style
  - **Today row:** title `Text` (semibold, max 2 lines, lineLimit) + status badge: icon + colored label (green checkmark for solved, orange ellipsis for in-progress, blue play for new/not-started — matches Swift `statusBadge` at line 203-218)
  - **Leaderboard row** (additive, renders only when non-null): `"Rank #N"` in secondary style
- Apply dark-mode-aware brand blue via hardcoded values (matching iOS `CrosscueWidget.swift` lines 17-24)
- Fallback placeholder (matches Swift `CrosscueEntry.placeholder` at line 46-55): streak 7/30, title "Today's Mini", status `notStarted`
- Fallback empty (matches Swift `CrosscueEntry.empty` at line 57-65): all nils/zeros

### 3. Register Widget in AndroidManifest

**File:** `android/app/src/main/AndroidManifest.xml`

Add inside `<application>`:

```xml
<receiver
    android:name=".CrosscueWidget"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/crosscue_widget_info"/>
</receiver>
```

**File:** `android/app/src/main/res/xml/crosscue_widget_info.xml` (new)

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="100dp"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/crosscue_widget_placeholder"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"/>
```

**Notes:**
- `updatePeriodMillis="0"` — we push updates manually from Dart's `HomeWidgetService.refresh()` and WorkManager, not via periodic Android polls. This avoids background drain and matches iOS's `TimelinePolicy.never` (Swift line 78). No automatic OS refreshes.
- Allow horizontal and vertical resize per user preference, matching iOS's `.supportedFamilies([.systemSmall, .accessoryRectangular])`.

**File:** `android/app/src/main/res/layout/crosscue_widget_placeholder.xml` (new, minimal)

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@android:color/transparent"/>
```

### 4. Deep-Linking from Widget Tap

The existing Dart code in `lib/app.dart` (lines 156-177) already handles widget deep links via a `crosscue://widget?route=...` URI.

On Android, the Glance `onClick` will launch the `MainActivity`:

```kotlin
val intent = Intent(context, MainActivity::class.java).apply {
  data = Uri.parse("crosscue://widget?route=${encodedRouteOrNull}")
  addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
}
context.startActivity(intent)
```

The `MainActivity` already has `flutter_deeplinking_enabled = true` (AndroidManifest line 48-50). The engine will forward the URI to go_router, and the `HomeWidget.widgetClicked` listener will intercept & navigate.

### 5. Cross-Platform Documentation

Create or update `docs/architecture/android-widget-setup.md`:

- Glance dependency & manifest registration
- `SharedPreferences` as the data bridge (vs iOS App Group)
- Why `updatePeriodMillis="0"` (manual push via WorkManager/home_widget)
- Deep-link flow (widget intent → Flutter engine → go_router)
- Testing notes (widget preview, live refresh, WorkManager background task)

---

## File Summary

| File | Action | Purpose |
|-|-|-|
| `android/app/build.gradle.kts` | Modify | Add Glance dependencies |
| `android/app/src/main/kotlin/dev/tomhess/crosscue/CrosscueWidget.kt` | Create | Widget `Content` (prefs read + Glance Compose UI) |
| `android/app/src/main/AndroidManifest.xml` | Modify | Widget `<receiver>` + provider metadata |
| `android/app/src/main/res/xml/crosscue_widget_info.xml` | Create | Widget size/provider config (`minWidth`, `updatePeriodMillis=0`) |
| `android/app/src/main/res/layout/crosscue_widget_placeholder.xml` | Create | Widget preview/fallback layout |
| `lib/features/home/data/services/home_widget_service.dart` | No-op | Already cross-platform; `home_widget` handles Android prefs natively |
| `docs/architecture/android-widget-setup.md` | Create | Cross-platform widget architecture docs |

---

## Risks & Edge Cases

1. **SharedPreferences threading:** Glance renders on the main UI thread. Reading `SharedPreferences` synchronously is fast enough, but to be safe we'll use `sharedPreferences.getString(...)` inside the `Content` block (it's blocking for a few ms, acceptable for a widget). If the read fails or the JSON is corrupt (e.g., mid-write), the `try/catch` falls back to the placeholder.

2. **No cross-process IPC:** Unlike iOS (App Group container), the Android widget runs in the same app process. `SharedPreferences.get()` is immediate. Writes from WorkManager or the foreground app are independent — `SharedPreferences` is thread-safe concurrent, and the widget reads on demand. Last-write-wins.

3. **Deep-link scheme:** The `crosscue://` scheme is already handled by go_router via the `MainActivity` intent filter and `flutter_deeplinking_enabled=true` in the manifest (lines 48-50). Widget tap launches the activity with this scheme; the Dart engine forwards it as a navigational event. The same flow already works on iOS via `HomeWidget.widgetClicked`.

4. **Widget sizing:** We ship only the standard home-screen widget (Android doesn't have a lock-screen variant like iOS's `.accessoryRectangular`). We match iOS's `.systemSmall` at ~180×100 dp and allow horizontal/vertical resize.

5. **Dark mode:** We'll hardcode the two brand blue shades (`#1565C0` / `#7EB8F7`) to match iOS *exactly*. No reliance on Material You or system color palettes, keeping parity simple.

6. **Leaderboard additive design:** The leaderboard row renders only when a non-null `rank` is present in the JSON. Adding leaderboard support later (#159) requires zero changes to the widget UI — purely additive.

---

## Verification Checklist

- [ ] Widget appears in Android widget picker on home screen
- [ ] Streak number + fire emoji render correctly (matches iOS font weight/style)
- [ ] Today's puzzle title + status icon show (solved ✓ / in-progress ⋯ / solve ▶)
- [ ] Widget taps navigate to the correct go_router page (puzzle solve view)
- [ ] WorkManager daily refresh keeps widget current (verify via background logs or pull-down widget refresh)
- [ ] Fallback placeholder renders when no data exists (fresh install / null prefs)
- [ ] Dark mode brand blue applies correctly
- [ ] No crashes or ANRs on resize, picker dismissal, or rapid app restarts
- [ ] Adding `leaderboardRank` data later renders the row without widget rebuild/migration

---

*Created: 2025-06-07 · Ref: Issue #204, iOS WidgetKit in `ios/CrosscueWidget/CrosscueWidget.swift`, `home_widget` plugin v0.7.0*