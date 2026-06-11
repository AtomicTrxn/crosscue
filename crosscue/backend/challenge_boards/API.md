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
under the size cap; other content is rejected with `400 invalid_avatar`.
Binary avatar storage is intentionally provisional in this slice.

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
