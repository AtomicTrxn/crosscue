# Crosscue Challenge Boards Worker

Cloudflare Workers + D1 backend foundation for private friend challenge boards.

This slice intentionally implements the membership/invite/profile core plus
the first result-submission path:

- anonymous player bootstrap and token auth;
- display-name updates with the v1 10-character rules;
- board create/list/detail;
- invite preview/join/regeneration;
- leave board and final-member auto-delete;
- 5 active boards per player and 20 active players per board.
- source-level result submission with idempotent upsert;
- honor-system result trust with bounded sanity checks: an elapsed-time floor
  and server-side normalization of clean-ranking eligibility (#228);
- weekly and lifetime aggregates based on submitted clean solves;
- player recovery bundle: bootstrap/restore/rotate of an anonymous identity;
- privacy deletion via `DELETE /players/me`;
- daily scheduled retention purge of `board_events` (14-day UTC window);
- abuse-dampening rate limits on identity creation and board writes;
- server-side display-name safety (reserved names + profanity/slur blocklist);
- atomic D1 batches for every multi-statement board/player transition, with
  fault-injection rollback coverage.

Lifetime stats are computed live from retained `challenge_results` (no
`player_board_stats` rollover in v1), so result rows are intentionally NOT
purged; only the audit-only `board_events` table is on a retention cron.

The rate-limit blocklist for display names is a small starter list in
`src/index.ts` and is meant to be maintained over time.

Avatar photos are stored by reference in an R2 bucket (`AVATARS` binding,
#268) and served from `GET /avatars/<playerId>/<sha256>.png` with a one-year
immutable cache. `wrangler.toml` binds a local simulated bucket plus separate
staging and production buckets. Both remote buckets are provisioned and bound
in the deployed environments (verified 2026-07-27). Tests can still omit the
binding to cover legacy inline `data:` URLs.

Out of scope for this slice: the optional `api.crosscue.app` custom domain,
realtime/live-board infrastructure, an activity feed, and paid tiers. Invite
deep links already ship through `crosscue.pages.dev`.

## Local Setup

1. Replace the placeholder D1 `database_id` values in `wrangler.toml` after
   creating the local/staging/prod databases with Wrangler.
2. Install dependencies from this directory.
3. Run local migrations:

```sh
npm run d1:migrate:local
```

4. Start the Worker:

```sh
npm run dev
```

5. In another terminal, run the local HTTP smoke test:

```sh
npm run smoke:local
```

The smoke test bootstraps two players, creates a board, previews and joins an
invite, submits one clean and one assisted result, and verifies the clean solve
ranks first.

`wrangler dev --local` simulates the configured `crosscue-avatars-local` R2
bucket automatically. Uploading a photo while developing locally therefore
exercises the by-reference path without creating a Cloudflare bucket.

### Flutter API Configuration

Challenge Boards uses sample data unless an API mode is selected with Dart
defines.

Sample/mock mode:

```sh
flutter run
```

Local Worker mode:

```sh
flutter run --dart-define=CHALLENGE_API_ENV=local
```

In local mode the app maps the Worker host automatically:

- Android emulator: `http://10.0.2.2:8787`
- iOS simulator, macOS, and other hosts: `http://127.0.0.1:8787`

An explicit URL always wins, which is useful for physical devices, tunnels,
staging, and production:

```sh
flutter run \
  --dart-define=CHALLENGE_API_ENV=staging \
  --dart-define=CHALLENGE_API_BASE_URL=https://<staging-worker-url>

flutter build ios \
  --dart-define=CHALLENGE_API_ENV=production \
  --dart-define=CHALLENGE_API_BASE_URL=https://<production-worker-url>
```

Supported `CHALLENGE_API_ENV` values are `sample`, `local`, `staging`,
`production`, and `custom`. When `CHALLENGE_API_BASE_URL` is absent for
`staging` or `production`, the app fails fast at startup (it never silently
falls back to sample data; see #236).

### Two-emulator board testing

Both emulators can share one local Worker and one local D1, which makes the
full create → invite → join flow testable on a single machine:

1. Start the Worker (`npm run d1:migrate:local` once, then `npm run dev`).
2. Install the app on both simulators with `CHALLENGE_API_ENV=local`. The
   iOS simulator reaches the Worker via `127.0.0.1`; the Android emulator
   via `10.0.2.2` (cleartext to these loopback hosts is allowed in debug
   builds only, via the debug-source-set network security config).
3. On emulator A: Challenge tab → create a board → copy the invite link.
4. On emulator B: Challenge tab → join a board → paste the link. Emulator
   clipboards sync with the host, so copy/paste crosses emulators.

Both players then submit Daily Mini results against the same board.

## Deploying

Requires `npx wrangler login` against the account that owns the D1 databases.
The `AVATARS` bindings are enabled in source and both current remote buckets
already exist. For a replacement account, provision each exactly once; for the
current account use `r2 bucket info` to confirm it:

```sh
npx wrangler r2 bucket create crosscue-avatars-staging
npx wrangler r2 bucket create crosscue-avatars
```

Then use this staging-first gate. A dry run must list `env.AVATARS`, and the
remote smoke must pass before advancing:

```sh
# Staging
npx wrangler r2 bucket info crosscue-avatars-staging
npx wrangler deploy --dry-run --env staging
npm run d1:migrate:staging
npx wrangler deploy --env staging
CHALLENGE_API_BASE_URL=https://crosscue-challenge-boards-staging.tomhess.workers.dev \
  npm run smoke:avatar:remote

# Production — only after staging is green
npx wrangler r2 bucket info crosscue-avatars
npx wrangler deploy --dry-run --env production
npm run d1:migrate:prod
npx wrangler deploy --env production
CHALLENGE_API_BASE_URL=https://crosscue-challenge-boards.tomhess.workers.dev \
  npm run smoke:avatar:remote
```

The avatar smoke creates one temporary player, uploads a 1×1 PNG, verifies the
returned HTTPS URL and downloaded image bytes, then deletes the player and
confirms the avatar URL is gone. Cleanup runs in `finally`, and the auth token
is never printed.

**Last live verification (2026-07-27):** migration `0007_ops_meta.sql`, both
environment deploys, and both remote avatar smokes passed. The staging and
production buckets reported zero objects after smoke cleanup.

R2 has no hard spend-cap switch in the Cloudflare dashboard. An account-wide
`R2 overage warning` budget alert is configured at `$1 USD`; it is
informational and does not pause service. Billing procedure and rollback impact
are documented in the repo-level deployment guide.

Deployed URLs, environment table, migration rules, rollback, and log tailing
live in the repo-level [DEPLOYMENT.md](../../../DEPLOYMENT.md) ("Backend:
Challenge Boards Worker"). Shipped apps reach production via the
`CHALLENGE_API_BASE_URL` Actions variable wired into release builds.
