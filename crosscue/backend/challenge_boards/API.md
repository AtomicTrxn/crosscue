# Challenge Boards API Contract

All responses are JSON. Authenticated requests use:

```http
Authorization: Bearer <playerAuthToken>
```

Errors:

```json
{
  "error": {
    "code": "board_full",
    "message": "This board is full.",
    "requestId": "..."
  }
}
```

Identity creation (`/players/bootstrap`, `/players/restore`) and board writes
(`/invites/join`, `/results`, invite regeneration) are rate-limited. Over the
limit returns `429` with code `rate_limited`. Display names are validated
server-side for length (10), allowed characters, reserved handles, and a
profanity/slur blocklist; rejections return `400 invalid_display_name`.

## Client identity & minimum version (#256)

Clients send their identity on **every** request (shipped since app v1.4.3):

```http
X-Crosscue-Client: <platform>/<semver>     # e.g. ios/1.4.3, android/1.4.3
```

When the Worker's optional `MIN_SUPPORTED_CLIENT` var (`wrangler.toml`,
format `X.Y.Z`) is set, any request whose header semver is missing,
unparsable, or lower than the minimum is rejected — on every route,
including identity creation — with:

```http
426 Upgrade Required
```

```json
{ "error": { "code": "client_too_old", "message": "…", "requestId": "…" } }
```

The app renders this as a persistent "Update Crosscue" state on the
Challenge tab (everything offline is unaffected), and the result outbox
holds entries rather than dropping them. Unset (the default in every
environment) means no enforcement. Setting the var also cuts off app
versions that predate the header (< v1.4.3) — that is the intended
force-upgrade/kill-switch lever; enable deliberately, staging first.

## Player

`POST /players/bootstrap`

Request:

```json
{ "displayName": "Maya" }
```

Response:

```json
{
  "player": {
    "id": "...",
    "displayName": "Maya",
    "isMe": true,
    "avatar": { "kind": "initials", "silhouetteLook": 1, "photoUrl": null }
  },
  "authToken": "...",
  "recoverySecret": "..."
}
```

`recoverySecret` is returned only at bootstrap and on rotation. The server stores
only `hash(recoverySecret)`. The client persists `{ playerId, recoverySecret }` in
its private app-storage recovery bundle to restore identity after device restore.

`POST /players/restore`

Unauthenticated. Exchanges a recovery bundle for a fresh auth token (the previous
token is invalidated).

Request:

```json
{ "playerId": "...", "recoverySecret": "..." }
```

Response:

```json
{ "player": { "...": "player" }, "authToken": "..." }
```

Returns `401 restore_failed` if the player is unknown, deleted, or the secret
does not match.

`POST /players/recovery/rotate`

Authenticated. Issues a new recovery secret and invalidates older recovery
bundles.

Response:

```json
{ "recoverySecret": "...", "rotatedAt": "2026-06-09T00:00:00.000Z" }
```

`DELETE /players/me`

Authenticated. Leaves all active boards (auto-deleting any board left with no
members), deletes the player's challenge results, anonymizes residual membership
rows, and soft-deletes the player record. The auth token and recovery secret are
revoked.

Response:

```json
{ "ok": true }
```

`GET /players/me`

Response:

```json
{ "player": { "...": "same shape as above" } }
```

`PATCH /players/me`

Request:

```json
{ "displayName": "Maya" }
```

`POST /players/me/avatar`

Request:

```json
{ "kind": "silhouette", "silhouetteLook": 2 }
```

`silhouetteLook` selects one of the ten preset looks and is clamped
server-side to 1..10 (look meanings are append-only; see the client's
`kPresetAvatars`).

Photo uploads may use:

```json
{ "kind": "photo", "photoPngBase64": "..." }
```

`photoPngBase64` must decode to PNG bytes (magic-byte checked) and stay
under the size cap; other content is rejected with `400 invalid_avatar`
(or `413 avatar_too_large`).

The returned `avatar.photoUrl` is one of two schemes, and clients must
render both:

