# iOS Release QA Checklist

> **Status:** Living. Android counterpart:
> [`android-release-checklist.md`](android-release-checklist.md).

Run this once per public-facing iOS release (TestFlight external, App Store) on
both an iPhone and an iPad. Takes ~15 minutes per device once the build is
installed.

**Prerequisites**
- TestFlight build processed and installable (you'll get an email from Apple
  when processing finishes — usually 5-30 minutes after the workflow's
  TestFlight upload step succeeds)
- TestFlight app installed on the target devices
- A `.puz` or `.ipuz` file available — easiest: AirDrop one from your Mac, or
  open from Files / Mail / Messages

---

## Automated coverage (run this first)

Much of sections 1, 3, 4, 5, 6, 7 is now covered by the Flutter
`integration_test` suite. Run it on a simulator before the manual pass:

```sh
scripts/run-ios-integration-tests.sh             # auto-picks/boots a simulator
scripts/run-ios-integration-tests.sh "iPhone 16" # or a name / UDID
```

It boots a simulator, runs every `crosscue/integration_test/*_test.dart`, and
drops a final-frame screenshot per test into `design/qa/ios-<git-sha>/`. The
same suite runs on demand in CI via the **Integration tests (iOS)** workflow
(`workflow_dispatch` only — it's costly, so it's not part of the per-PR gate).

What the suite exercises today:
- `app_launch_test` — boots to the first frame (§1, partial)
- `seed_and_solve_test` — seed a puzzle, open it, render the solve screen (§3)
- `rebus_and_navigation_test` — rebus entry via the long-press menu; Stats &
  Settings render (§4, §6, §7)
- `lifecycle_and_theme_test` — background/resume persistence; live dark-mode
  toggle (§5 partial, §8 partial)

**Still requires a human on a real device** (OS-level, not automatable here):
§2 import via the share sheet, §8 Dynamic Type, §9 iPad multitasking /
rotation, §10 edge cases (Airplane Mode, calls), and true force-quit. A green
suite means the manual pass below can focus on these.

---

## 1. Install & first launch

- [ ] App installs from TestFlight without errors
- [ ] App icon and display name render correctly on the home screen
  (icon should not be the default Flutter "F", name should be "Crosscue")
- [ ] First launch shows onboarding or a non-empty home screen (no crash, no
  blank white screen)
- [ ] Status bar text is visible (light text on dark backgrounds, dark on light)
- [ ] No content is clipped by the Dynamic Island / notch / home indicator

## 2. Import a puzzle

- [ ] Share a `.puz` file from another app (Files, Mail, Messages) → Crosscue
  appears in the share sheet
- [ ] Selecting Crosscue opens the puzzle directly (no intermediate "imported"
  screen issues)
- [ ] Repeat with a `.ipuz` file
- [ ] Imported puzzles appear in the home/library list with correct metadata
  (title, source, date)

## 3. Solving — basic input

- [ ] Tap an empty cell → cell highlights, keyboard appears
- [ ] Type a letter → letter fills the cell, focus advances to the next cell
  in the current direction
- [ ] Tap the same cell again → solve direction flips between Across and Down
- [ ] Swipe left/right or up/down across cells → focus moves accordingly
- [ ] Backspace → removes the current cell's letter, focus moves back one cell
- [ ] Tap a clue in the clue list → grid jumps to that clue's first cell

## 4. Solving — rebus

- [ ] Long-press a cell → rebus dialog opens with current content pre-filled
- [ ] Type a multi-letter entry (e.g., `EST`) and press the **Enter** button →
  cell shows the rebus correctly, focus advances
- [ ] Long-press the same cell again → rebus dialog reopens with the current
  rebus content pre-filled (matches NYT pre-fill behavior)
- [ ] Dismiss the dialog by tapping outside it → no debug/error screen; the
  current entry is handled as the dialog indicates

## 5. Persistence

- [ ] Solve about ⅓ of a puzzle, then put the app in the background (swipe
  up to the home screen)
- [ ] Reopen Crosscue → puzzle resumes exactly where you left off, timer
  continues from the right point
- [ ] Force-quit Crosscue (swipe up + away from app switcher) → relaunch →
  same puzzle, same progress, timer correct

## 6. Stats

- [ ] Complete a small puzzle end-to-end → stats screen shows the entry with
  the correct time and date
- [ ] Streak indicator (if shown) reflects the completion

## 7. Settings & privacy

- [ ] Settings → toggle theme (Light / Dark / System) → app theme switches
  correctly without restarting
- [ ] Settings → Privacy & Data → Privacy policy → opens the published policy
  in Safari (`https://atomictrxn.github.io/crosscue/privacy.html`)
- [ ] Any other in-app links resolve to working URLs
- [ ] `Clear all data` works; if Challenge Boards was used, it reports the
  server-side deletion (or offers the offline retry path)

