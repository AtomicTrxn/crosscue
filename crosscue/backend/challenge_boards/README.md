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
- weekly and lifetime aggregates based on submitted clean solves.

Out of scope for this slice: native deep links, privacy deletion, production
binary avatar storage, realtime/live-board infrastructure, and paid tiers.

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
`staging` or `production`, the app stays in sample mode until the real Worker
URL is provided.
