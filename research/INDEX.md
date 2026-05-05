# Research Index — Crosscue

All 18 topics are **Resolved** (research complete). Implementation status reflects whether the topic's conclusions have been coded.

Status key: ✅ Implemented · 🔄 Partially Implemented · ⬜ Pending · 🔒 Active Guardrail

> ⚠️ **Legal Guardrail:** [topic-07](topic-07-legal-tos-puzzle-sources.md) classifies puzzle sources as `prohibited`, `needs_review`, `openLicense`, `explicitPermission`, or `userImport`. **Read topic-07 before writing any code that fetches, downloads, or automates access to puzzle content from external sources.** NYT, LA Times, and The Guardian are `prohibited`. This rule is permanent and applies to all sprints.

---

## By Sprint

### Sprints 1–3 (Complete)

| # | File | Topic | Status |
|---|------|-------|--------|
| 2 | [topic-02](topic-02-drift-database-schema.md) | Drift DB schema, tables, indexes, TypeConverters | ✅ Sprint 1 |
| 12 | [topic-12](topic-12-flutter-project-structure.md) | `lib/` folder layout, naming conventions | ✅ Sprint 1 — superseded by ARCHITECTURE.md |
| 13 | [topic-13](topic-13-screen-inventory-routes.md) | Screen inventory, go_router setup, route table | ✅ Sprint 1 — superseded by ARCHITECTURE.md |
| 14 | [topic-14](topic-14-puzzle-parser-spec.md) | `.puz` / `.ipuz` parser field-by-field spec | ✅ Sprint 2 — superseded by MODELS.md + code |
| 16 | [topic-16](topic-16-first-run-phase1.md) | Phase 1 import-first launch path, empty states | 🔄 Sprint 1–3 done; onboarding detail needed for Sprint 6 |
| 11 | [topic-11](topic-11-game-mechanics-feedback.md) | Letter placement, auto-advance, check/reveal rules | 🔄 Basic input done Sprint 3; check/reveal pending Sprint 5 |
| 17 | [topic-17](topic-17-ux-missing-details.md) | 20 UX gap decisions: back nav, completion sheet, keyboard, etc. | 🔄 Some decisions shipped Sprint 3; remainder drives Sprints 4–6 |
| 10 | [topic-10](topic-10-design-ux-research.md) | Typography, colour system, micro-interactions, branding | 🔄 Theme + grid colours shipped Sprints 1/3; animations pending Sprint 6 |

### Sprint 4 — Solve Persistence

| # | File | Topic | Status |
|---|------|-------|--------|
| 2 | [topic-02](topic-02-drift-database-schema.md) | `solve_sessions` + `cell_progress` autosave detail | ✅ Sprint 4 |
| 11 | [topic-11](topic-11-game-mechanics-feedback.md) | Pause/resume, timer persistence rules | ✅ Sprint 4 |
| 17 | [topic-17](topic-17-ux-missing-details.md) | §4 timer pause/background behaviour | ✅ Sprint 4 |

### Sprint 5 — Check & Reveal

| # | File | Topic | Status |
|---|------|-------|--------|
| 11 | [topic-11](topic-11-game-mechanics-feedback.md) | Check/reveal/hint rules, mistake counting, CellState transitions | ✅ Sprint 5 |
| 17 | [topic-17](topic-17-ux-missing-details.md) | §3 keyboard Check key scope, §8 ClueBar tap-to-toggle | ✅ Sprint 5 |

### Sprint 6 — Onboarding & Settings

| # | File | Topic | Status |
|---|------|-------|--------|
| 16 | [topic-16](topic-16-first-run-phase1.md) | Onboarding flow, sample puzzle policy | ✅ Sprint 6 |
| 17 | [topic-17](topic-17-ux-missing-details.md) | §7 onboarding format, §19 mock grid design, §10 post-completion review | ✅ Sprint 6 |
| 10 | [topic-10](topic-10-design-ux-research.md) | Animations, haptics, completion feedback | ✅ Sprint 6 (haptics + completion sheet; animations post-MVP) |
| 3 | [topic-03](topic-03-canvas-accessibility.md) | CustomPainter semantics, TalkBack/VoiceOver, traversal order | ⬜ Post-MVP |

### Sprint 7 — Archive & Stats

| # | File | Topic | Status |
|---|------|-------|--------|
| 15 | [topic-15](topic-15-streak-stats-algorithm.md) | Streak eligibility, local-date/timezone, current/longest streak algorithm | ✅ Sprint 7 |
| 17 | [topic-17](topic-17-ux-missing-details.md) | §5 Archive Phase 1 list view, §20 orphan session handling | ✅ Sprint 7 |

