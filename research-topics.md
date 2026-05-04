# Crossword App — Research Topics

This tracker captures the remaining research needed before and during implementation.

## Research Workflow

1. Pick one topic from the tracker and update its row before starting:
   - `Status`: `In Progress`
   - `Owner`: `Claude`, `Codex`, or `Tars`
   - `Output File`: create or confirm the matching `research/topic-XX-slug.md` file
2. Generate or update that topic's research output file. Each topic gets its own file; keep this tracker as an index, not the research body.
3. When research is finished, update the topic row:
   - Move it to the `Resolved` section
   - Set `Status` to `Resolved`
   - Keep the final owner name
   - Replace `Research Needed` with `Research Completed`
   - Make sure the `Output File` link points to the completed research file
4. If research uncovers new unknowns, add them as new tracker rows instead of burying them inside the completed topic.

## Research Directives

- Start with the specific decision the research must unblock. End with a recommendation or a short list of viable options.
- Prefer primary/current sources: official docs, publisher pages, package docs, platform policy docs, source repositories, live endpoint inspection, or code samples.
- Capture source links in the topic file. For time-sensitive facts, include the access date or exact current date.
- Separate facts, assumptions, and recommendations. Clearly mark unresolved risks.
- Include implementation implications: schema changes, package choices, API contracts, permissions, policy constraints, test needs, and migration concerns.
- Keep outputs actionable. A future implementer should be able to turn the research into tasks without re-reading every source.
- Avoid copying long passages from sources. Summarize, quote sparingly, and link back.
- If a topic touches legal, privacy, payments, accessibility, or app-store policy, call out the confidence level and what still needs human review.

## Decision Required — Before `flutter create`

| # | Status | Owner | Decision | Notes |
|---|--------|-------|----------|-------|
| D1 | Resolved | Tom | **App name** | **Crosscue** — approved. Package ID: `com.crosscue.crosscue`. Play Store / App Store / domain / trademark availability confirmed by owner. |

## Critical — Needed Before Writing Code

*All critical pre-code topics resolved.*

## Important — Needed In Early Sprints

*All important topics resolved.*

## Lower Priority — Worth Scheduling

*All lower-priority topics resolved.*

## Resolved

