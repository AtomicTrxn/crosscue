# Crosscue — Application Review & Gap Analysis

**Date:** 2026-06-07
**Reviewed against:** `main` @ `73939ee` (post #197)
**Method:** Static review of the Flutter app (`crosscue/lib`, `crosscue/test`), native code (`ios/`, `android/`), the challenge-boards Worker backend (`crosscue/backend/challenge_boards`), build/config, and all 5 open GitHub issues. No runtime profiling was performed; findings are code- and config-based.

> **Overall:** the core product (offline solving, import, stats, archive, cross-device sync) is mature, well-tested, and cleanly layered. The notable risk areas are all in **recently-added or partially-scaffolded surfaces**: Challenge Boards (large, defaults to sample data, conventions diverge), an unimplemented reminders/notifications layer, an unimplemented paid tier, and several **iOS-only platform features** with no Android parity.

---

## 1. Summary table

Legend — **Type:** `Issue` = open GitHub issue · `Finding` = review finding · `Parity` = iOS/Android feature gap. **Status:** does it still exist / need action?

| ID | Type | Area / Feature | What it is | Status | Possible remediation |
|----|------|----------------|------------|--------|----------------------|
| **#114** | Issue | iOS WidgetKit widget | Streak + today's puzzle Home/Lock-screen widget | **Implemented** (`ios/CrosscueWidget/`, acceptance all checked) — issue stale | Verify on device, then **close**. Track Android parity as new issue → see P1 |
| **#115** | Issue | iOS App Intents (Shortcuts/Siri/Spotlight) | 3 intents: today's puzzle, stats, continue solve | **Implemented** (`ios/Runner/CrosscueAppIntents.swift`) — issue stale | Verify in Shortcuts/Siri, then **close**. Android parity → see P2 |
| **#159** | Issue | Challenge Boards (private friend boards) | Full design for invite-only boards, UTC leaderboards, Worker+D1 backend | **Partially built** (UI + client + Worker foundation via #194); **not production-wired** | Deploy Worker, wire `CHALLENGE_API_BASE_URL`, implement invite deep links, recovery bundle, retention cron, privacy policy. See F1/F5 |
| **#128** | Issue | Dependency stack bump | drift/sqlite3/file_picker/share_plus/package_info_plus | **Still blocked** (versions still pinned in `pubspec.yaml`) | Upgrade Flutter SDK first (meta ≥1.18), then coordinated `pub upgrade --major-versions` |
| **#183** | Issue | `SolveNotifier` refactor | Split ~707-line notifier's public surface by responsibility | **Still valid, optional** (file unchanged) | Low priority; act only if the file becomes a friction point |
| **F1** | Finding | Challenge Boards data | Tab defaults to **sample/placeholder data**; real API gated behind build-time define + deployed Worker | Open | Decide: feature-flag the tab off until backend is live, or ship with clear "preview" labeling; confirm release builds inject the base URL |
| **F2** | Finding | Challenge Boards code quality | 31/39 files carry a blanket `// ignore_for_file:` (8 lints); feature ships its **own** theme/palette/nav parallel to `core/` | Open | Bring files up to project lint standard; converge on `core/theme` + `core/routing`; treat as tech-debt cleanup before further investment |
| **F3** | Finding | Reminders / notifications | Settings **keys** + sync exclusions scaffolded, but **no plugin, no scheduler, no UI** — both platforms | Open | Either implement (`flutter_local_notifications` + zoned scheduling + settings UI) or remove the dead scaffolding |
| **F4** | Finding | Paid / licensed tier | `FreeEntitlementService` + `licensed_daily_reminder_enabled` key scaffold a paid tier that doesn't exist | Open | Decide monetization direction; remove or build out the entitlement layer |
| **F5** | Finding | Invite deep links | `/challenge/join` route exists; **no** Android App Links / iOS Universal Links config | Open | Add intent-filters + `autoVerify`, Associated Domains, AASA/`assetlinks.json`, cold-start route handling |
| **F6** | Finding | Sync manifest scalability | Manifest is one JSON blob, one entry per remote blob, read+rewritten on every write-pass | Low | Monitor blob size for large libraries; consider sharding the manifest per-namespace if it grows |
| **F7** | Finding | Minor cleanups | Vestigial `archive` nav icon, leftover `_keyStreakReminder`, local `.wrangler/state` DB files, dual challenge screen folders | Low | Housekeeping pass |
| **P1** | Parity | Home/Lock-screen widget | WidgetKit widget is **iOS-only**; no Android Glance widget | iOS only | Build an Android Glance `AppWidgetProvider`; `home_widget`/WorkManager plumbing already runs on Android (currently a no-op) |
| **P2** | Parity | Shortcuts / voice / launcher intents | App Intents are **iOS-only** | iOS only | Add Android App Shortcuts (static/dynamic) + optionally Assistant App Actions |
| **P3** | Parity | Branded share sheet | Native branded share is **iOS-only**; Android uses `share_plus` | iOS richer | Acceptable; optionally brand the Android share preview |
| **P4** | Parity | Sync backend & restore | iOS = iCloud, Android = Google Drive (by design); **no cross-platform restore** | By design | Document the limitation; relevant to the challenge-identity recovery bundle (#159) which also can't cross platforms |

---

## 2. Detailed findings

### Open issues — status & context

#### #114 — iOS WidgetKit widget — *Implemented; recommend close*
`ios/CrosscueWidget/` exists (`CrosscueWidget.swift`, `CrosscueWidgetBundle.swift`, `CrosscueWidgetControl.swift`) with the App Group entitlement, and every acceptance checkbox in the issue is checked. Dart side pushes state via `home_widget` driven by `WidgetRefreshScheduler` (WorkManager/BGTask). **The issue is stale-open.** Action: verify rendering on a device build (memory notes the release/device build still needs the App Store provisioning profile re-issued with App Groups), then close. **The Android counterpart does not exist** — see **P1**.

#### #115 — iOS App Intents — *Implemented; recommend close*
`ios/Runner/CrosscueAppIntents.swift` declares `OpenTodaysPuzzleIntent`, `OpenStatsIntent`, `ContinueLastSolveIntent`, and a single `CrosscueShortcuts: AppShortcutsProvider`. It uses the App Group `pendingIntentRoute` token pattern (string route id, additive — matching the issue's "don't centralize behind an enum" guidance). **Stale-open.** Action: verify in Shortcuts/Siri/Spotlight and close. **No Android equivalent** — see **P2**.

#### #159 — Challenge Boards (private friend boards) — *Partially built, not production-wired*
This is a very large design ticket. #194 delivered a real **foundation**, not just a stub:
- **Flutter UI:** complete tab + board detail + sheets (`lib/features/challenge_boards/**`, 39 files).
- **Flutter client/data:** `ApiChallengeRepository`, `ChallengeBoardApi` (Dio), `ChallengeIdentityStore`, `ChallengeResultOutbox`, and `ChallengeResultSubmitter` — and result submission **is wired into the solve-completion path** (`solve_notifier.dart:710`, `submitOrQueue`, fire-and-forget).
- **Backend:** `crosscue/backend/challenge_boards/` is a genuine Cloudflare Worker — `src/index.ts` (~1,184 lines), 3 D1 migrations, `API.md`, Miniflare tests (`worker.test.mjs`), smoke script.

**What's missing / not production-ready** (the bulk of #159's acceptance list):
- The Worker isn't deployed, and the app **defaults to sample data** (F1).
- Invite **deep links** have no native plumbing (F5).
- Same-cloud **player recovery bundle**, **retention cron**, **rate limiting**, **display-name server-side safety**, and the **privacy-policy / QA** updates are not evidenced.
- The Archive→Settings + Challenge-as-primary-tab navigation migration **is done** (Archive is reachable from Settings; Challenge is one of the 4 shell tabs).

Action: treat #159 as in-progress; the remaining work is productionization (deploy + config + deep links + privacy), not greenfield.

#### #128 — Coordinated dependency bump — *Still blocked*
`pubspec.yaml` confirms the pins are unchanged: `drift ^2.20`, `sqlite3_flutter_libs ^0.5`, `file_picker ^11.0.2`, `share_plus ^12`, `package_info_plus ^9`. The issue's own analysis says this is blocked on the Flutter SDK's `meta 1.17` pin. Action unchanged: **upgrade the Flutter SDK first**, then re-attempt the coordinated major-version bump and re-run DB-migration + codegen.

#### #183 — `SolveNotifier` refactor — *Still valid, optional*
`solve_notifier.dart` is still the largest notifier and exposes the broad public surface described. The issue itself calls this **optional polish**, not a defect, and notes the hard logic is already delegated. Action: defer unless the file becomes a maintenance friction point.

---

### Review findings

#### F1 — Challenge Boards renders **sample data** by default *(highest-impact finding)*
`ChallengeApiConfig.fromDartDefines()` resolves `baseUrl` from `CHALLENGE_API_BASE_URL` / `CHALLENGE_API_ENV`. With no build-time override:
- `sample` (the default) and even `staging`/`production` env names resolve `baseUrl: null`;
- only `local` auto-points at a localhost Worker, or an explicit URL override is honored.

In `challenge_board_providers.dart`, every repository falls back to `SampleChallengeRepository` when `apiChallengeRepositoryProvider == null`, and `ChallengeResultSubmitter` is constructed `enabled: api != null`. **Net effect:** unless a release build injects `CHALLENGE_API_BASE_URL` *and* the Worker is deployed, the Challenge **primary tab shows fabricated boards/leaderboards** and submissions are silently dropped.

**Risk:** a first-class tab presenting fake social data to real users; honor-system result submission no-ops.
**Remediation options:**
1. Gate the Challenge tab behind a runtime flag that's off until the backend is live; or
2. Ship it clearly labeled as a non-functional preview; and
3. Confirm what the current TestFlight/Play builds actually inject (verify the release pipeline's `--dart-define`s).

#### F2 — Challenge Boards diverges from project conventions *(tech debt)*
- **Lint bypass:** 31 of 39 `challenge_boards` Dart files begin with an identical `// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls`. The rest of the codebase is lint-clean; this feature opts out wholesale.
- **Parallel infrastructure:** the feature ships its own `theme/app_colors.dart`, `theme/app_text_styles.dart`, `challenge_palette.dart`, and `widgets/challenge_bottom_nav.dart` — duplicating `core/theme/**` and the app's `NavigationBar` shell. It also uses a non-standard folder layout (`screens/`, `sheets/`, `widgets/`, `avatar/` at the feature root) instead of the `presentation/…` layering used by every other feature.

This pattern (blanket ignores + self-contained theme/nav) reads like externally-generated code grafted in. It works, but it's a maintenance and consistency liability that will compound as the feature grows.
**Remediation:** schedule a conventions pass — remove the blanket ignores file-by-file, fold styling into `core/theme`, and align the folder structure — **before** investing further in the feature.

#### F3 — Reminders / notifications are unimplemented on both platforms
`app_settings_table.dart` documents canonical keys `daily_reminder_enabled`, `daily_reminder_time`, `streak_reminder_enabled`, `streak_reminder_time`, `notifications_sound_enabled`, `notifications_last_scheduled_at`, `licensed_daily_reminder_enabled`, and `SettingsSyncAdapter.excludedKeys` deliberately excludes `notifications_last_scheduled_at`. **But:** there is **no** notifications package in `pubspec.yaml` (no `flutter_local_notifications`/equivalent), **no** scheduling code anywhere in `lib`, and **no** settings UI surfacing these toggles. The only live reference is a stray `_keyStreakReminder` constant in the settings repo.
**Risk:** dead scaffolding that implies a shipped feature; sync logic already reserves keys for it.
**Remediation:** either implement the feature (add the plugin, a zoned daily/streak scheduler honoring the keys, permission prompts, and a Settings "Reminders" section) or remove the vestigial keys/exclusions to avoid confusion.

#### F4 — Paid / licensed tier is scaffolded but unimplemented
`lib/core/entitlement/` contains `EntitlementService` + `FreeEntitlementService` (everything free), and the settings keys include `licensed_daily_reminder_enabled`. No store-billing integration exists.
**Remediation:** decide the monetization direction. If none planned near-term, remove the entitlement abstraction and the `licensed_*` key to reduce dead surface; if planned, track it as an explicit epic.

#### F5 — Invite deep links have no native plumbing
`Routes.challengeJoin = '/challenge/join'` and `challengeBoard(id)` exist in the router, but `android/app/src/main/AndroidManifest.xml` declares only `MAIN`/`LAUNCHER` + `PROCESS_TEXT` (no App Links intent-filter, no `autoVerify`, no scheme/host), and there's no iOS Associated Domains / AASA config. `#159`'s `https://crosscue.app/join/<boardId>?token=...` flow therefore cannot open the app.
**Remediation:** add Android App Links (intent-filter + `autoVerify` + hosted `assetlinks.json`), iOS Universal Links (Associated Domains + hosted `apple-app-site-association`), Flutter cold-start + warm-start route handling, and the Cloudflare web fallback page. Required before private boards are usable.

#### F6 — Sync manifest scalability (future consideration) *(low)*
The incremental-sync manifest (`manifest/v1.json`, shipped in #195–#197) is a **single JSON document holding one entry per remote blob across all namespaces**, read once per sync and **rewritten whenever a pass produces writes**. For a heavy user with a large imported library this single blob grows unbounded and becomes a non-trivial Drive read+write each active sync — partially eroding the latency win for the largest libraries.
**Remediation (only if observed):** shard the manifest per namespace (e.g. `manifest/puzzles.json`), or cap/compact it. No action needed at current scale; worth a size metric during beta.

#### F7 — Minor cleanups
- `core/routing/nav_icons.dart` still defines an `archive` icon/painter though Archive is no longer a shell tab (moved into Settings) — vestigial.
- `app_settings_repository_impl.dart` has a leftover `_keyStreakReminder` constant tied to the unbuilt reminders feature (F3).
- `backend/challenge_boards/.wrangler/state/**` (local Miniflare D1/cache sqlite files) are present on disk — confirm they're gitignored and not committed.
- Two challenge screen folders (`presentation/screens/` router wrappers vs `screens/` content). Not a bug (the wrapper delegates to `ChallengeTabScreen`), but it muddies the layering (ties into F2).

---

### Platform-parity gaps (iOS vs Android)

#### P1 — Home/Lock-screen widget: **iOS only**
WidgetKit widget exists (`ios/CrosscueWidget/`); `find android -iname '*widget*'` returns nothing — there is **no Android Glance/`AppWidgetProvider`**. The cross-platform plumbing already runs on Android: `WidgetRefreshScheduler` registers a WorkManager periodic task on Android and `home_widget` is a dependency — but with no Android widget receiver, that background work pushes state to nothing (wasted wake-ups).
**Remediation:** implement an Android Glance widget reading the same shared-prefs payload `home_widget` already writes; the Dart side needs little change.

#### P2 — Shortcuts / Siri / Spotlight: **iOS only**
`CrosscueAppIntents.swift` provides App Intents on iOS. Android has no App Shortcuts (static `shortcuts.xml` or dynamic `ShortcutManager`) and no Assistant App Actions / Quick Settings tile.
**Remediation:** add Android static/dynamic App Shortcuts for the same three actions (today's puzzle, stats, continue solve) using the existing string-route mechanism.

#### P3 — Branded share sheet: **iOS richer** *(minor)*
`ResultShare` routes through a native `crosscue.share` MethodChannel on iOS (branded `LPLinkMetadata` icon); every other platform uses `share_plus`. Android sharing works but is unbranded. Acceptable; brandable later if desired.

#### P4 — Sync backend & cross-platform restore: **by design**
iOS uses iCloud (`ICloudSyncHandler.swift`), Android uses Google Drive AppData (`google_sign_in` + `googleapis`). Both are first-class, but **there is no cross-platform restore** — an iOS user can't recover their library on Android and vice-versa. This also constrains #159's challenge-identity recovery bundle (same-cloud only). Document the limitation in-product; #159 already flags manual recovery-code export as separate future work.

---

## 3. What's solid (for balance)

- **Sync** is well-architected: typed transport errors, adapter merge rules (set-union, LWW, best-progress override, FK skip-and-retry), and the new manifest/cursor incremental layer are thoroughly unit-tested (577 tests pass).
- **Database migrations** (v1→v7) are additive, guarded for minimal historical schemas, and individually tested.
- **Solve engine** delegation (`GridProgressMutator`, `SolveFocusNavigator`, `ClueProgressCalculator`, `SolveElapsedSeconds`) keeps the notifier honest despite its size.
- **Accessibility** support was added (#179) across grid/keyboard/clues/timer.
- The codebase is otherwise **lint-clean and convention-consistent** — which is exactly why the Challenge Boards divergence (F2) stands out.

## 4. Suggested priority order

1. **F1 / #159** — decide Challenge Boards go-live vs gate-off; don't ship a primary tab of fake data unlabeled. *(product + release risk)*
2. **F3 / F4** — resolve the reminders and entitlement scaffolding (build or delete). *(user-visible dead surface)*
3. **F5** — invite deep links, if Challenge Boards is going live. *(blocks the headline feature)*
4. **P1 / P2** — Android widget + shortcuts parity. *(platform fairness)*
5. **F2** — Challenge Boards conventions/tech-debt pass. *(maintainability)*
6. **#128** — dependency bump after a Flutter SDK upgrade. *(hygiene/security)*
7. **F6 / F7 / #183** — low-priority polish.
