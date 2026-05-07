# Crosscue

An Android crossword puzzle app built with Flutter.

Import `.puz` or `.ipuz` puzzle files, solve them with a full interactive grid and
clue panel, track your solving history, and build a daily streak.

**Phase 1: Android only.** iOS is Phase 2.

---

## Project Docs

All documentation lives in the repository root:

| Doc | Purpose |
|-----|---------|
| [AGENTS.md](../../AGENTS.md) | Start here — agent orientation, tech stack, dev commands |
| [ARCHITECTURE.md](../../ARCHITECTURE.md) | Feature structure, layer rules, data flow, new-feature checklist |
| [SPRINTS.md](../../SPRINTS.md) | Sprint tracker — what's done, what's next |
| [MODELS.md](../../MODELS.md) | Domain model field reference |
| [CONVENTIONS.md](../../CONVENTIONS.md) | Hard coding rules (Freezed, Riverpod, Drift, routing, etc.) |
| [DEPLOYMENT.md](../../DEPLOYMENT.md) | How to build, install, monitor logs, and debug |
| [research/INDEX.md](../../research/INDEX.md) | Sprint-by-sprint research navigator |

---

## Quick Start

```bash
# All commands run from this directory:
# crosscue/

# Run on emulator
flutter run -d <device-id>

# Build + install
flutter build apk --debug --no-pub
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <device-id> shell am start -n com.crosscue.crosscue/.MainActivity

# Regenerate after model/notifier/table changes
flutter pub run build_runner build --delete-conflicting-outputs

# Lint (must be 0 issues before committing)
flutter analyze
```

---

## Tech Stack

| Concern | Library |
|---------|---------|
| Language | Dart / Flutter |
| State | Riverpod 3 + riverpod_annotation |
| Models | Freezed 3 |
| Database | Drift (SQLite) |
| Navigation | go_router |
| Grid rendering | CustomPainter |
| Theming | Material 3 + DynamicColor |
