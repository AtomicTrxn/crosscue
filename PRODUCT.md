# Crosscue — Product Vision & Principles

> **Status:** Living — the "why" companion to `ARCHITECTURE.md`'s "how".
> Update when product direction changes; decisions that change a rule here
> get an ADR in [`docs/architecture/decisions/`](docs/architecture/decisions/README.md).

## Vision

A crossword solver with NYT-grade mechanics and none of the strings: no
subscription, no account, no ads, no analytics. **Your puzzles. Your device.
No strings attached.**

**Target user:** the serious-casual solver — someone who solves daily (often
the mini), cares about streaks and times, may own a Bluetooth keyboard, and
actively prefers software that doesn't watch them. Not targeting constructors,
tournament solvers, or children.

## Product principles

These are testable rules, not aspirations. A feature that violates one needs
an ADR explaining why, before it ships.

1. **Offline-first.** Every core flow — import, solve, archive, stats — works
   with the network off, forever. Network use happens only on an explicit user
   action (downloading a puzzle, joining a board) or an opt-in the user made.

2. **The online-feature rule.** Every online feature must be:
   - **(a) opt-in** — off until the user takes a deliberate action;
   - **(b) anonymous or pseudonymous** — no name, email, or account;
   - **(c) deletable in-app** — including server-side data, from Settings;
   - **(d) degradable** — the rest of the app is fully functional with it
     off, unreachable, or down.

   Sync (user's own iCloud/Drive) and Challenge Boards (anonymous handle,
   in-app deletion, sample-mode fallback) both pass. The next online idea
   gets tested against these four letters before any design work.

3. **No surveillance, ever.** No ads, no analytics SDKs, no third-party
   trackers, no remote crash reporting without an explicit future opt-in
   design. This is identity, not a phase.

4. **Respect the puzzle.** Source content only with a verified license
   (the legal guardrail in `CONVENTIONS.md` is binding), attribute authors,
   and follow solver conventions (rebus behavior, no spoiling theme squares).

5. **Quality over breadth, on every target.** Mechanics match or beat the
   big apps (focus model, rebus, check/reveal semantics, accessibility), and
   a user-visible feature ships only when it works on **all app targets** —
   currently iOS and Android. Platform parity is required, not aspirational
   ([ADR-0015](docs/architecture/decisions/0015-platform-parity-policy.md)).

## Roadmap themes

Issues should serve a theme; themes are priorities, not dates.

| Theme | What it covers | Representative work |
|---|---|---|
| **Solver depth** | Mechanics that reward daily use: pencil mode, better clue navigation, puzzle-format coverage (`.jpz` decision pending) | `EntryMode.pencil` reserved enum |
| **Social** | Challenge Boards productionization and follow-ons (activity feed, more sources) | #159 workstreams, deep links |
| **Platform parity** | Android widget + App Shortcuts; keeping the two stores equivalent | P1/P2 from the 2026-06-07 analysis |
| **Content sources** | New legally-cleared puzzle feeds; resilience of existing ones | Crosshare canary, source registry |
| **Retention / habit** | Streak mechanics; local-only reminders if revisited ([ADR-0014](docs/architecture/decisions/0014-reminders-deferred.md)) | — |
| **Trust & operations** | Privacy posture, server hardening, backup/restore, compatibility guarantees | `docs/architecture/compatibility.md`, threat model |

## Non-goals

Stated once so they don't get re-litigated per feature:

- **No accounts, no public/global leaderboards.** Social stays private and
  invite-only.
- **No ads, subscriptions, or paid tiers.** Monetization was considered and
  declined ([ADR-0013](docs/architecture/decisions/0013-no-monetization.md));
  the entitlement scaffolding was removed in #211. Revisiting requires a new
  ADR and may only consider a one-time supporter unlock — never ads,
  analytics, or feature-gating of solving.
- **No real-time multiplayer / co-solving.**
- **No cross-platform cloud migration service.** iOS↔Android moves use the
  privacy-screen export/import; the recovery bundle is same-cloud by design.
- **No scraping unlicensed sources** — regardless of technical ease.

## How product feedback works (without analytics)

There is deliberately no telemetry, so feedback is gathered where users
already are, and the loop is a routine, not a dashboard:

- **Inbound channels:** GitHub Issues (public), TestFlight feedback, Play
  Console reviews/ratings, App Store reviews, and direct email
  (`atomhess@gmail.com`).
- **Routine:** triage store reviews + TestFlight feedback when cutting each
  release; convert actionable items to issues tagged by roadmap theme.
- **In-app signals stay local:** stats the app shows the user (streaks,
  solve counts) are theirs alone; sharing them is always a user action
  (the share sheet), never an upload.
- **Feature success** is judged by qualitative feedback and store metrics
  (ratings, update adoption), accepted as a deliberate trade for privacy.
