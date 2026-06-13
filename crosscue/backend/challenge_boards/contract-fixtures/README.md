# Challenge Boards contract fixtures (#260)

Canonical request/response pairs for the Challenge Boards HTTP API, lifted from
[`../API.md`](../API.md). **One source of truth, two consumers** — keeping the
Worker and the Dart client honest about the wire shapes:

- **Worker** — `../test/contract.test.mjs` drives the real router through a
  golden flow + reject/error triggers and asserts each captured response
  matches its fixture.
- **Dart client** — `crosscue/test/features/challenge_boards/contract_fixtures_test.dart`
  feeds each fixture response through the real `ChallengeBoardApi` (via a fake
  Dio adapter) and asserts the typed model, and serializes typed inputs back
  into the fixture request shapes.

A field renamed in a fixture (or in either side's code) fails **both** suites.
When the API changes, update `API.md`, the fixture, and re-run `make ci`.

## File shape

```jsonc
{
  "name": "...",                       // human label
  "request":  { "method", "path", "body"? },
  "response": { "status", "body" }
}
```

## Placeholder matchers

Volatile values use string tokens; both consumers match them structurally
rather than by exact value:

| Token | Matches |
|-------|---------|
| `"<string>"` | any string |
| `"<int>"` | any integer |
| `"<iso>"` | any ISO-8601 datetime string |
| `"<url>"` | any string beginning `http` |

Everything else is matched exactly (recursively for objects/arrays).
