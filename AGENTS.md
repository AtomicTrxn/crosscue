# Agent Instructions: Crosscue (Crossword App)

## Read These First

Before writing any code, read these documents in order:

| Doc | Purpose |
|-----|---------|
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | Feature structure, layer rules, data flow diagrams, checklist for adding a new feature |
| **[SPRINTS.md](./SPRINTS.md)** | Open/planned work (⬜) and deferred items (⏸) — check this before starting any task |
| **[ISSUES.md](./ISSUES.md)** | Bug reports and enhancement requests — check before starting any sprint for items to pull in |
| **[MODELS.md](./MODELS.md)** | Every domain model, its fields, DB mapping, and ID format |
| **[CONVENTIONS.md](./CONVENTIONS.md)** | Hard rules: Freezed 3.x, Riverpod 3.x, FocusNode, file picker, routing, Drift, naming |
| **[DEPLOYMENT.md](./DEPLOYMENT.md)** | How to run, build, install, monitor logs, and debug on the emulator |

Historical shipped-sprint detail lives in **[COMPLETED_SPRINTS.md](./COMPLETED_SPRINTS.md)**. Do not load it unless past implementation context is specifically needed.

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
| Language | Dart / Flutter | Use `flutter` on `PATH`, or set `FLUTTER=/path/to/flutter/bin/flutter` |
| State | Riverpod 3 + `riverpod_annotation` | Codegen — see CONVENTIONS.md for naming rules |
| Models | Freezed 3 | `abstract class` for single-factory — see CONVENTIONS.md |
| Database | Drift (SQLite) | Do NOT use Hive or Isar |
| Navigation | `go_router` | Always use `Routes` constants, never raw strings |
| Grid rendering | `CustomPainter` | Do NOT use SVG or widget-per-cell |
| Theming | `DynamicColor` | Material You on Android 12+ |

---

## Dev Commands

CI checks run from the **repo root** via `make`:

```bash
make ci          # full pipeline (format → analyze + test + generated → build APK)
make format      # dart format check only
make analyze     # flutter analyze only
make test        # flutter test only
make generated   # build_runner + generated-file drift check
make build       # debug APK build only
make install-hooks  # wire up git hooks (run once after cloning)
```

Flutter/Dart commands run from the **Flutter project root**: `crosscue/`

```bash
# Code generation (run after any @freezed / @riverpod / @DriftDatabase change)
dart run build_runner build

# Run on emulator
flutter run -d <device-id>

# Build + install manually (see DEPLOYMENT.md for full workflow)
flutter build apk --debug --no-pub
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
```

When adding packages, reference **`crosscue/pubspec.yaml`** — it lists all Phase 1 packages with their locked versions, and Phase 2 packages are commented out inline.

---

## Before Every Push

1. `dart run build_runner build` — regenerate if any annotated files changed
2. **`make ci`** — run the full pipeline (format → analyze → test → generated → build) from the repo root; do not substitute individual commands
3. Stage only app source files — never commit `.claude/settings.local.json`, `*.save`, or temp files
4. Follow the commit message style in CONVENTIONS.md

The pre-push git hook runs `make ci` automatically when pushing to `main`,
blocking the push on any failure. Run `make install-hooks` once after cloning
to activate it. On feature branches the hook does not fire — run `make ci`
manually before opening a PR.

---

## Research

**[research/INDEX.md](./research/INDEX.md)** maps each sprint to the research topics that inform it. Before starting any sprint, open INDEX.md and read the topics listed under that sprint heading. Topic-07 (legal/ToS) is a permanent guardrail — read it before touching any puzzle source code.

---

## Testing & Verification

- **Parser tests:** Verify `.puz` and `.ipuz` parsing with known-good fixtures (Sprint 8)
- **Navigation:** Cell tap → focus → direction toggle → letter input → advance
- **Regression:** Run `build_runner` to keep generated code in sync
- **Persistence:** After Sprint 4, verify that closing and reopening a puzzle restores exact cell progress, focus position, and elapsed time
