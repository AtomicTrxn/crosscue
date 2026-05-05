# Research Topic #17 — UX Missing Details

Status: Resolved
Implementation Status: 🔄 Partially Implemented — Sprints 3–7 shipped back nav, timer, load failure, check/reveal, timer pause, Archive, onboarding, completion sheet, and mock grid; ClueBar redesign remains Sprint 10; accessibility and icon polish remain deferred/Sprint 13
Owner: Claude

## Research Question

What UX details are missing from the existing design documentation that implementers will need before building each screen?

## Decision To Unblock

A UX review of topics #10, #11, #13, #16, and the architecture doc identified 15 gaps — transitional moments and secondary interactions not covered by any prior topic. This document specifies a design decision for each.

---

## 1. Back Navigation Mid-Solve

**Gap:** No doc defines what happens when the user presses Back while actively solving.

**Decision:** Show a confirmation dialog if the puzzle has any user-entered guesses. Progress is always autosaved, so "leave" is safe — the dialog exists only to prevent accidental exits.

```
┌─────────────────────────────────┐
│  Leave puzzle?                  │
│                                 │
│  Your progress is saved. You    │
│  can pick up where you left off.│
│                                 │
│  [Keep solving]  [Leave]        │
└─────────────────────────────────┘
```

- "Keep solving" is the default (left-aligned) — action wording, not destructive.
- "Leave" is the secondary action (right, not styled as destructive since progress is saved).
- If the puzzle has zero guesses (empty grid), skip the dialog and navigate immediately.
- OnboardingScreen back is still disabled (navigates via Skip only) — this rule applies to SolveScreen only.

---

## 2. Completion Stats Sheet Content

**Gap:** Dialog A in topic-13 is named but never designed.

**Decision:** A `DraggableScrollableSheet` slides up from the bottom after the confetti animation completes (~1 s after puzzle solved). It is not auto-dismissed — the user must act.

### Layout

```
┌──────────────────────────────────┐
│  ───                             │  ← drag handle
│                                  │
│  🎉  Clean solve!                │  ← solve label (per topic-15 completion types)
│                                  │
│  ⏱  4:23                        │  ← elapsed time, large
│  Personal best ▲  Previous: 6:12│  ← PB comparison line (only if clean eligible)
│                                  │
│  🔥  24-day streak               │  ← streak (updated)
│                                  │
│  ──────────────────────────────  │
│                                  │
│  [   Share result   ]            │  ← ghost/outlined button
│  [  View filled grid  ]          │  ← text button
│                                  │
│  [      Next puzzle      ]       │  ← primary button (go to Home)
│                                  │
└──────────────────────────────────┘
```

### Rules

| Condition | Solve label | PB line shown? | Streak line |
|-----------|-------------|----------------|-------------|
| `clean` | "Clean solve!" | Yes, if new PB: "New personal best!" | Yes |
| `checked` | "Solved with checks" | No | Yes |
| `hinted` | "Solved with hints" | No | Yes |
| `revealed` | "Puzzle revealed" | No | No |

- "Next puzzle" navigates to `Routes.home`.
- "View filled grid" dismisses the sheet; the grid stays visible in a read-only completed state (see §10).
- "Share result" opens the system share sheet with a text card: "I solved [Title] in 4:23 — Crosscue".
- If the session is `revealed`, "Share result" is hidden (not meaningful to share a revealed puzzle).
- Streak line is omitted if `completion_type == revealed`.

---

## 3. ImportScreen Visual Design

**Gap:** The import flow is specified (topic-16) but the screen itself has no visual layout.

**Decision:**

```
┌─────────────────────────────────┐
│  ←  Import Puzzle               │  ← app bar, back closes screen
├─────────────────────────────────┤
│                                 │
│        [puzzle file icon]       │
│                                 │
│  Import a .puz or .ipuz file    │  ← headline, center
│                                 │
│  Crosscue supports AcrossLite   │
│  (.puz) and iPuz (.ipuz) puzzle │
│  formats.                       │  ← body text, center
│                                 │
│  ┌─────────────────────────┐    │
│  │   Choose puzzle file    │    │  ← filled primary button
│  └─────────────────────────┘    │
│                                 │
│  Import files you have          │
│  permission to use.             │  ← small caption, muted color
│                                 │
├─────────────────────────────────┤
│ (loading state replaces button) │
└─────────────────────────────────┘
```

