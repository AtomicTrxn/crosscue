# Sync Adapter Design (G5 — iCloud / Google Drive)

> **Status:** Living — the as-built sync reference. Decision record:
> [ADR-0009](decisions/0009-sync-architecture-and-rollout.md); cross-version
> rules: [`compatibility.md`](compatibility.md) +
> [ADR-0016](decisions/0016-mixed-version-sync-policy.md).
> Tracks [#9 (G5)](https://github.com/AtomicTrxn/crosscue/issues/9).
> Companion doc to `ARCHITECTURE.md`. Sync ships **opt-in (off by default)**;
> users enable it from the onboarding sync step or Settings — there is no
> default-on flip (see "Migration / rollout"). The one-time platform setup
> (iCloud entitlement / Google Cloud OAuth) and two-device soak live in
> [`sync-icloud-setup.md`](sync-icloud-setup.md) and
> [`sync-googledrive-setup.md`](sync-googledrive-setup.md).

## Goals / non-goals

**In scope.** Cross-device sync of (a) the puzzle library — every imported
or downloaded puzzle, (b) the per-puzzle solve session (in-progress + latest),
(c) the immutable `puzzle_completions` history that drives streaks/PBs, and
(d) a small allowlist of user-facing settings users expect to follow them
across devices (theme, haptics, sounds, colorblind, Crosshare auto-download
config).

**Out of scope.** Real-time multiplayer / co-solve. Server-mediated
leaderboards. Cross-account sharing. Migrating data *between* iCloud and
Google Drive when a user changes platforms — the existing privacy-screen
export/import is the supported bridge.

## High-level shape

Three layers, replacing today's two-method `SyncAdapter` interface with an
orchestration model:

```
SyncOrchestrator               ← top-level: schedules pushes/pulls, exposes status
  ├── NamespaceSyncAdapter     ← per-namespace logic (puzzles, sessions, completions, settings)
  │     uses
  └── SyncTransport            ← platform-specific blob store (iCloud / Drive / Fake)
```

- `SyncTransport` is the *only* platform-aware piece. It exposes a tiny
  CRUD-on-named-blobs API: `read(key)`, `write(key, bytes, ifMatch)`,
  `list(prefix)`, `delete(key)`, plus account management:
  `account()` (silent), `signIn()` (interactive where the platform needs it),
  and the `supportsInteractiveSignIn` capability flag. (As built there is no
  `changes()` stream — sync is driven by the app-resume / post-write triggers
  below, not a push channel.) The iCloud impl uses the app's iCloud Documents
  container for blobs; the Google Drive impl uses the AppData scope (hidden,
  per-app, no user file picker needed).
- `NamespaceSyncAdapter` per namespace owns the entity shape, conflict rule,
  and merge function. Keeps platform concerns out of domain code.
- `SyncOrchestrator` is what `core_providers` exposes (replacing today's
  `syncAdapterProvider`). It owns the foreground-resume trigger and a
  debounced "after local write" trigger.

Transport is picked via `Platform.isIOS ? ICloudTransport : GoogleDriveTransport`,
with `FakeSyncTransport` for tests. `NoOpSyncTransport` keeps the local-only
build viable until platform adapters land.

## Data model

Sync state already exists on `solve_sessions` (`isSynced`, `syncVersion`,
`createdAt`, `updatedAt`). Extend the same triple to the other synced tables
in **schema v5**:

| Table | New columns | Why |
|---|---|---|
| `puzzles` | `syncVersion`, `isSynced` (already has `createdAt`/`updatedAt`) | Library replication |
| `puzzle_completions` | `clientUuid` (UUID v4), `deviceId` | Append-only — dedupe on `clientUuid`; `deviceId` for provenance |
| `app_settings` | `syncVersion` | LWW per key (already has `updatedAt`) |
| `cell_progress` | (none) | Travels inside the session blob, not synced independently |

`clientUuid` on completions is the key insight: it's append-only history, so
each device generates a UUID at insert time, and merge becomes a set union
with `clientUuid` as the dedupe key — no conflict logic needed.

## Wire format

One blob per entity, in an app-private folder (`Documents/sync/` on iCloud,
AppData root on Drive). Keys:

```
puzzles/<puzzleId>.json
sessions/<puzzleId>.json          # latest session + its cell_progress, denormalized
completions/<clientUuid>.json     # immutable
settings/<key>.json
manifest.json                     # index: {namespace → [{key, syncVersion, updatedAt, etag}]}
```

`manifest.json` is the only thing read on every sync tick. Entity blobs are
fetched only when the manifest says the remote version is newer. Keeps a
typical incremental sync to one small GET.

Each blob is `{schemaVersion, deviceId, syncVersion, updatedAt, payload}`.
`schemaVersion` lets us evolve formats; readers ignore unknown fields and
skip blobs with newer schemas than they understand (forward-compat).

## Conflict resolution

Per namespace, picked for what the data actually means:

- **Puzzles** — content-addressable (id = `local:<sha256-prefix>`, checksum
  stored separately). Identical content → no conflict. Different content
  under the same id is impossible by construction. Merge = union.
- **Completions** — immutable, append-only. Merge = set union keyed by
  `clientUuid`. No conflicts possible.
- **Sessions** — one mutable row per puzzle. Last-writer-wins by
  `(updatedAt, deviceId)`, with a "best-progress" override: if remote is
  `completed` and local is `in_progress`, keep remote regardless of clock.
  Avoids the case where a stale clock erases a real completion.
- **Settings** — LWW per key by `updatedAt`. Keys are independent.

`deviceId` is the tiebreaker on equal `updatedAt`, so two devices can't
deadlock if clocks match. `syncVersion` is incremented locally on every
write; remote `syncVersion ≤ local` means "we already have this or newer,
skip download."

## API surface

```dart
abstract class SyncOrchestrator {
  Stream<SyncState> get state;          // disabled | signedOut | idle | syncing | error
  Future<SyncAccount?> currentAccount();
  Future<void> enable();                // iOS: check iCloud token; Android: sign in
  Future<void> disable({bool wipeRemote = false});
  Future<SyncResult> syncNow();         // manual trigger from settings
  DateTime? get lastSyncedAt;
}
```

`SyncState` is a hand-written sealed class (`SyncDisabled` / `SyncSignedOut` /
`SyncIdle` / `SyncRunning` / `SyncError`) — exhaustively switchable like a
Freezed union, but plain Dart. `SyncResult` reports `{pushed, pulled,
conflicts, duration}` for the settings UI to render.

The legacy two-method `SyncAdapter` (just `sync()` + `isSyncEnabled`) is
removed once `SyncOrchestrator` is wired — no compatibility shim, since the
only caller is the provider.

## Trigger model

Mirror the Crosshare auto-download pattern in `app.dart` — a
`WidgetsBindingObserver` calling `ref.read(syncOrchestratorProvider).syncNow()`
on `resumed`. Add a debounced (5s) trigger from `SolveRepositoryImpl.saveProgress`
/ `markComplete` so an active solver gets near-realtime cross-device updates
without hammering the transport on every keystroke.

No background fetch / WorkManager in v1. App-resume + post-write is
sufficient for the daily-mini use case and avoids the platform background-
execution rabbit hole.

## Platform specifics

- **iCloud (iOS).** Use the iCloud Documents container (entitlement
  `com.apple.developer.icloud-container-identifiers`). Account is implicit;
  `FileManager.url(forUbiquityContainerIdentifier:)` returns `nil` if the
  user has iCloud Drive off for the app — that's the `signedOut` state. No
  `google_sign_in` equivalent dialog needed.
- **Google Drive (Android).** `google_sign_in` 7.x +
  `extension_google_sign_in_as_googleapis_auth` + `drive.appdata` scope.
  AppData folder is hidden from the user's Drive UI and per-app — exactly
  the trust model we want. Sign-in is explicit on first enable (the toggle
  drives the prompt); `google_sign_in` owns token storage/refresh internally
  (no separate `flutter_secure_storage`). Needs an Android OAuth client plus
  a web client whose ID is passed as `serverClientId` — see
  [`sync-googledrive-setup.md`](sync-googledrive-setup.md).
- **Authentication failures.** Surface as `SyncState.signedOut` (user needs
  to act) vs. `SyncState.error(transient)` (orchestrator retries on next
  trigger). Never block UI.

## Settings UX

New `/settings/sync` route under the existing settings shell, alongside
`/settings/sources` and `/settings/privacy`:

- Master toggle (off → on triggers `enable()`).
- Account row: shows iCloud account / Google account email (with sign-out
  for Drive).
- "Last synced … · X puzzles · Y completions" status line.
- "Sync now" button (manual trigger).
- "Delete cloud data" (destructive, confirms; calls `disable(wipeRemote: true)`).

Use the existing `SettingsSwitchRow` / `SettingsNavRow` widgets so it
matches the rest of settings visually.

## Privacy / data model fit

- Sync is **off by default**. v1 ships disabled — opt-in flow from settings.
- "Clear all data" in the privacy screen must also call
  `disable(wipeRemote: false)` so a wipe doesn't unexpectedly delete the
  user's other device's data. Add a second confirm step for the "also delete
  cloud copy" path.
- Crash reporter logs and the local raw payloads (where retained per source
  policy) never sync — they're device-local diagnostics.

## Test strategy

- `FakeSyncTransport` (in-memory map) lets every adapter test run hermetically
  with no platform code.
- Property tests for merge functions: idempotence (sync twice = sync once),
  commutativity (A→B + B→A converges).
- Integration test: spin two `AppDatabase.forTesting` instances sharing one
  `FakeSyncTransport`, drive a solve on one, sync, assert the other sees
  the completion.
- Drift schema-version test follows the existing v3→v4 pattern in
  `app_database_test.dart`.

## Migration / rollout

1. Schema v5 (additive columns + `clientUuid` backfill for existing
   completions). ✅
2. Land `SyncTransport` + `FakeSyncTransport` + `SyncOrchestrator` with
   `NoOpSyncTransport` still wired — no behavior change. ✅
3. iCloud transport behind an off-by-default settings entry on iOS. ✅ (#142)
4. Google Drive transport on Android. ✅ (#145 transport, #157 sign-in UI;
   inert until the OAuth clients exist).
5. **Ship opt-in (off by default) — no default-on flip.** ✅ (decided)
   Sync stays disabled until the user turns it on from the onboarding sync
   step (#142) or Settings; `getSyncEnabled()` defaults to `false`. The
   onboarding enablement screen makes an automatic default-on flip
   unnecessary, so it has been dropped from the plan.

All steps have landed. Remaining work is **operational, not code**: the
one-time iCloud-entitlement / Google-Drive-OAuth platform setup and the
two-device soaks, both documented in the setup guides above. Background
sync and a server-side bridge remain out of scope (see "Open questions").

## Open questions

- **Settings sync granularity** — sync all settings, or only the
  "preference" subset and leave device-local things (e.g., haptics, which
  the user may want different per device) local? Lean toward a per-key
  allowlist.
- **Quota.** AppData has a per-user 1 GB cap with current Drive policy;
  iCloud uses the user's account quota. A 15×15 puzzle blob is ~5 KB,
  completions are <1 KB. 1000 puzzles ≈ 5 MB — fine. Worth a guard against
  pathological growth (the manifest could cap visible history at, say, 5
  years of completions and let older rows live only locally).
- **Cross-platform migration.** A user switching iOS→Android can't read
  their iCloud data from Drive. The existing privacy-screen export/import
  is the bridge — explicitly document it on the sync settings page rather
  than building a server.
