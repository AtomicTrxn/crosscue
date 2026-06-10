# Challenge Boards (#159) — implementation breakdown

Breakdown of the remaining work to ship private friend challenge boards (v1) per
[#159](https://github.com/AtomicTrxn/crosscue/issues/159). Much of the design is already
built; this plan covers only the gaps.

## Status snapshot (2026-06-09)

**Built and merged:**

- Cloudflare Worker (`crosscue/backend/challenge_boards/`, ~1,184 lines): bootstrap, get/patch
  player, avatar, list/create boards, board detail, invite preview/join/regenerate, leave,
  result submission. Migrations 0001–0003 (`players`, `boards`, `memberships`, `board_events`,
  `challenge_results`). Weekly + lifetime leaderboards computed **live**, source_id matching,
  invite hashing/expiry/versioning, idempotent results.
- Flutter feature module (`lib/features/challenge_boards/`): full presentation layer, API +
  sample repositories, result outbox, submission mapper, identity store. Wired into the 4-tab
  app shell. Solve completion → challenge submission hook
  (`solve_notifier.dart:421`). Deep-link join routing (#203), no-backend gating (#198),
  iOS associated-domains + Android autoVerify configured.

**Architecture decision (locked):** v1 keeps **live-compute lifetime + bounded retention purge**.
We do NOT build `daily_results` / `player_board_stats` / `processed_lifetime_weeks` / the Monday
rollover cron for v1. The issue's acceptance criteria referencing rollover/`player_board_stats`
are superseded by this decision and should be amended on the issue.

---

## Workstream A — Identity recovery (backend + Flutter)

Survives device restore; an explicit v1 acceptance criterion. Currently bootstrap-only — no
recovery secret exists, so identity is lost on reinstall.

- **A1. Backend `POST /players/restore`** — exchange `playerId + recoverySecret` for a fresh auth
  token. Store only `hash(recoverySecret)`. Structured error for restore-failed.
- **A2. Backend `POST /players/recovery/rotate`** — generate new recovery secret (Web Crypto),
  store new hash, invalidate older bundles, record `recovery_secret_rotated_at`.
- **A3. Migration 0004** — add `recovery_secret_hash`, `recovery_secret_rotated_at` to `players`.
  Confirmed absent from 0001 (current columns: id, display_name, auth_token_hash, avatar_*,
  created_at, last_seen_at, deleted_at).
- **A4. Flutter recovery bundle** — DONE. `challenge_identity_store` now persists `recoverySecret`
  (in the synced `app_settings` table) and exposes `readRecoveryBundle()`; `ChallengeBoardApi`
  captures the secret on bootstrap, adds `restore()` / `rotateRecovery()`, and `_authOptions()`
  restores from the bundle before bootstrapping a new player. `rotateRecovery` is exposed on
  `ChallengeProfileRepository`. Covered by challenge_api_client_test (bootstrap-persists-secret,
  restore-before-bootstrap, rotation-stores-new-secret).
- **A5. Flutter rotate UI** — DONE. A "Reset recovery code" action in the Profile sheet
  (`edit_name_sheet`), shown only when a real backend is configured, behind a
  `showResetRecoveryDialog` confirm; calls `rotateRecovery()`, closes the sheet, and snackbars the
  result. Covered by challenge_sheets_test (action shown/hidden + invokes callback). Optional
  refinement still open: move the bundle from `app_settings` to a dedicated challenge-identity sync
  blob (today it's co-located in the synced settings KV, which already survives same-platform
  restore but co-mingles with settings sync).

## Workstream B — Privacy & deletion (release gate) — DONE

- **B1. Backend `DELETE /players/me`** — DONE (workstream A commit): leaves all boards, deletes
  results, anonymizes + soft-deletes the player, revokes token.
- **B2. Flutter deletion path** — DONE. `ChallengeBoardApi.deleteAccount()` (explicit token, no
  auto-bootstrap, clears local identity via `ChallengeIdentityStore.clear()` +
  `AppSettingsDao.removeValue`). Wired into Privacy → "Clear all data": deletes the server player
  first (while the token still exists), with an offline/error dialog letting the user clear the
  device anyway and retry later. Gated to no-op when the Challenge Boards backend isn't configured.
- **B3. Privacy policy** — DONE. `docs/privacy.md` gains an "Optional Challenge Boards" section
  (server-stored identity/display name/membership/invite metadata/result metadata/lifetime
  stats/recovery-bundle-hash/UTC rules/retention/deletion/backup caveat), qualified summary, and
  an updated retention/deletion section. Effective date bumped to 2026-06-09.
- Tests: api `deleteAccount` (deletes + clears, no-op without identity); privacy_screen
  integration test asserts clear-all also DELETEs the server account and clears local identity.

## Workstream C — Retention purge (replaces full rollover model)

**Scope correction:** under live-compute lifetime, `challenge_results` IS the lifetime source, so
those rows must NOT be purged without a rollover step (which v1 defers). They are compact (one row
per player per daily puzzle), so v1 retains them. Retention applies only to `board_events`, which
feeds no ranking.

- **C1. Scheduled handler + Cron Trigger** — daily UTC purge of `board_events` older than 14 UTC
  days, in bounded chunks. `challenge_results` is intentionally retained under live-compute.
- **C2. wrangler.toml** — add `[triggers] crons` for default/staging/production.
- **C3. Retention index** — index `board_events(created_at)` for the purge query.
- **C4. (Deferred)** challenge_results retention — revisit only if a `player_board_stats` rollover
  is added later, or if per-puzzle result volume is observed to grow unexpectedly.
- Tests: scheduled handler purges only out-of-window events; chunking terminates.

## Workstream D — API hardening

- **D1. Rate limiting** — DONE. Two Cloudflare Rate Limiting bindings: `RL_IDENTITY` (IP-keyed,
  15/60s) on bootstrap/restore, `RL_WRITE` (player-keyed, 60/60s) on join/results/invite-regenerate.
  Bindings are optional in `Env` so local/test runs without them skip limiting; over-limit returns
  `429 rate_limited`. Caps remain transactional.
- **D2. Server-side display-name safety** — DONE. `validateDisplayName` now normalizes
  case/separators/leetspeak and rejects a reserved-handle set + profanity/slur starter blocklist
  (`400 invalid_display_name`). The list lives in `src/index.ts` and is meant to be maintained.
- Tests: reserved/blocked/leetspeak names rejected (clean name passes); fake limiter → 429.
- **D3. (Optional, TODO) `GET /boards/:id/events`** — events are written but not exposed; include
  only if product wants an activity feed in v1.
- **D4. (TODO) Canonical-source policy** — confirm honor-system `source_id` match is acceptable for
  v1 (no `challenge_puzzles` registry / checksum). Document the decision; reject mismatched sources.

## Workstream E — Infra & provisioning (deploy gate)

- **E1. D1 databases** — provision real staging + prod databases; replace placeholder zero-UUID
  `database_id`s in `wrangler.toml`.
- **E2. Custom domain** — route Worker to `api.crosscue.app`; keep invite links on
  `crosscue.app/join/...`.
- **E3. Secrets** — set auth/HMAC secrets via `wrangler secret`; nothing secret in `[vars]`.
- **E4. Observability** — enable Workers Logs + Traces with secret/token/invite-URL redaction;
  request-id correlation (already partly present).
- **E5. Worker-runtime tests** — `@cloudflare/vitest-pool-workers` covering bindings, scheduled
  handler, rate-limit behavior, error paths; confirm compat flags match Wrangler.

## Workstream F — Deep links & QA

- **F1. Host AASA + assetlinks** — serve `apple-app-site-association` and `assetlinks.json` from
  crosscue.app; verify entitlements/autoVerify resolve. `deeplinks/join.html` is the web fallback.
- **F2. QA matrix** (`docs/qa/`) — invite expiry/regeneration/old-link-invalidation, board
  full/limit, idempotent rejoin, leave + final-member auto-delete, same-cloud restore (iOS &
  Android), UTC weekly reset, retention purge, installed/not-installed deep-link cold-start &
  warm-start, source eligibility.

---

## Sequencing

```
E (infra) ─┬─> can deploy backend at all
A (recovery)│
B (privacy) ├─> release gates: must land before store submission
C (retention)
D (hardening) ─> before public beta
F (deeplink/QA) ─> final verification
```

Recommended order: **E1–E3 → A → B → C → D → F**. E unblocks real testing; A and B are the two
acceptance-criteria gaps that block release; C prevents unbounded growth; D/F harden before beta.

## Issue housekeeping

- Amend #159 to mark the rollover/`player_board_stats` acceptance criteria as superseded by the
  live-compute + purge decision.
- #111 and #117 already CLOSED (superseded design alternatives) — no action.