**Loading state** (shown immediately after file is picked, before parse completes):
- Replace the button with a `LinearProgressIndicator` (indeterminate) + "Reading puzzle…" caption.
- If parsing takes > 3 s, add "This is taking a moment…".
- Do not navigate away; stay on ImportScreen until success or failure.

**Error state:** Defined in topic-16 (import error bottom sheet); ImportScreen stays visible behind the sheet.

**Success:** Navigate immediately to `/solve/:puzzleId` — do not show a confirmation step unless puzzle metadata (title/date) is missing entirely, in which case show a one-field "Name this puzzle" dialog before navigating.

---

## 4. Timer Pause Behavior

**Gap:** No doc defines pause mechanics or background behavior.

**Decisions:**

### User-initiated pause
- Tapping the timer label in the app bar toggles pause/resume.
- The timer displays a pause icon (⏸) when paused to signal the state.
- Paused state persists in `PuzzleState` (`isPaused: bool`) and is persisted to Drift so a killed-and-relaunched app resumes paused.
- Drift persistence uses `solve_sessions.is_paused`, `paused_at`, and `total_paused_ms`; `elapsed_ms` stores active solve time only and must not advance while paused.

### App-backgrounded (system pause)
- When the app enters background (`AppLifecycleState.paused`), the timer auto-pauses.
- On return to foreground (`AppLifecycleState.resumed`), show a full-grid overlay:

```
┌─────────────────────────────────┐
│  [blurred / dimmed grid]        │
│                                 │
│         ⏸  Paused              │
│                                 │
│     [  Tap to continue  ]       │
│                                 │
└─────────────────────────────────┘
```

- The overlay prevents inadvertent viewing of the grid while the timer is stopped.
- Tapping anywhere on the overlay resumes the timer and hides it.

### Elapsed time
- Timer counts only active (non-paused) time — consistent with topic-15's "active elapsed timer time" rule.

---

## 5. Archive Screen — Phase 1 Layout

**Gap:** Topic-10 specifies a calendar view, which breaks for import-only content with arbitrary or missing dates.

**Decision:** Phase 1 Archive uses a **vertical list**, not a calendar. Switch to calendar when a daily network source is enabled.

### List item layout

```
┌─────────────────────────────────────────────┐
│  ✓  The Guardian Cryptic — Monday           │
│     Guardian · Tue 28 Apr 2026 · 15×15      │
│     Completed  ·  4:23                      │  ← time shown if completed
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  ◑  LA Times Weekday Puzzle                 │
│     Imported · 15×15                        │
│     In progress · 2:11 elapsed             │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  ○  Untitled Puzzle                         │
│     Imported 1 May 2026 · 15×15            │
│     Not started                             │
└─────────────────────────────────────────────┘
```

Status icons: `○` not started · `◑` in progress · `✓` completed · `★` completed (personal best)

### Sort and filter

- Default sort: **import date descending** (most recent first).
- Sort picker: Import date / Puzzle date / Title (A–Z).
- Filter chips (horizontal scroll above list): All · In Progress · Completed · Not Started.

### Dates in Phase 1
- If `publish_date` is present in puzzle metadata, show it.
- If absent, show "Imported [date]".
- Do not show a calendar tab until a daily source with date-keyed content exists.

---

## 6. Keyboard Check Key Scope

**Gap:** The `[✓ Check]` key on the custom keyboard is undefined — topic-11 has three check scopes.

**Decision:** The keyboard Check key triggers **Check word** (the active word, not the focused letter or the whole puzzle). Rationale: letter-level is too narrow for a one-tap action; puzzle-level is too powerful and surprising. Word-level matches user intent 90% of the time.

Check letter and Check puzzle remain accessible via the overflow menu (⋮).

---

## 7. Onboarding Screen Format and Transition

**Gap:** Topic-10 describes steps but not format; topic-16 forbids requiring a puzzle file.

**Decision:** Use a **synthetic mock grid** — a hardcoded 5×5 crossword with 2 clues, authored by the development team, embedded as a const in the onboarding widget. This grid is never stored in Drift; it is purely presentational.

### Format: bottom-anchored card over the mock grid

