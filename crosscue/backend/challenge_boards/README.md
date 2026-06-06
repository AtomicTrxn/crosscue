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

Point Flutter at the local Worker with:

```sh
flutter run --dart-define=CHALLENGE_API_BASE_URL=http://127.0.0.1:8787
```

When the Dart define is absent, the app keeps using the sample repository.