## 8. Visual & accessibility

- [ ] Toggle dark mode → all screens still look correct (no white-on-white
  text, no missing icons)
- [ ] Toggle iOS Dynamic Type to "Larger Accessibility Size" (Settings →
  Accessibility → Display & Text Size → Larger Text) → app text scales, no
  overlapping content
- [ ] (Optional) Toggle Increase Contrast and Reduce Transparency → app
  remains usable
- [ ] (Optional) VoiceOver smoke test on the home screen → focusable
  controls are reachable and announced

## 9. iPad-specific

Skip if testing on iPhone only.

- [ ] App launches in portrait → grid uses the wider layout, not a centered
  iPhone-sized column
- [ ] Rotate to landscape → grid + clue panel reflow correctly (no clipping,
  no overlapping panels)
- [ ] Split View with another app side-by-side → app reflows at smaller
  widths without crashing or losing state
- [ ] Slide Over (small floating Crosscue window) → app remains usable, no
  rendering glitches
- [ ] iPad keyboard shortcuts (if supported) — Cmd-Z / Cmd-Shift-Z, arrow
  keys, return — behave as expected

## 10. Edge cases

- [ ] Cycle Airplane Mode on/off → no crashes, no offline error banners that
  shouldn't appear (Crosscue is offline-first)
- [ ] Open a puzzle, lock the device, wait 30s, unlock → app resumes at the
  same cell, timer doesn't lose seconds inappropriately
- [ ] Receive a notification or phone call mid-solve → app handles
  interruption gracefully when foregrounded again
- [ ] Low-memory: install on the oldest supported device you own (minimum
  iOS target is `16.0` per `Runner.xcodeproj` / `Podfile`) and confirm core
  flows still work

## 11. Home-screen widget background refresh (#175)

> **Best-effort, not guaranteed.** The home-screen widget's "today" tile is
> kept current by a `BGAppRefreshTask` (and Android WorkManager). **iOS decides
> when — or whether — it runs**, based on how often the user opens the app; for
> low-engagement users it may fire rarely or not at all. This only affects the
> *widget glance* for someone who hasn't opened the app in a day or two — the
> in-app on-open experience is always fresh (Crosshare auto-download + refresh).
> Don't treat a stale tile after a long gap as a bug.

- [ ] On-open refresh still works (the reliable path): with the widget added,
  open the app on a new day → the tile reflects today's puzzle + streak.
- [ ] (Best-effort, may not fire) Leave the app closed overnight with
  auto-download on → the tile updates on its own. If it doesn't, this is
  expected iOS throttling, not a regression.
- [ ] Cold-start time is unchanged — scheduling runs post-first-frame, never
  on the critical launch path.

To force the iOS task during development (instead of waiting for the OS), pause
in the debugger right after launch and run:
`e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"dev.tomhess.crosscue.refresh"]`

## 12. Challenge Boards (only on builds with a configured backend)

- [ ] Challenge tab loads real boards rather than sample data
- [ ] Create or join a board, set a display name, then select a photo avatar →
  it renders in the board; replace it with a built-in silhouette → the board
  remains usable and the former photo no longer renders
- [ ] Submit an eligible daily-mini result → it appears on the board
- [ ] Open an invite link from Messages/Safari → app opens to the join preview;
  without the app, the web fallback renders
- [ ] `Clear all data` after using the feature reports server deletion; confirm
  the avatar and player cannot be retrieved afterward when a test environment
  is available

## 13. Sync (only when this build is configured for iCloud)

- [ ] Enable sync → iCloud authorization/status completes without a crash
- [ ] Sync now succeeds; a second device using the same iCloud account sees
  the expected library/progress changes
- [ ] Turn off and remove cloud copy → the app confirms removal; local data
  behavior matches the choice shown in the UI

## 14. App Intents (Shortcuts / Spotlight / Siri)

- [ ] In Shortcuts, the three Crosscue actions (Today's Puzzle, Stats,
  Continue) appear and reach the expected screen from both cold and warm start
- [ ] Spotlight and Siri, where enabled on the test device, surface/run the
  actions without a stale or incorrect route

---

## Reporting bugs found during QA

For each bug:
1. Take a screenshot or screen recording on the device
2. Open a new GitHub issue at https://github.com/AtomicTrxn/crosscue/issues/new
3. Include: device + iOS version, reproduction steps, expected vs. actual,
   the screenshot or recording

Block submitting for review if any item in sections 1-7 or 12-14 fails. File
failures in sections 8-10 as enhancements unless they cause a crash, data loss,
an accessibility regression, or a store-review blocker.

## After QA passes

1. Mark this release's QA pass complete in the release issue
2. App Store Connect → submit the prepared build for review
3. Monitor App Store Connect for review status; typical turnaround is 1-3 days