```
┌─────────────────────────────────┐
│  [Skip]             1 of 3 ●○○ │  ← skip (top-right), step dots (top-right)
│                                 │
│   [5×5 mock grid, interactive]  │
│                                 │
│                                 │
├─────────────────────────────────┤
│  Tap a cell to focus it         │  ← step headline
│  Then type a letter.            │  ← step body
│                                 │
│            [ Next → ]           │
└─────────────────────────────────┘
```

### Three mandatory steps

| Step | Instruction | Completion trigger |
|------|-------------|-------------------|
| 1 | "Tap a cell to focus it. Then type a letter." | User enters any letter |
| 2 | "Tap the focused cell again to switch direction." | User toggles direction |
| 3 | "Use Check or Reveal in the menu to get help any time." | Timed (3 s) or user taps Next |

After step 3: card content changes to:

```
│  You're ready to solve!         │
│  Import a puzzle to get started.│
│                                 │
│  [ Import your first puzzle ]   │  ← primary button, goes to /import
│  [ Maybe later ]                │  ← text button, goes to Home
```

This bridges the onboarding-to-import cliff rather than dropping the user on an empty Home.

---

## 8. ClueBar Tap-to-Toggle Direction

**Gap:** Not defined whether tapping the ClueBar switches direction.

**Decision:** Yes — tapping the ClueBar toggles between the across and down clue for the focused cell, identical to double-tapping the cell itself. The ClueBar updates to show the new direction's clue text. If the focused cell belongs to only one word (e.g., a corner cell with no perpendicular), tapping the ClueBar does nothing (no animation, no feedback).

The ClueBar should display which direction is active with a small inline label:

```
│  ↔ 8-Across: Like a fox        │  ← "↔" or "↕" prefix for current direction
```

This makes the tap affordance more discoverable.

---

## 9. Clue List Auto-Scroll to Active Clue

**Gap:** Not addressed.

**Decision:** The clue list auto-scrolls to keep the active clue visible whenever the focus cell changes. Use `ScrollController.animateTo` with a 150 ms ease-out curve — fast enough not to feel sluggish, slow enough to be trackable.

Rules:
- If the active clue is already fully visible: no scroll.
- If the active clue is partially visible: scroll just enough to fully reveal it.
- If the active clue is off-screen: scroll to center it vertically in the list.
- Do not scroll if the user is actively scrolling the clue list manually (detect via `ScrollNotification`).

The active clue in the list is highlighted with `primaryContainer` background (see topic-10 color system).

---

## 10. Post-Completion Grid Review

**Gap:** No post-completion state defined after the stats sheet is dismissed.

**Decision:** After "View filled grid" is tapped on the stats sheet:

- Sheet dismisses.
- SolveScreen remains visible with the completed grid.
- Custom keyboard is hidden.
- ClueBar is still shown (read-only — tap still scrolls the clue list but does not change focus for editing).
- App bar shows: `← [source name]` and a `Share` icon (no timer — timer is replaced by final time: `⏱ 4:23`).
- All cells are non-editable. Tapping a cell focuses it (highlights it + shows its clue in ClueBar) but does not open the keyboard.
- Overflow menu in this state: Share result · Back to home. (Check/reveal options removed — puzzle is complete.)

Back button from this state: navigate to originating tab without confirmation dialog (no in-progress state).

---

## 11. Solve Screen Overflow Menu (⋮)

**Gap:** Only hint items were defined; full menu never specified.

**Decision:**

```
⋮ Menu — while solving (in-progress)
├── Check letter
├── Check word
├── Check puzzle
├── ─────────────────
├── Reveal letter
├── Reveal word
├── Reveal puzzle        ← triggers "This will fill the whole puzzle. Continue?" dialog
├── ─────────────────
├── Puzzle info          ← only shown when PuzzleMetadata.notes is non-empty (see §16)
├── ─────────────────
├── Pause timer          ← toggles; label changes to "Resume timer" when paused
└── Restart puzzle       ← triggers "Clear all letters and start over?" dialog
```

```
⋮ Menu — when completed (read-only state)
├── Share result
├── Puzzle info          ← only shown when PuzzleMetadata.notes is non-empty (see §16)
└── Back to home
```

"Restart puzzle" clears all cell progress, resets the timer to 0:00, and creates a new `solve_session` row (the old completed session, if any, is preserved).

---

