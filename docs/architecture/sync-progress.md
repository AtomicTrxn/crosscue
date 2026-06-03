# Sync Adapter — Implementation Progress

> Engine + iCloud transport originally tracked under #9 (G5, closed). The
> in-app UI and triggers shipped under
> [#142](https://github.com/AtomicTrxn/crosscue/issues/142) (closed); the
> remaining Android (Google Drive) transport is tracked in
> [#145](https://github.com/AtomicTrxn/crosscue/issues/145).
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
| ✅ | Apple Developer container + Xcode capability | Completed during the v1.2.7 iOS 1.0 release push. App ID has iCloud capability in Xcode 6 / CloudKit-compatible mode; container `iCloud.dev.tomhess.crosscue` exists; provisioning profile carries `icloud-services` + `icloud-container-identifiers` + `ubiquity-container-identifiers` entitlements. See [`sync-icloud-setup.md`](sync-icloud-setup.md). |
| ⏳ | Manual two-device soak | Unblocked (UI shipped). Needs two devices signed in to the same iCloud account with the entitlement-carrying build. |

## Phase 3 — Google Drive transport ([#145](https://github.com/AtomicTrxn/crosscue/issues/145))

| Status | Item | Notes |
|---|---|---|
| ✅ | `GoogleDriveSyncTransport` impl | CRUD over the Drive `appDataFolder`; fails gracefully (no-op) when not signed in / not configured. Wired into `syncTransportProvider` for Android. |
| ✅ | `google_sign_in` + `googleapis` integration | `google_sign_in` v7 + `extension_google_sign_in_as_googleapis_auth` → authorized `DriveApi`. Silent `account()` + interactive `signIn()`. |
| ✅ | Transport tests | Inert-safety (no-op when unconfigured) + `list`/`read` against a mock HTTP `DriveApi`. |
| ✅ | `serverClientId` wiring ([#160](https://github.com/AtomicTrxn/crosscue/issues/160)) | Web client ID threaded via `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID` (required by `google_sign_in` 7.x on Android without `google-services.json`); `release.yml` passes it from a non-secret Actions variable. Empty → inert. |
| ⏳ | Google Cloud project + OAuth clients (manual) | Enable Drive API; consent screen + test users; **two** OAuth clients — Android (package + signing-key SHA-1) and Web (its ID is the `serverClientId`). `drive.appdata` scope. See [`sync-googledrive-setup.md`](sync-googledrive-setup.md). |
| ✅ | Android sync-UI wiring ([#157](https://github.com/AtomicTrxn/crosscue/issues/157)) | `signIn()` is on the `SyncTransport` interface; orchestrator `enable()` calls it (interactive on Drive, ambient on iCloud). `supportsInteractiveSignIn` lets the UI enable even with no silent account. Settings + onboarding copy is platform-generic via `core/sync/sync_service_copy.dart` (iOS "iCloud", Android "Google Drive"). |
| ⏳ | Internal-track soak | Two Android devices, same Google account. Blocked only on the OAuth client above. |

## Phase 4 — Settings UX + triggers ([#142](https://github.com/AtomicTrxn/crosscue/issues/142))

| Status | Item | Notes |
|---|---|---|
| ✅ | `/settings/sync` route + screen | `SyncSettingsScreen` + `SyncController`; enable/disable, live status, "Sync now", "Turn off and remove iCloud copy". Persisted via `AppSettingsRepository.get/setSyncEnabled` + boot re-enable (#150). |
| ✅ | App-resume trigger in `app.dart` | In the existing app-level lifecycle observer; self-guards via the orchestrator (#151). |
| ✅ | Post-solve trigger | Fires once per completion from `SolveScreen` (not the notifier, to keep its unit tests DB-free). `syncNow()` coalesces overlapping passes (#151). |
| ✅ | Onboarding opt-in step | Skippable step; disabled with a sign-in hint when no iCloud account is reachable (#152). |
| ⏳ | "Clear all data" wired to `disable()` | Privacy screen — keep cloud data by default; second confirm for cloud wipe. |
| ⏳ | Default-on flip | Only after both platforms have soaked. |

## Risks / open items

- Settings sync allowlist is not yet decided — placeholder is "all keys" but
  see open question in `sync-design.md`.
- No background sync (WorkManager / BGTaskScheduler) in scope — re-evaluate
  if user feedback shows stale-on-resume to be a frequent complaint.
- Cross-platform migration (iOS↔Android) intentionally not handled — privacy
  export/import bridges it.
