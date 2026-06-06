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
  "authToken": "..."
}
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

Photo uploads may use:

```json
{ "kind": "photo", "photoPngBase64": "..." }
```

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