## 12. Settings Screen Layout

**Gap:** Settings data model exists (added this session) but no screen layout defined.

**Decision:** Standard Material 3 `ListView` with section headers (`ListTile` groups separated by `Divider`s).

### Sections and items

**Appearance**
- Theme: System / Light / Dark (segmented button or radio sheet)
- Colorblind mode: toggle (swaps correct/incorrect colors — see topic-10)

**Gameplay**
- Haptics: toggle (default on)
- Sounds: toggle (default off)
- Skip filled cells on advance: toggle (default off)
- Keyboard layout: [Default] (selector — Phase 1 has only one layout; placeholder for future)

**Notifications**
- Puzzle reminder: toggle
  - → If on, show time picker row below (HH:mm) — stored as `daily_reminder_time`
- Streak reminder: toggle
  - → If on, show time picker row below (HH:mm) — stored as `streak_reminder_time`

**Privacy & Data**
- Crash reporting: toggle (default off until the user opts in; links to brief explanation)
- Export data: navigation row → triggers share sheet with `crossword.db`
- Import data: navigation row → triggers file picker for `.db` restore
- Delete all data: navigation row → destructive confirmation dialog

**Help**
- How to play: navigation row → replays OnboardingScreen tutorial (using the mock grid)
- About Crosscue: navigation row → version, open-source licenses, contact email

---

## 13. Grid Zoom/Pan Behavior

**Gap:** Pinch-to-zoom mentioned in topic-10 but pan and reset not defined.

**Decisions:**

- **Zoom range:** 1× (default) to 3× (maximum). Below 1× is not allowed.
- **Pan:** After any zoom > 1×, the user can drag the grid freely within the zoomed bounds. The grid does not pan outside its own edges.
- **Focus follow:** When the active cell changes (by tap, keyboard advance, or clue-list tap), the grid view animates to keep the active cell visible. If the cell is already visible, no pan. If it is off-screen, animate to center it (200 ms ease-out).
- **Reset:** Double-tap anywhere on the grid to reset to 1× zoom, centered on the active cell.
- **Zoom state is session-local:** Not persisted — reset to 1× on every solve session launch.
- **Implementation note:** Use `InteractiveViewer` widget with `constrained: false`, `minScale: 1.0`, `maxScale: 3.0`, and a `TransformationController` to programmatically center on the active cell.
- **Accessibility note:** After a zoom/pan gesture, the semantic bounding rectangles reported by `CustomPainter.semanticsBuilder` become stale relative to the screen — TalkBack may announce focus on the wrong cell. Attach a listener to the `TransformationController` and call `markNeedsSemanticsUpdate()` on the `CustomPainter` whenever the transform changes:
  ```dart
  _transformController.addListener(() {
    _gridPainterKey.currentContext
        ?.findRenderObject()
        ?.markNeedsSemanticsUpdate();
  });
  ```
  This forces Flutter to recompute semantic positions after every zoom or pan frame. Expose the painter via a `GlobalKey<State>` or a `ChangeNotifier`-based painter to make `markNeedsSemanticsUpdate()` accessible from the controller listener.

---

## 14. SolveScreen Load Failure State

**Gap:** Error states defined for import and offline sources but not for database read failures on SolveScreen.

**Decision:** If `PuzzleNotifier` fails to load the puzzle from Drift (e.g. a database error, missing record), show a full-screen error state instead of the grid:

```
┌─────────────────────────────────┐
│  ←  Puzzle                      │
├─────────────────────────────────┤
│                                 │
│       [error icon]              │
│                                 │
│  Couldn't load this puzzle      │  ← headline
│                                 │
│  Something went wrong on our    │
│  end. Your progress is safe.    │  ← body
│                                 │
│  [  Try again  ]                │  ← retries the Drift read
│  [  Back  ]                     │  ← navigates to originating tab
│                                 │
└─────────────────────────────────┘
```

The error state is displayed via `AsyncValue.error` handling in the `PuzzleNotifier` provider — no special widget needed beyond the standard error branch.

---

## 15. Notification Copy

**Gap:** Topic-06 defines architecture but copy strings are only sketched.

**Decision:** Finalized copy for Phase 2 local notifications. Phase 1 remains import-first and should not promise an automatic daily puzzle. Use daily-source language only after a licensed daily source is enabled; otherwise copy should point to continuing or importing a puzzle.