- an inline `data:image/png;base64,…` URL (legacy/no-bucket storage), or
- an `https:` URL served by this Worker (when the `AVATARS` R2 bucket is
  bound, #268) — immutable and content-addressed, see below.

`GET /avatars/<playerId>/<sha256>.png`

Public and unauthenticated — plain image bytes, fetched by an image loader
with no bearer token or client-version header (exempt from the min-client
gate). Served from R2 with `Cache-Control: public, max-age=31536000,
immutable` (the key is a content hash, so the bytes never change). Returns
`404` when the bucket is unbound or the object is missing. Uploading a new
photo writes a fresh key and deletes the prior object; deleting the player
removes all of theirs.

## Boards

`GET /boards`

Response:

```json
{
  "boards": [
    {
      "id": "...",
      "name": "Friday Crew",
      "playerCount": 8,
      "rankingMode": "average_time",
      "ownerPlayerId": "...",
      "myWeekly": {
        "rank": 1,
        "outOf": 8,
        "cleanSolves": 0,
        "avgClean": "—",
        "bestClean": "—",
        "totalClean": "—"
      }
    }
  ],
  "lifetime": {
    "avgClean": "—",
    "cleanSolves": 0,
    "bestClean": "—",
    "rankingStatus": "Solve 5 clean puzzles to unlock lifetime ranking",
    "weeksCounted": 0
  }
}
```

`POST /boards`

Request:

```json
{ "name": "Friday Crew", "rankingMode": "average_time" }
```

`rankingMode` is optional and defaults to `average_time`. Supported values:
`fastest_time`, `average_time`, and `total_time`.

Response:

```json
{ "board": { "...": "board summary" }, "inviteLink": "https://..." }
```

`GET /boards/:id`

Response:

```json
{
  "board": { "...": "board summary" },
  "weekly": [
    {
      "rank": 1,
      "player": { "...": "player" },
      "cleanSolves": 0,
      "avgClean": "—",
      "bestClean": "—",
      "totalClean": "—",
      "weeksCounted": 0
    }
  ],
  "lifetime": []
}
```

Weekly rankings use Daily Mini publish dates from Monday 00:00 UTC through the
next Monday 00:00 UTC. Finishing an older Daily Mini during the current week
does not count toward the current weekly board.

Players with at least one clean Daily Mini rank above assisted-only or
unsubmitted players. Within clean entries, boards sort by their configured
time mode: lowest best clean time, lowest average clean time, or lowest total
clean time. Clean solve count and assisted count are deterministic tie-breakers.

`POST /boards/:id/leave`

Response:

```json
{ "ok": true, "boardDeleted": false }
```

When the departing player owns the board and members remain, ownership
passes to the earliest-joined active member (ties broken by player id);
an `owner_changed` event is recorded. Rejoining resets a player's join
order, so a returning ex-owner queues at the back of the succession line.
The same succession runs when an owner deletes their account.

`DELETE /boards/:id/members/:playerId`

Owner-only: removes an active member from the board. The target's results
rows are retained but stop counting for this board (same as leaving); their
membership is closed with state `removed`.

Response:

```json
{ "ok": true }
```

Errors: `403 not_owner` (requester does not own the board),
`400 cannot_remove_self` (owners leave instead), `404 member_not_found`
(target is not an active member). A removed player can rejoin with a
still-valid invite link — regenerate the invite to lock them out.

`POST /boards/:id/invite/regenerate`

Response:

```json
{ "inviteLink": "https://...", "expiresAt": "2026-07-06T00:00:00.000Z" }
```

## Invites

`POST /invites/preview`

Request:

```json
{ "inviteLink": "https://crosscue.app/join/<boardId>?token=<secret>" }
```

Response result values:

- `valid`
- `boardFull`
- `alreadyMember`
- `playerLimitReached`
- `invalidOrExpired`
- `boardDeleted`

The invite secret is verified before any board details are disclosed: a
rotated or otherwise invalid link previews as `invalidOrExpired` with an
empty `boardName` and zero counts. Expired-but-genuine links still show the
board name.

`POST /invites/join`

Request:

```json
{ "inviteLink": "https://crosscue.app/join/<boardId>?token=<secret>" }
```

Response:

```json
{ "board": { "...": "board summary" } }
```

## Results

`POST /results`

Submits one canonical result for the authenticated player and source puzzle.
The server upserts by `(player, sourceId, sourcePuzzleId)`, so retries are safe.
Results are counted for every active board the player belongs to with the same
`sourceId`.

Request:

```json
{
  "sourceId": "crosshare_daily_mini",
  "sourcePuzzleId": "2026-06-05",
  "puzzleTitle": "Daily Mini",
  "publishedOn": "2026-06-05",
  "completedAt": "2026-06-05T12:34:56.000Z",
  "elapsedMs": 91000,
  "completionType": "clean",
  "cleanSolveEligible": true
}
```

Only `sourceId: "crosshare_daily_mini"` with a `publishedOn` Daily Mini date is
accepted for Challenge Boards. Other puzzle sources are ignored and do not count
toward weekly or lifetime challenge standings.

Submissions are honor-system in v1 (#159/#228), with two server-side sanity
checks:

- `elapsedMs` below 3000 (3 seconds) is rejected with reason
  `implausible_elapsed_ms`.
- `cleanSolveEligible` is stored as `false` unless `completionType` is
  `clean`, so assisted or revealed solves can never enter the clean ranking
  regardless of what the client sends.

`completionType` values:

- `clean`
- `checked`
- `hinted`
- `revealed`
- `unsolved`

Response:

```json
{ "accepted": true }
```

If the player has no active board for the submitted source, the response is:

```json
{ "accepted": false, "reason": "no_active_source_board" }
```

Other soft-reject reasons (also HTTP 202): `not_challenge_daily_mini` for
ineligible sources, `implausible_elapsed_ms` for times under the floor, and
`implausible_completed_at` for completion timestamps more than a day in the
future. `publishedOn` must be a real calendar date.
