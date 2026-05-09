# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Read First

Before writing any code, read these docs in order — they contain decisions that are not obvious from the code alone:

| Doc | What it covers |
|-----|---------------|
| `ARCHITECTURE.md` | Layer rules, feature structure, data flow, new-feature checklist |
| `SPRINTS.md` | All open/planned work — check before starting any task |
| `ISSUES.md` | Bug reports and enhancements — check before starting any sprint |
| `MODELS.md` | Every domain model, field list, DB mapping, ID format |
| `CONVENTIONS.md` | Hard rules born from real bugs (Freezed, Riverpod, FocusNode, FilePicker, routing) |
| `DEPLOYMENT.md` | Build, run, install, log capture, and debugging runbook |

`COMPLETED_SPRINTS.md` has historical sprint detail — load only when past implementation context is needed.

---

## Commands

All `make` targets run from the **repo root**. All `flutter`/`dart` commands run from `crosscue/`.

```bash
# Run the full CI pipeline locally (mirrors GitHub Actions exactly)
make ci

# Individual checks
make format      # dart format check
make analyze     # flutter analyze
make test        # flutter test
make generated   # build_runner + git diff check
make build       # debug APK

# Run a single test file
cd crosscue && flutter test test/features/import/puz_parser_test.dart

# Run tests matching a name pattern
cd crosscue && flutter test --name "rebus cells"

# Code generation — required after any @freezed / @riverpod / @DriftDatabase change
cd crosscue && dart run build_runner build

# Watch mode during active development
cd crosscue && dart run build_runner watch

# Run on emulator
cd crosscue && flutter run -d <device-id>

# Install git hooks (run once after cloning)
make install-hooks
```

**Always run `make ci` before pushing or opening a PR.** Individual targets (`make format`, `make test`, etc.) are for iterating on a specific failure only — they do not substitute for the full pipeline. The pre-push hook enforces `make ci` on pushes to `main`; on feature branches it does not fire, so `make ci` must be run manually.

---

## Architecture in Brief

Clean Architecture: **Data → Domain → Presentation** per feature. Features live under `lib/features/<name>/`, shared infrastructure under `lib/core/`.

**Layer rules (hard):**
- Domain models never import Flutter
- Presentation never touches Drift tables directly
- Repositories are always exposed as their **interface type** via `@Riverpod(keepAlive: true)` providers; the impl is injected inside the provider

**Shared vs feature-local models:**
- Models consumed by more than one feature → `core/domain/models/`
- Solve-only models (`CellProgress`, `FocusPosition`) → `features/solve/domain/models/`
- `Grid<T>` and `SolveState` are plain Dart classes (not Freezed) because Freezed can't handle generic type parameters

**State management pattern:**
- `presentation/notifiers/` — stateful `AsyncNotifier` subclasses owning business logic, timers, multi-step workflows
- `presentation/providers/` — pure Riverpod providers: repositories, read/query derivations
- `SolveState` is a plain immutable class with a hand-written `copyWith`; update state with `state = AsyncData(s.copyWith(...))`

**Database:**
- Drift (SQLite), accessed only from data-layer DAOs — never from presentation
- `puzzles.canonicalJson` stores the full `Grid<SolutionCell>` as JSON via `GridSerializer` — no separate cells table
- All multi-table writes must use `transaction()`

**Grid rendering:**
- `CrosswordGridPainter` is a `CustomPainter` — one `paint()` call for the whole grid, no widget-per-cell
- Keyboard input: physical keys via `FocusNode.onKeyEvent` (set in `initState`); soft keyboard via a hidden offscreen `TextField` with `keyboardType: TextInputType.none`

---

## Key Gotchas

**Freezed 3.x:**
- Single-factory classes → `abstract class`. Multi-factory (union) classes → plain `class`.
- Always run `build_runner` after changes.

**Riverpod 3.x:**
- Generated provider name comes from the class name: `SolveNotifier` → `solveProvider` (not `solveNotifierProvider`)
- No `valueOrNull` — use `switch (state) { AsyncData(:final value) => value, _ => null }`
- `keepAlive: true` required on all repository and infrastructure providers

**Android specifics:**
- File picker: always `FileType.any`, validate extension client-side — `.puz`/`.ipuz`/`.jpz` have no registered MIME types
- Never share a `FocusNode` between a `Focus` widget and its `TextField` child — causes circular focus tree crash

**Routing:**
- Always use `Routes` constants, never raw strings
- Puzzle IDs contain `:` — `Uri.encodeComponent` when navigating, `Uri.decodeComponent` in `SolveNotifier.build()`

**Result type:**
- Parsers and repository methods return `Result<T, E>` — never throw across layer boundaries
- Notifiers translate `Result` into sealed state variants

---

## CI Pipeline

```
Stage 1   Format
             │
Stage 2   Analyze ── Test ── Generated files   (parallel)
             │
Stage 3   Build debug APK
```

All jobs use Flutter `3.41.9`. Format requires `flutter pub get` first so the formatter resolves the SDK constraint and applies the correct tall style.
