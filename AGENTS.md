# Agent Instructions: Crosscue (Crossword App)

## Read These First

Before writing any code, read these documents in order:

| Doc | Purpose |
|-----|---------|
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | Feature structure, layer rules, data flow diagrams, checklist for adding a new feature |
| **[SPRINTS.md](./SPRINTS.md)** | What is already built (✅), what is next (⬜), what is deferred (⏸) — check this before starting any task |
| **[ISSUES.md](./ISSUES.md)** | Bug reports and enhancement requests — check before starting any sprint for items to pull in |
| **[MODELS.md](./MODELS.md)** | Every domain model, its fields, DB mapping, and ID format |
| **[CONVENTIONS.md](./CONVENTIONS.md)** | Hard rules: Freezed 3.x, Riverpod 3.x, FocusNode, file picker, routing, Drift, naming |
| **[DEPLOYMENT.md](./DEPLOYMENT.md)** | How to run, build, install, monitor logs, and debug on the emulator |

---

## Core Principles

- **Mobile-First (Flutter):** All UI must be adaptive and follow Material 3 principles.
- **Offline-First:** The app relies on local `.puz`/`.ipuz` imports and local SQLite (Drift) for all state.
- **Security-First:** Treat all imported files as untrusted. Validate dimensions, size, and types before parsing.
- **Legal Guardrails:** Never implement automated downloaders for `prohibited` or `needs_review` sources (e.g., NYT, LA Times, The Guardian) without explicit permission. See `LicenseStatus` enum.
- **Phase 1 = Android only.** iOS is Phase 2. Do not add iOS-specific code yet.

---

## Tech Stack

| Concern | Library | Notes |
|---------|---------|-------|
| Language | Dart / Flutter | SDK at `/Users/tomhess/flutter/bin/flutter` |
| State | Riverpod 3 + `riverpod_annotation` | Codegen — see CONVENTIONS.md for naming rules |
| Models | Freezed 3 | `abstract class` for single-factory — see CONVENTIONS.md |
| Database | Drift (SQLite) | Do NOT use Hive or Isar |
| Navigation | `go_router` | Always use `Routes` constants, never raw strings |
| Grid rendering | `CustomPainter` | Do NOT use SVG or widget-per-cell |
| Theming | `DynamicColor` | Material You on Android 12+ |

---

## Dev Commands

All commands must be run from the **project root**: `/Users/tomhess/Claude/Crossword/crosscue/crosscue/`

```bash
# Code generation (run after any @freezed / @riverpod / @DriftDatabase change)
/Users/tomhess/flutter/bin/flutter pub run build_runner build

# Lint — must be 0 issues before committing
/Users/tomhess/flutter/bin/flutter analyze

# Run on emulator
/Users/tomhess/flutter/bin/flutter run -d emulator-5554

# Build + install manually (see DEPLOYMENT.md for full workflow)
/Users/tomhess/flutter/bin/flutter build apk --debug --no-pub
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

When adding packages, reference **`pubspec-starter.yaml`** in the repo root — it lists all Phase 1 packages with pinned versions and Phase 2 packages commented out.

---

## Before Every Commit

1. `build_runner build` — regenerate if any annotated files changed
2. `flutter analyze` — 0 issues required
3. Stage only app source files — never commit `.claude/settings.local.json`, `*.save`, or temp files
4. Follow the commit message style in CONVENTIONS.md

---

## Research

**[research/INDEX.md](./research/INDEX.md)** maps each sprint to the research topics that inform it. Before starting any sprint, open INDEX.md and read the topics listed under that sprint heading. Topic-07 (legal/ToS) is a permanent guardrail — read it before touching any puzzle source code.

---

## Testing & Verification

- **Parser tests:** Verify `.puz` and `.ipuz` parsing with known-good fixtures (Sprint 8)
- **Navigation:** Cell tap → focus → direction toggle → letter input → advance
- **Regression:** Run `build_runner` to keep generated code in sync
- **Persistence:** After Sprint 4, verify that closing and reopening a puzzle restores exact cell progress, focus position, and elapsed time