| # | Status | Owner | Topic | Output File | Research Completed | Why It Matters |
|---|--------|-------|-------|-------------|--------------------|----------------|
| 1 | Resolved | Claude | Puzzle source endpoints | [topic-01-puzzle-source-endpoints.md](research/topic-01-puzzle-source-endpoints.md) | Technical fetch URLs, response formats, token flows, and downloader strategy for Universal, LA Times, and Guardian. Robocrosswords patterns confirmed outdated; #7 legal review blocks shipping these as enabled sources without permission. | Source integration drives the first usable content experience and affects legal, caching, parser, and offline architecture. |
| 10 | Resolved | Claude | Design & UX research | [topic-10-design-ux-research.md](research/topic-10-design-ux-research.md) | Typography, color system, layout patterns, micro-interactions, onboarding, loading/error states, motivation loops, branding, and Flutter package recommendations. | Establishes the app's user experience direction and visual implementation guidance. |
| 3 | Resolved | Codex | Canvas + TalkBack/VoiceOver accessibility | [topic-03-canvas-accessibility.md](research/topic-03-canvas-accessibility.md) | CustomPainter semantics strategy, per-cell semantic nodes, traversal order, focus synchronization, announcement guidance, keyboard/zoom requirements, risks, and implementation checklist. | Confirms the app can keep canvas rendering while exposing a usable screen reader model before grid implementation begins. |
| 2 | Resolved | Codex | Drift database schema | [topic-02-drift-database-schema.md](research/topic-02-drift-database-schema.md) | Recommended Drift/SQLite schema, MVP tables, indexes/constraints, JSON converter guidance, open decisions, and first implementation slice. | Establishes the local persistence model for puzzle imports, source downloads, autosave, resume, and archive browsing. |
| 4 | Resolved | Codex | Monetization model | [topic-04-monetization-model.md](research/topic-04-monetization-model.md) | No-ads model, free-version support tiers, deferred Pro decision, store-policy constraints, entitlement boundary, privacy impact, and implementation checklist. | Keeps the solving experience clean while allowing voluntary support without forcing a paid/free product split too early. |
| 5 | Resolved | Codex | Analytics, feedback & crash reporting | [topic-05-analytics-crash-reporting.md](research/topic-05-analytics-crash-reporting.md) | Data-minimizing feedback/crash-reporting recommendation, no Phase 1 product analytics, Sentry/Firebase evaluation, privacy rules, telemetry interfaces, and implementation checklist. | Enables bug reports and crash diagnosis while collecting as little user data as possible and never logging puzzle content. |
| 6 | Resolved | Codex | Push notification architecture | [topic-06-push-notification-architecture.md](research/topic-06-push-notification-architecture.md) | Local-only post-MVP notification recommendation, permission strategy, package choices, settings data model, scheduler interface, copy guidance, risks, and implementation checklist. | Supports useful reminders without backend tokens, remote push infrastructure, notification analytics, or unnecessary data collection. |
| 7 | Resolved | Codex | Legal/ToS for puzzle sources | [topic-07-legal-tos-puzzle-sources.md](research/topic-07-legal-tos-puzzle-sources.md) | Source-by-source ToS risk review, no-scraping recommendation for Universal/LA Times/Guardian, safe Phase 1 content strategy, source legal fields, cache/attribution rules, and implementation guardrails. | Prevents building source infrastructure around content that cannot be legally fetched, cached, or redistributed without permission. |
| 8 | Resolved | Codex | CI/CD and release pipeline | [topic-08-cicd-release-pipeline.md](research/topic-08-cicd-release-pipeline.md) | GitHub Actions-first CI recommendation, phased Android/iOS release pipeline, signing/secrets guidance, fastlane timing, flavor guidance, quality gates, and starter workflow. | Gives the app a lightweight validation path now and a clear path to signed store releases later. |
| 9 | Resolved | Claude | Backend sync decision | [topic-09-backend-sync-decision.md](research/topic-09-backend-sync-decision.md) | No-backend Phase 1 recommendation, Android Auto Backup configuration, future-compatible schema columns, NoOpSyncAdapter interface, manual export/import flow, and conflict resolution strategy for Phase 2. | Keeps Phase 1 simple while ensuring local schema is sync-ready and cross-device data portability is covered without a backend. |
| 11 | Resolved | Codex | Game mechanics & input feedback | [topic-11-game-mechanics-feedback.md](research/topic-11-game-mechanics-feedback.md) | Letter-placement behavior, auto-advance, check/reveal/hint rules, rebus entry, completion validation, mistake/stats model, UI feedback matrix, accessibility copy, and open decisions on streak policy. | These rules shape the puzzle engine, UI feedback, state model, settings, accessibility semantics, and solve-history data before implementation starts. |
| 15 | Resolved | Codex | Streak & stats algorithm | [topic-15-streak-stats-algorithm.md](research/topic-15-streak-stats-algorithm.md) | Streak eligibility rules, completion types, local-date/timezone handling, current/longest streak algorithm, stats aggregates, milestone thresholds, schema fields, and implementation tests. | Rules directly affect Drift schema columns that must be in the initial migration and keep stats consistent with game mechanics. |
| 12 | Resolved | Claude | Flutter project structure & folder conventions | [topic-12-flutter-project-structure.md](research/topic-12-flutter-project-structure.md) | Full `lib/` directory tree, layer-to-folder mapping, file/class naming conventions, Riverpod provider conventions, cross-feature import rules, test mirroring, and quick-reference table. | Without a defined structure, two developers immediately create incompatible layouts. Needed before the first file is created. |
| 13 | Resolved | Claude | Screen inventory & navigation routes | [topic-13-screen-inventory-routes.md](research/topic-13-screen-inventory-routes.md) | Full screen inventory (7 screens + 4 dialogs), go_router ShellRoute setup, route path constants, AppShell code, parameter contracts, deep-link and back-stack behaviour, and implementation checklist. | Can't scaffold the app shell or wire go_router without a defined route map. Needed before any widget work starts. |
| 14 | Resolved | Claude | Puzzle file format parser spec | [topic-14-puzzle-parser-spec.md](research/topic-14-puzzle-parser-spec.md) | `.puz` binary field layout, CRC-16 validation, ISO-8859-1 handling, rebus/circle extension blocks; `.ipuz` JSON field mapping; shared `PuzzleParser` interface; `ParseError` enum; ID generation; test fixture requirements; implementation checklist. | Both formats are needed for Phase 1 file import. Parser is a standalone component that other features depend on — define it before implementing it. |
| 16 | Resolved | Codex | Phase 1 first-run & import-only experience | [topic-16-first-run-phase1.md](research/topic-16-first-run-phase1.md) | Import-first launch path, Home empty states, import success/failure flow, onboarding adjustments, sample puzzle policy, legal/privacy guardrails, data model implications, and implementation checklist. | Gives the Phase 1 app a valid first-run path without network sources or Browse Sources assumptions. |
| 17 | Resolved | Claude | UX missing details | [topic-17-ux-missing-details.md](research/topic-17-ux-missing-details.md) | Research Completed | Design decisions for 20 UX gaps: back navigation mid-solve, completion stats sheet content, ImportScreen layout, timer pause/background behavior, Archive Phase 1 list view, keyboard Check key scope, onboarding format and transition, ClueBar tap-to-toggle, clue list auto-scroll, post-completion grid review, overflow menu full spec, Settings screen layout, grid zoom/pan, SolveScreen load failure state, notification copy, puzzle notes display, single-puzzle delete, splash screen, onboarding mock grid design, and Archive orphan session handling. |
| 18 | Resolved | Claude | Privacy policy & store compliance | [topic-18-privacy-policy-store-compliance.md](research/topic-18-privacy-policy-store-compliance.md) | Research Completed | Play Store Data Safety form answers, App Store privacy label requirements, minimum viable privacy policy draft scoped to Phase 1 (no accounts, no ads, crash-reporting-only), publication checklist, and open questions for GDPR/CCPA. Must be human-reviewed before publishing. |

## Ready to Build

All pre-code research topics are resolved. Implementation planning is complete.

- **[implementation-plan.md](implementation-plan.md)** — 7-sprint ordered task breakdown with acceptance criteria and cross-sprint dependencies.
- **[pubspec-starter.yaml](pubspec-starter.yaml)** — Pinned starter `pubspec.yaml` with all Phase 1 packages; Phase 2 packages commented out. See the notes section for first-setup instructions.

Start with Sprint 1 of the implementation plan.
