# Compatibility Matrix — Versioned Contracts

> **Status:** Living — update whenever any contract version bumps.
> Mixed-version sync policy: [ADR-0016](decisions/0016-mixed-version-sync-policy.md).

Crosscue is no longer a single binary: it is an app, a sync format, a server,
and a widget that evolve at different speeds. This page is the one place that
states every versioned contract, who depends on it, and what must stay
compatible with what.

## The five contracts

| # | Contract | Current version | Written by | Read by | Compatibility rule | Bump procedure |
|---|----------|-----------------|------------|---------|--------------------|----------------|
| 1 | **Local DB schema** (Drift) | **v7** (`app_database.dart` → `schemaVersion`) | The app | The same app | Migrations are additive and run forward-only on upgrade; each historical step has a migration test | Increment `schemaVersion`, add migration + test (checklist in `app_database.dart`) |
| 2 | **Sync blob envelope** | **schema 1** (`SyncBlob.currentSchemaVersion`) | Every synced device | Every synced device | Readers ignore unknown payload fields; blobs with a *newer* schema are skipped (`decode()` → null). Prefer additive payload fields over schema bumps — see ADR-0016 for the mixed-version policy | Bump `currentSchemaVersion` only under ADR-0016's flag-day rules |
| 3 | **Worker D1 schema** | migrations **0001–0006** | Worker deploys | Deployed Worker | Migrations must be backward-compatible with the **currently deployed** Worker (additive), because migrate runs before deploy; never edit an applied migration | New numbered SQL file; `migrate → deploy`, staging before prod (DEPLOYMENT.md) |
| 4 | **Worker HTTP API** | unversioned paths (contract: `API.md`) | Worker | Every shipped app version | Worker changes must stay compatible with the **oldest app version still in the field** — there is currently **no force-upgrade lever** (gap; see below) | Additive request/response changes only; removals require the min-client mechanism first |
| 5 | **Widget payload** | `crosscue_widget_v1`, `"version": 1` | App (`HomeWidgetService`) | iOS widget extension + Android `CrosscueWidgetProvider` (#223) — either may be older than the app, or newer after a partial update | Additive only: new optional keys/rows; never repurpose `version` for additive fields | New key name (`_v2`) only for breaking shape changes |

Related but unversioned: the app↔extension App Group route token
(`pendingIntentRoute`, additive string tokens by design — see
`ios-app-intents.md`) and the export/import backup file from the privacy
screen (treat as contract #1's serialized form; verify import of old exports
when bumping #1).

## Support-window statements

These are the guarantees to preserve when changing anything above:

1. **Old app + new Worker:** must keep working. Deploy order is always
   Worker-before-app-release, and the Worker supports every fielded client
   until a minimum-client mechanism exists.
2. **New app + old data:** a fresh build must open any database produced by
   any released version (forward-only migrations, each step tested).
3. **Two devices, different app versions, same sync account:** both must
   converge or fail *visibly* — never fork silently. Today's behavior and
   the target policy are in ADR-0016.
4. **App + older widget extension** (or vice versa): the widget renders
   whatever optional rows it understands; absent/extra keys are not errors.

## Known gap — no minimum-client lever (planned)

The Worker cannot currently distinguish client versions or retire old ones:
clients send no version identifier and there is no `client_too_old` response.
Plan (design review 2026-06-11 §3.2, small code task):

- Client sends `X-Crosscue-Client: <platform>/<semver>` on every request.
- Worker config gains `MIN_SUPPORTED_CLIENT` (Wrangler var, no schema change)
  and a structured `426 client_too_old` response.
- The app renders that as a friendly "update Crosscue" state on the Challenge
  tab only — everything offline is unaffected (the degradability principle,
  `PRODUCT.md`).

Until this lands, **treat contract #4's "support the oldest fielded client"
rule as absolute.**

## External dependency: Crosshare (single point of failure)

`CrosshareDownloader` is an HTTP + HTML scraper, and three user-visible
features sit on it: the home "Past puzzles" section, daily auto-download, and
**Challenge Boards eligibility** (`crosshare_daily_mini` is the only accepted
result source). A Crosshare markup change degrades all three at once.

**Degradation policy (stale-but-honest):**

- Already-imported puzzles, streaks, stats, and existing board standings are
  local/server data and must remain fully usable during an outage.
- Fetch failures must never crash or block the home screen; the Past-puzzles
  section shows what is already downloaded plus a quiet failure state — never
  fabricated content.
- Challenge result submission already queues offline (`ChallengeResultOutbox`)
  and flushes later; a download outage means *no new eligible puzzle*, which
  boards experience as a quiet day, not an error.

**Risk-reduction tasks (tracked, not yet built):**

1. Scheduled CI canary (weekly cron) running the live fetch/parse against
   crosshare.org, opening an issue on failure.
2. Ask Crosshare about a stable feed/API (license approval already on file —
   `CONVENTIONS.md` source table).
3. Longer term: a Worker-side canonical puzzle-id registry (D4 in
   [`../challenge-boards-159-breakdown.md`](../challenge-boards-159-breakdown.md))
   to decouple board eligibility from client-side scraping success.

## Quick reference — where each version lives

```
crosscue/lib/core/database/app_database.dart   schemaVersion (Drift)
crosscue/lib/core/sync/models/sync_blob.dart   currentSchemaVersion (sync envelope)
crosscue/backend/challenge_boards/migrations/  D1 schema (numbered SQL)
crosscue/backend/challenge_boards/API.md       HTTP contract (prose)
docs/architecture/ios-widget-setup.md          widget payload schema
```
