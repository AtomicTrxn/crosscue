# Crosscue

Crosscue is a clean, offline-first crossword app for solving your own puzzle files on Android.

Import `.puz` or `.ipuz` crossword files, solve them with a touch-friendly interactive grid, and keep your progress, history, and stats on your device.

## Features

- Import `.puz` and `.ipuz` puzzle files from your device
- Solve with a full crossword grid and clue panel
- Check or reveal letters, words, and the full puzzle
- Resume puzzles with progress, timer, and position restored
- Track solve history, streaks, and stats
- Light, dark, and system theme
- Colorblind mode (deuteranopia dot indicator)

## Offline by Design

All puzzles, progress, and stats stay on your device. No account required. The app does not include built-in puzzle downloads — future sources will only be added once legally cleared.

## Status

Core puzzle importing, solving, persistence, archive, stats, settings, and onboarding are complete. Active development continues — see [GitHub Issues](https://github.com/AtomicTrxn/crossque/issues) for planned work.

**Phase 1: Android.** iOS is Phase 2.

## Project Docs

| Doc | Purpose |
|-----|---------|
| [CLAUDE.md](CLAUDE.md) | Agent orientation, commands, architecture summary, gotchas |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Feature structure, layer rules, data flow, new-feature checklist |
| [MODELS.md](MODELS.md) | Domain model field reference and DB mapping |
| [CONVENTIONS.md](CONVENTIONS.md) | Hard coding rules (Freezed, Riverpod, Drift, routing, etc.) |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Build, install, log capture, and debug runbook |
| [research/INDEX.md](research/INDEX.md) | Background research by topic |
