# Codebase Review — 2026-06-10

Full review of coding style, architecture, logic, security, cloud usage, and
maintainability. This file tracks each finding to resolution; update the
Status column as items land (reference the PR).

## Overall assessment

Well-disciplined codebase. The clean-architecture rules in ARCHITECTURE.md are
followed in practice (no Drift imports in presentation, `Result<T,E>` at layer
boundaries, interface-typed providers), hand-written code has essentially zero
lint suppressions or TODOs, no secrets are committed, CI mirrors local checks
via `make ci`, and the privacy posture is deliberate (local-only opt-in crash
reporter, minimal `appDataFolder` Drive scope, static no-analytics invite
page). The Worker backend uses parameterized SQL throughout and hashes every
secret at rest.

Risk is concentrated in the newest surface — cloud sync × Challenge Boards
identity — plus a few Worker-side hardening gaps.

## Findings

Severity: H = high, M = medium, L = low/hygiene.

| # | Sev | Finding | Status |
|---|-----|---------|--------|
| 1 | H | Challenge auth token, recovery secret, player id, and result outbox sync to Google Drive / iCloud (`excludedKeys` in `settings_sync_adapter.dart` misses the `challenge_*` keys). Token exposure + LWW merge can clobber a freshly rotated token across devices; synced outbox can double-submit. | **Fixed (this PR)** — excluded from sync + stale remote blobs deleted on pull; regression tests added |
| 2 | H | Worker has zero CI coverage: `ci.yml` runs only Flutter checks; `npm test` / `tsc --noEmit` for `crosscue/backend/challenge_boards` never run on PRs. | **Fixed (#236)** — "Worker checks" CI job (npm test + tsc), `make worker` mirror |
| 3 | H | Avatar photos stored as ≤500 KB base64 data-URLs in D1 with no PNG validation, returned inline in every leaderboard row (one 20-member board detail can approach 10 MB). | **Partially fixed (#237)** — PNG magic-byte validation; R2 move / by-reference avatars in lists still open |
| 4 | M | Challenge secrets live in plain SQLite (Drift `app_settings`) rather than platform secure storage; Android manifest sets no `allowBackup`/`dataExtractionRules`, so OS backups include tokens. | Open — needs `flutter_secure_storage` (new dep) + value migration; deliberate change |
| 5 | M | `previewInvite` returns real board name/member count on the `boardFull`/`playerLimitReached` paths before verifying the invite token — a rotated/expired link still discloses current details. | **Fixed (#237)** — invite secret verified before any board details are returned |
| 6 | M | Join caps are check-then-act, not transactional (comment at `index.ts` rate-limit helper claims "enforced transactionally"); concurrent joins can briefly exceed 20. | **Fixed (#237)** — comment now states the check-then-insert race; overshoot accepted for v1 |
| 7 | M | `requireAuth` writes `last_seen_at` on every authenticated request — one D1 write per API call. | **Fixed (#237)** — last_seen_at refreshed at most hourly |
| 8 | M | Date validation is shape-only: `validateDateOnly` accepts `2026-13-99`; `validateIsoDateTime` accepts far-future `completedAt`. | **Fixed (#237)** — round-trip calendar-date check; completedAt >24h in the future soft-rejected |
| 9 | M | `CHALLENGE_API_ENV=staging|production` silently falls back to sample data unless `CHALLENGE_API_BASE_URL` is also set — a misconfigured release build shows sample boards instead of failing. | **Fixed (#236)** — staging/production without a base URL now throws at startup |
| 10 | M | GitHub Actions pinned to mutable tags (incl. third-party `r0adkll/upload-google-play`, `softprops/action-gh-release` with signing-secret access). | **Fixed (#238)** — all actions pinned to commit SHAs with version comments |
| 11 | M | Settings sync LWW tiebreak compares `remote.deviceId` to the literal string `'local'` (`_shouldTakeRemote`), not the documented `(updatedAt, deviceId)` tiebreak. Deterministic but asymmetric. | Open — fix or re-document |
| 12 | L | `GET /boards/:id/invite` returns a fake URL containing `current-secret-not-readable` alongside `needsRegeneration: true`. | Open — drop the fake link from the contract |
| 13 | L | Domain models import `flutter/foundation` for `@immutable`, breaching the "domain never imports Flutter" rule; `package:meta` provides the same annotation. | Open |
| 14 | L | `listBoards` runs a full leaderboard aggregate per board (N+1, ≤5 today). | Open — revisit at scale |
| 15 | L | `deletePlayer` leaves `actor_player_id` in `board_events` for ≤14 days (retention window). | Open — confirm privacy doc covers it |
| 16 | L | CORS is `*` with `Authorization` allowed — fine for a token-only API; revisit if cookies or a web client appear. | Open — accepted for v1 |
| 17 | L | Test coverage thin on stats (2 files), archive (1), onboarding (1) relative to UI size (largest hand-written files are stats/onboarding screens, ~650 lines each). | Open |
| 18 | L | Worker is one 1,455-line file; route handlers / validation / queries are natural split points before the next feature. | Open |

## Notably good (keep doing)

Hashed-at-rest invite/auth/recovery secrets (256-bit); per-env rate-limit
bindings; daily `board_events` retention cron; structured JSON logs with an
explicit no-secrets policy; `Result` error discipline in parsers; mechanical
architecture enforcement in tests; docs that match the code.
