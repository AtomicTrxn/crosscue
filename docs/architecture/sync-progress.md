# Sync Adapter — Implementation Progress

> Tracks [#9 (G5)](https://github.com/AtomicTrxn/crosscue/issues/9).
> Design lives in [`sync-design.md`](sync-design.md). Update the status
> column as each phase merges.

Legend: ✅ done · 🚧 in progress · ⏳ deferred · ❌ blocked

## Phase 1 — Foundation (this branch)

| Status | Item | Notes |
|---|---|---|
| ✅ | Architecture design doc (`sync-design.md`) | |
| ✅ | Progress tracking doc (this file) | |
| ✅ | Schema v5 migration | Additive columns on `puzzles`, `puzzle_completions`, `app_settings`; backfill `clientUuid` on existing completions. |
| ✅ | Sync domain models | `SyncState` (freezed union), `SyncResult`, `SyncAccount`, `SyncBlob` envelope, namespace enum. |
| ✅ | `SyncTransport` interface | Tiny CRUD-on-named-blobs API. Lives in `core/sync/transport/`. |
| ✅ | `NoOpSyncTransport` | Wired as the default transport — local-only build still works. |
| ✅ | `FakeSyncTransport` | In-memory shared map for tests. |
| ✅ | Per-namespace adapters | Puzzles, sessions, completions, settings — each owns serialize/merge. |
| ✅ | `SyncOrchestrator` | Top-level facade. Replaces legacy two-method `SyncAdapter`. |
| ✅ | Provider wiring | `core_providers.dart` exposes orchestrator + transport. |
| ✅ | Schema migration test | Drift v4 → v5 covers new columns + backfill. |
| ✅ | Convergence test | Two `AppDatabase.forTesting` instances + one `FakeSyncTransport` reach a stable state. |
| ✅ | `flutter analyze` clean | |

## Phase 2 — iCloud transport

| Status | Item | Notes |
|---|---|---|
| ✅ | `ICloudSyncTransport` (Dart) | Method-channel client; safely no-ops when handler not registered (Android, tests). |
| ✅ | `ICloudSyncHandler` (Swift) | `NSFileCoordinator` over the ubiquity container's `Documents/sync/` directory. |
| ✅ | Channel registration in `AppDelegate` | Hooked into `didInitializeImplicitFlutterEngine`; safe before any entitlement is configured. |
| ✅ | Conditional provider wiring | `syncTransportProvider` returns `ICloudSyncTransport` on iOS; `NoOpSyncTransport` elsewhere. |
| ✅ | Tests for the Dart side | `MockMethodChannel` covers each method's argument marshaling + error swallowing. |
| ⏳ | Apple Developer container + Xcode capability | One-time, manual; documented in [`sync-icloud-setup.md`](sync-icloud-setup.md). |
| ⏳ | Manual two-device soak | After Step 5 above, on real devices on the same iCloud account. |

## Phase 3 — Google Drive transport (deferred)

| Status | Item | Notes |
|---|---|---|
| ⏳ | Google Cloud project + OAuth client | `drive.appdata` scope. |
| ⏳ | `google_sign_in` + `googleapis` integration | Refresh token via `flutter_secure_storage`. |
| ⏳ | `GoogleDriveSyncTransport` impl | |
| ⏳ | Internal-track soak | Two Android devices, same Google account. |

## Phase 4 — Settings UX + triggers (deferred)

| Status | Item | Notes |
|---|---|---|
| ⏳ | `/settings/sync` route + screen | Mirror `source_management_screen.dart` style. |
| ⏳ | App-resume trigger in `app.dart` | Mirror the Crosshare auto-download pattern. |
| ⏳ | Post-write debounce trigger | 5s debounce after `SolveRepositoryImpl.saveProgress` / `markComplete`. |
| ⏳ | "Clear all data" wired to `disable()` | Privacy screen — keep cloud data by default; second confirm for cloud wipe. |
| ⏳ | Default-on flip | Only after both platforms have soaked. |

## Risks / open items

- Settings sync allowlist is not yet decided — placeholder is "all keys" but
  see open question in `sync-design.md`.
- No background sync (WorkManager / BGTaskScheduler) in scope — re-evaluate
  if user feedback shows stale-on-resume to be a frequent complaint.
- Cross-platform migration (iOS↔Android) intentionally not handled — privacy
  export/import bridges it.