| Notification type | Title | Body |
|-------------------|-------|------|
| Reminder with in-progress puzzle | "Ready to keep solving?" | "Pick up where you left off in Crosscue." |
| Reminder with no active puzzle | "Ready for a puzzle?" | "Import or open a crossword when you have a minute." |
| Licensed daily source reminder (future only) | "Time to solve" | "Today's crossword is ready." |
| Daily reminder (puzzle already solved today) | — | *Do not send — suppress if today is already solved* |
| Streak reminder — streak ≥ 3 days, not yet solved | "Keep your streak going" | "You're on a {N}-day streak. Don't break it today." |
| Streak reminder — streak = 1 day | "Solve again today" | "You solved yesterday. Keep the momentum." |
| Streak milestone | "🔥 {N}-day streak!" | "You've solved {N} days in a row. Keep it up." |

Rules:
- Never send a reminder on a day the user has already completed a streak-eligible solve.
- Streak reminder fires at the user's configured reminder time if reminders are enabled. It is not a separate notification; it augments the reminder body on days when a streak is active.
- Milestone notifications fire immediately after completion triggers the milestone (see topic-15 thresholds: 7, 14, 30, 100, 365 days).
- Do not send multiple notifications in one day. If both daily and milestone would fire, send only the milestone notification.

---

## 16. Puzzle Notes Display

**Gap:** `PuzzleMetadata.notes` is parsed and stored but no doc defines where it is shown.

**Decision:** Puzzle notes (theme explanations, special rules) are shown in two places:

1. **Before solving (optional banner):** If `notes` is non-null and non-empty, display a dismissible info banner between the ClueBar and the grid with the notes text. Dismissed state is session-only — it reappears on the next launch of the same puzzle until the user taps "Got it."

```
┌──────────────────────────────────┐
│  ℹ️  All theme answers share a  │
│     hidden connection.  [Got it] │  ← info chip, dismissible
└──────────────────────────────────┘
```

2. **Overflow menu:** "Puzzle info" menu item opens a bottom sheet showing title, author, publisher, copyright, and notes — useful for users who dismissed the banner or for mid-solve reference.

If `notes` is null or empty, neither the banner nor the "Puzzle info" item appears.

---

## 17. Single-Puzzle Delete From Archive

**Gap:** No spec for deleting one puzzle and its solve history from the Archive.

**Decision:** Long-press on an Archive list item reveals a contextual action menu with:
- **Delete puzzle** — deletes the puzzle row, all its clues, and all its solve sessions (cascade from topic-02 schema). Requires a confirmation dialog: "Delete this puzzle and all solve history? This cannot be undone."
- **Cancel**

Swipe-to-dismiss is not used — accidental swipe deletes are too destructive for solve history. Long-press is intentional and less prone to error.

After deletion:
- If the deleted puzzle is the currently active puzzle in `PuzzleState`, clear active state and navigate to Home.
- Streak counts are recalculated on next Stats screen load; a delete that removes a streak-qualifying day will reduce the streak count. No special warning is shown (the confirmation dialog covers this).

---

## 18. Splash Screen / Launch Screen

**Gap:** No doc defines the Crosscue launch screen shown while Flutter initializes.

**Decision:**

**Android (`launch_background.xml`):**
- Background color: `#1565C0` (Crosscue brand blue, same as `primary` in light mode)
- Centered logo: the Crosscue app icon (partial grid with single letter), white, ~120 dp

**iOS (`LaunchScreen.storyboard`):**
- Same blue background, same centered icon
- No wordmark — icon only at launch

**Flutter splash → first frame:**
- Use `flutter_native_splash` package to generate the native launch screens from a single config
- After Flutter renders its first frame, transition directly to the app — no custom animated splash in the Flutter layer (native splash is enough)
- Set `flutter_native_splash` background color to `#1565C0` with `fullscreen: false`

Add `flutter_native_splash` to the architecture library table as a dev dependency.

---

## 19. Onboarding Mock Grid Design Constraint

**Gap:** Topic-17 §7 specifies a 5×5 const mock grid but doesn't define its structure. Step 2 (tap to toggle direction) silently fails if the focused cell has only one word through it.

