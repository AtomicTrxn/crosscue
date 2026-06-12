# Threat Model — Crosscue

> **Status:** Living — update when a trust boundary, secret, or accepted risk
> changes. Disclosure process: [`SECURITY.md`](../../SECURITY.md).
> Companion: [`compatibility.md`](compatibility.md) (contracts),
> [`docs/privacy.md`](../privacy.md) (user-facing commitments).

This page states what the system defends against and — just as important —
what it deliberately accepts. A security finding that lands in the "accepted"
table is a known trade-off, not a gap.

## Assets

| Asset | Where it lives | Sensitivity |
|---|---|---|
| Puzzle library, solve progress, stats | Device SQLite (Drift) | User-private; no server copy |
| Sync blobs (library/sessions/completions/settings) | User's own iCloud container / Drive AppData | User-private; provider-managed |
| Challenge **auth token** | Platform secure storage (Keychain/Keystore via `SecureKeyValueStore`) | Bearer credential — device-local by design, excluded from sync and OS backup |
| Challenge **recovery bundle** (player id + recovery secret) | App DB (`app_settings`), synced to the user's own cloud | Credential-equivalent; deliberately survives backup/restore (see privacy.md) |
| Server data (players, boards, results, events) | Cloudflare D1 | Pseudonymous; secrets stored only as SHA-256 hashes |
| Invite links | User-shared URLs | Capability tokens — possession grants join |
| Signing/release secrets (keystore, Apple certs, ASC API key, Play service account) | GitHub Actions Secrets | Highest impact — supply-chain |

## Trust boundaries

1. **Device ↔ user's cloud** (iCloud Documents / Drive AppData). The cloud
   account *is* the boundary: anyone controlling the account can read or
   tamper with sync blobs and the recovery bundle. Blobs are not
   end-to-end encrypted beyond provider encryption — accepted (below).
2. **Device ↔ Challenge Worker.** HTTPS; bearer-token auth; no cookies.
   The server never sees puzzle contents — only result metadata
   (see `API.md` / privacy.md).
3. **Device ↔ Crosshare** (puzzle downloads). Read-only HTTPS fetches of
   licensed content; no credentials involved.
4. **CI ↔ stores.** Dispatch-only release workflow against an explicit tag;
   actions pinned to commit SHAs (#238); store uploads opt-in per dispatch.

## Defended threats

| Threat | Defense |
|---|---|
| Server database theft exposing credentials | Auth tokens, recovery secrets, and invite secrets stored only as SHA-256 hashes; no Worker-side secrets exist at all (`wrangler.toml` carries only public vars) |
| Token theft from a device backup | Auth token lives in Keychain/Keystore; Android backup rules exclude the secure-prefs file (#240) |
| Token clobbering / double-submit via settings sync | `challenge_*` auth token and result outbox excluded from sync (#235/#239) |
| Invite brute force / link replay | 256-bit hashed invite secrets, expiry + versioning (regeneration invalidates old links), preview discloses nothing until the secret verifies (#237), write rate limits |
| Mass anonymous identity creation | IP-keyed rate limit on bootstrap/restore (`RL_IDENTITY`) |
| Board-write abuse | Player-keyed rate limit (`RL_WRITE`); board caps (5 boards/player, 20 players/board) |
| Fabricated solve times (gross) | Elapsed-time floor, future-timestamp rejection, server-side normalization of clean-eligibility (#228/#237) |
| SQL injection | Parameterized SQL throughout the Worker (verified 2026-06-10 review) |
| Offensive/impersonating handles | Server-side display-name validation: reserved handles + blocklist + normalization (D2) |
| Secret leakage via logs | Structured JSON logs with an explicit no-secrets/no-invite-URL convention |
| Supply-chain via mutable action tags | All GitHub Actions pinned to commit SHAs (#238) |
| Malicious puzzle files | 5 MB parser cap, typed `Result` error paths, checksum dedupe; parsers never execute content |

## Accepted risks (deliberate)

| Accepted risk | Rationale | Revisit when |
|---|---|---|
| **Honor-system results** — clients self-report times; a motivated user can submit fake (plausible) times | Boards are private, invite-only groups of friends; only bounded sanity checks are worth their complexity in v1 | Boards grow beyond friend groups, or a puzzle-registry/canonical-source check lands (D4 in the #159 breakdown) |
| **Invite links are capability URLs** — anyone holding a valid link can join | Matches the product model ("share a link with friends"); regeneration + expiry bound the exposure | — |
| **Long-lived bearer tokens** with no scheduled rotation | Anonymous identity; rotation exists via restore (old token invalidated); compromise blast radius is one pseudonymous player | Tokens ever gate anything beyond leaderboards |
| **Recovery bundle in the synced DB** rather than secure storage | Must survive OS backup + device restore to keep identity durable; documented in privacy.md; server stores only its hash | — |
| **No E2E encryption of sync blobs** | The user's own cloud account is the stated trust boundary; provider-at-rest encryption applies | Product identity changes (it shouldn't) |
| **CORS `*` with `Authorization` allowed** | Token-only API, no cookies — browser same-origin protections aren't load-bearing | A web client or cookies appear (finding 16, 2026-06-10) |
| **Join caps are check-then-insert** — concurrent joins can briefly exceed 20 | Overshoot is cosmetic at this scale (#237) | Caps become contractual |
| **No client attestation / anti-tamper** | Pointless against a determined user of an open-source app; the data at stake is friend-group times | — |

## Known gaps (not accepted — tracked)

- **No minimum-client / force-upgrade lever** on the Worker API — see
  [`compatibility.md`](compatibility.md) and design-review §3.2. Until it
  exists, abusive or broken old clients can't be retired.
- **Avatar storage** is provisional: base64 PNGs in D1, returned inline
  (partially fixed #237; R2 / by-reference delivery still open).
- **Alerting is pull-based** (`wrangler tail`) — see DEPLOYMENT.md
  "Monitoring & alerting" for the planned push signals.

## Out of scope

Compromised devices, compromised Apple/Google accounts, malicious OS
keyboards, and attacks on Cloudflare/Apple/Google infrastructure itself.
