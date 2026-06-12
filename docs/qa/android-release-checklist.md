# Android Release QA Checklist

> **Status:** Living — the Android counterpart to
> [`ios-release-checklist.md`](ios-release-checklist.md).

Run this once per public-facing Android release (Play internal promotion to
closed/open testing, production) on at least one phone; add a tablet/foldable
pass when available. ~15 minutes per device once the build is installed.

**Prerequisites**
- The release build from the **Play track** (or the release-signed APK from
  the GitHub Release) — **never a debug build**: R8 minification and resource
  shrinking are release-only and "can break plugin reflection in ways debug
  builds will not catch" (DEPLOYMENT.md).
- A `.puz` or `.ipuz` file reachable on the device (Files/Drive/Gmail).

---

## Automated coverage (context)

The Flutter `integration_test` suite currently runs in CI on **iOS only**
(`integration-test-ios.yml`). Individual tests can be run locally against an
emulator (`flutter test integration_test/<file>.dart -d <android-device-id>`,
see DEPLOYMENT.md) — doing so before this manual pass is recommended. An
Android CI leg is tracked work (design review 2026-06-11 §5.4).

---

## 1. Install & first launch

- [ ] App installs from the Play track without errors
- [ ] App icon and name ("Crosscue", not the Flutter default) render on the
  launcher; adaptive icon looks correct in round/squircle masks
- [ ] First launch shows onboarding or a non-empty home screen — no crash,
  no blank frame (watch specifically for R8-related startup crashes)
- [ ] Status bar / navigation bar contrast correct in both gesture-nav and
  3-button-nav modes; no content under the camera cutout

## 2. Import a puzzle

- [ ] Open a `.puz` from Files ("Open with" → Crosscue) → imports and opens
- [ ] Share a `.puz` from Drive or Gmail → Crosscue appears in the share
  sheet and imports correctly
- [ ] Repeat with `.ipuz`
- [ ] In-app import button → system file picker opens (this is the
  `FileType.any` path — regression here historically hung the picker, see
  CONVENTIONS.md), picking a non-puzzle file shows a clean rejection
- [ ] Imported puzzles appear in the home list with correct metadata

## 3. Solving — basic input

- [ ] Tap an empty cell → cell highlights, soft keyboard appears
- [ ] Type a letter → fills, focus advances; tap same cell → direction flips
- [ ] Backspace → clears and moves back; clue tap → grid jumps to the clue
- [ ] **Bluetooth/USB keyboard** (if available): letters, arrows, backspace,
  and `Esc` (rebus dialog) all work — the Android focus plumbing has its own
  history (shared-FocusNode crash, CONVENTIONS.md)

## 4. Solving — rebus

- [ ] "Rebus" key on the soft keyboard opens the dialog; multi-letter entry
  renders with autoshrink, no clipping
- [ ] Long-press a cell → "Enter rebus" pre-fills current content

## 5. Persistence & lifecycle

- [ ] Solve ⅓ of a puzzle, background the app (home gesture) → reopen →
  exact resume, timer correct
- [ ] Swipe the app away from Recents → relaunch → same progress
- [ ] **System back** from the solve screen returns to home (does not exit
  the app from a nested screen); back on the home tab exits cleanly
  (predictive-back animation OK on Android 14+)
- [ ] Rotate during a solve (if rotation enabled) / window resize → no state
  loss

## 6. Stats

- [ ] Complete a small puzzle → stats screen shows the entry; streak reflects
  the completion

## 7. Settings & privacy

- [ ] Theme toggle (Light/Dark/System) switches live
- [ ] **Material You:** with a strongly-colored wallpaper, dynamic color
  harmonizes but brand roles hold — grid semantic colors must NOT follow the
  wallpaper accent (ARCHITECTURE.md → Theme System)
- [ ] Privacy policy link opens the published page
- [ ] `Clear all data` works; if Challenge Boards was used, it reports the
  server-side deletion (or the offline retry dialog)

## 8. Visual & accessibility

- [ ] Dark mode pass over every screen (table in DEPLOYMENT.md → Dark-mode QA)
- [ ] System font size at maximum (Settings → Display → Font size) → text
  scales without overlap
- [ ] TalkBack smoke test on home + solve: controls reachable and announced
- [ ] Colorblind mode: verification shows blue/orange + ✓/✗ symbols

## 9. Tablet / foldable (skip if unavailable)

- [ ] Split-screen with another app → reflows, no crash, no state loss
- [ ] Fold/unfold posture change mid-solve → grid relaid out correctly

## 10. Edge cases

- [ ] Airplane Mode on/off → no crashes; offline-first flows unaffected;
  Past-puzzles section degrades quietly (no fabricated content)
- [ ] Lock device 30 s mid-solve → unlock → same cell, timer sane
- [ ] Incoming call/notification mid-solve → graceful on return
- [ ] Battery saver enabled → app remains usable
- [ ] Uninstall prompt offers data preservation (`hasFragileUserData`) —
  verify the prompt appears on Android 10+

## 11. Challenge Boards (only on builds with a configured backend)

- [ ] Challenge tab loads real boards (not sample data) — a release build
  must never show sample boards (#236 makes misconfiguration throw at
  startup; verify it didn't)
- [ ] Submit an eligible daily-mini result → appears on the board
- [ ] Invite link tap (`https://crosscue.app/join/...`) from a messaging app
  → opens the app to the join preview (App Links `autoVerify`); from a
  browser without the app → `join.html` fallback

## 12. Sync (only once Google Drive OAuth is live — currently inert)

- [ ] Settings → Sync → enable → Google sign-in prompt appears and completes
- [ ] "Sync now" succeeds; second device sees the data (two-device soak is a
  separate procedure — `sync-icloud-setup.md` Step 5 pattern)
- [ ] While inert (no OAuth clients): the toggle fails gracefully, no crash

## 13. Home-screen widget

- [ ] **N/A — no Android widget exists yet** (parity debt, ADR-0015 / P1).
  When the Glance widget ships, mirror iOS checklist §11 here.

---

## Reporting bugs found during QA

Same flow as iOS: screenshot/recording → new GitHub issue with device,
Android version, steps, expected vs. actual. Block the release on failures in
sections 1–7; file 8–10 findings as enhancements unless severe.

## After QA passes

1. Mark the QA pass complete in the release issue.
2. Promote the build to the target Play track in Play Console.
3. Monitor Play Console → Quality (ANRs/crashes) for the first days after
   rollout — this is the only crash signal that exists (no remote crash
   reporting, by design).