**Decision:** The mock grid must have at least one cell at the intersection of an across word and a down word. The simplest valid 5×5 design that supports all three onboarding steps:

```
A C E # #     1-Across: ACE  (row 0, cols 0–2)
# # N # #     1-Down:   END  (col 2, rows 0–2)
# # D # #
# # # # #
# # # # #
```

Cell (0, 2) = 'E' is the intersection of 1-Across and 1-Down. The tutorial should focus on this cell so both Step 1 (tap to focus) and Step 2 (toggle direction) work correctly — the cell belongs to two words, so toggling is meaningful. The three-letter words keep the mock visually clean without needing a full grid layout.

---

## 20. Archive Orphan Session Handling

**Gap:** "Restart puzzle" creates a new `solve_session`; Archive must not show abandoned mid-solve sessions as separate list entries.

**Decision:** Archive queries use the latest session per puzzle, not all sessions:

```sql
-- Dart/Drift equivalent
SELECT * FROM solve_sessions s1
WHERE s1.last_played_at = (
  SELECT MAX(s2.last_played_at)
  FROM solve_sessions s2
  WHERE s2.puzzle_id = s1.puzzle_id
)
ORDER BY s1.last_played_at DESC;
```

Rules:
- If the latest session is `completed`, show the puzzle as Completed with its solve time.
- If the latest session is `in_progress`, show as In Progress.
- Abandoned sessions (replaced by a restart) are retained in the database for stats accuracy but never surfaced in the Archive list view.
- The Stats screen total-puzzles count uses only sessions with `completion_type IN ('clean', 'checked', 'hinted', 'revealed')`, so abandoned restarts do not inflate the count.

---

## Implementation Checklist

1. Add `isPaused` field to `PuzzleState` and wire `AppLifecycleListener` to auto-pause on background.
2. Build `CompletionStatsSheet` as a `DraggableScrollableSheet` driven by `PuzzleStatus` transitions in `PuzzleNotifier`.
3. Add `isReadOnly` mode to `SolveScreen` for post-completion grid review.
4. Build `ImportScreen` with the three-zone layout above; add loading state widget that replaces the CTA button.
5. Add the mid-solve back-navigation dialog to `SolveScreen`'s `PopScope` (`canPop: false`, `onPopInvokedWithResult`). Note: `WillPopScope` is removed in current Flutter — use only `PopScope`.
6. Build `OnboardingScreen` with synthetic 5×5 const mock grid and three-step card overlay.
7. Implement `ArchiveScreen` as a list view with sort/filter; defer calendar to Phase 2.
8. Wire `ScrollController` auto-scroll in the clue list panel.
9. Add direction indicator prefix to `ClueBar` and wire `ClueBar` tap to `toggleDirection` command.
10. Set keyboard Check key to trigger `checkWord` command.
11. Complete the overflow menu (`⋮`) items in SolveScreen including Pause timer and Restart puzzle.
12. Build `SettingsScreen` with the five-section layout.
13. Wrap `CrosswordGrid` in `InteractiveViewer` with `TransformationController`; add double-tap-to-reset gesture.
14. Add `AsyncValue.error` handling branch to `SolveScreen` with the retry/back error UI.
15. Finalize notification strings in the `flutter_local_notifications` scheduler before Phase 2 reminders ship.
16. Display `PuzzleMetadata.notes` as a dismissible banner above the grid and as a "Puzzle info" overflow item when non-empty.
17. Add long-press delete to Archive list items with confirmation dialog; cascade-delete clues and sessions.
18. Configure `flutter_native_splash` with `#1565C0` background + app icon before first TestFlight/Play Store build.
19. Design the onboarding 5×5 mock grid with the intersection cell at (0, 2) as described in §19.
20. Implement Archive DAO query using latest-session-per-puzzle logic to suppress orphan restart sessions.

## Sources

- [topic-10-design-ux-research.md](topic-10-design-ux-research.md)
- [topic-11-game-mechanics-feedback.md](topic-11-game-mechanics-feedback.md)
- [topic-13-screen-inventory-routes.md](topic-13-screen-inventory-routes.md)
- [topic-15-streak-stats-algorithm.md](topic-15-streak-stats-algorithm.md)
- [topic-16-first-run-phase1.md](topic-16-first-run-phase1.md)
- [architecture-design-review.md](../docs/archive/architecture-design-review.md)