### Sprint 8 — Parser Tests & Source Registry

| # | File | Topic | Status |
|---|------|-------|--------|
| 14 | [topic-14](topic-14-puzzle-parser-spec.md) | Test fixture requirements | ✅ Sprint 8 — PuzFixtureBuilder + 78 tests |
| 1 | [topic-01](topic-01-puzzle-source-endpoints.md) | Source fetch URLs, response formats, downloader strategy | ⬜ Post-MVP — SourceRegistry foundation laid; actual downloaders blocked by topic-07 legal review |
| 7 | [topic-07](topic-07-legal-tos-puzzle-sources.md) | Per-source ToS risk, prohibited/needs-review classification | 🔒 Active guardrail — read before any source work |

### Post-MVP

| # | File | Topic | Status |
|---|------|-------|--------|
| 8 | [topic-08](topic-08-cicd-release-pipeline.md) | GitHub Actions CI, signing, Play Store release pipeline | ⬜ Post-MVP |
| 9 | [topic-09](topic-09-backend-sync-decision.md) | No-backend Phase 1 rationale, NoOpSyncAdapter, Phase 2 sync schema | ⬜ Post-MVP |
| 4 | [topic-04](topic-04-monetization-model.md) | No-ads model, voluntary support, entitlement boundary | ⬜ Post-MVP |
| 5 | [topic-05](topic-05-analytics-crash-reporting.md) | Data-minimizing crash reporting, Sentry/Firebase eval | ⬜ Post-MVP |
| 6 | [topic-06](topic-06-push-notification-architecture.md) | Local-only notifications, permission strategy, scheduler interface | ⬜ Post-MVP |
| 18 | [topic-18](topic-18-privacy-policy-store-compliance.md) | Play Store Data Safety, App Store privacy labels, privacy policy draft | ⬜ Store submission — human review required before publishing |

---

## All Topics

| # | File | Topic | Impl. Status |
|---|------|-------|--------------|
| 1 | [topic-01](topic-01-puzzle-source-endpoints.md) | Puzzle source endpoints | ⬜ Post-MVP (SourceRegistry foundation in Sprint 8; downloaders pending legal review) |
| 2 | [topic-02](topic-02-drift-database-schema.md) | Drift database schema | ✅ Sprints 1–7 |
| 3 | [topic-03](topic-03-canvas-accessibility.md) | Canvas + TalkBack/VoiceOver accessibility | ⬜ Post-MVP |
| 4 | [topic-04](topic-04-monetization-model.md) | Monetization model | ⬜ Post-MVP |
| 5 | [topic-05](topic-05-analytics-crash-reporting.md) | Analytics & crash reporting | ⬜ Post-MVP |
| 6 | [topic-06](topic-06-push-notification-architecture.md) | Push notification architecture | ⬜ Post-MVP |
| 7 | [topic-07](topic-07-legal-tos-puzzle-sources.md) | Legal / ToS for puzzle sources | 🔒 Active guardrail |
| 8 | [topic-08](topic-08-cicd-release-pipeline.md) | CI/CD & release pipeline | ⬜ Post-MVP |
| 9 | [topic-09](topic-09-backend-sync-decision.md) | Backend sync decision | ⬜ Post-MVP |
| 10 | [topic-10](topic-10-design-ux-research.md) | Design & UX research | ✅ Sprints 1–6 (haptics, completion sheet; animations post-MVP) |
| 11 | [topic-11](topic-11-game-mechanics-feedback.md) | Game mechanics & input feedback | ✅ Sprints 3–5 |
| 12 | [topic-12](topic-12-flutter-project-structure.md) | Flutter project structure | ✅ Sprint 1 |
| 13 | [topic-13](topic-13-screen-inventory-routes.md) | Screen inventory & navigation routes | ✅ Sprint 1 |
| 14 | [topic-14](topic-14-puzzle-parser-spec.md) | Puzzle file format parser spec | ✅ Sprints 2 + 8 |
| 15 | [topic-15](topic-15-streak-stats-algorithm.md) | Streak & stats algorithm | ✅ Sprint 7 |
| 16 | [topic-16](topic-16-first-run-phase1.md) | Phase 1 first-run & import-only experience | ✅ Sprint 6 |
| 17 | [topic-17](topic-17-ux-missing-details.md) | UX missing details (20 decisions) | ✅ Sprints 4–7 (app icon + TalkBack deferred post-MVP) |
| 18 | [topic-18](topic-18-privacy-policy-store-compliance.md) | Privacy policy & store compliance | ⬜ Store submission |
