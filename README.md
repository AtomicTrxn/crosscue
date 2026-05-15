# Crosscue

**Your crossword puzzles. Your device. No strings attached.**

Crosscue is an Android app for solving crossword puzzle files — built for people who want a clean, capable solver that stays out of their way. No subscription. No account. Your puzzles and progress live on your device.

---

## What It Does

Import a `.puz` or `.ipuz` file from anywhere on your phone and start solving immediately. Crosscue handles the rest:

- **Full interactive grid** — tap a cell to start, tap again to flip direction, swipe or use arrow keys to move
- **Physical and on-screen keyboard** — works with Bluetooth keyboards and the soft keyboard alike
- **Check & reveal** — check a letter, word, or the full grid; reveal when you're stuck; mistakes are tracked separately from reveals
- **Auto-save** — close the app mid-solve and pick up exactly where you left off, timer included
- **Rebus support** — multi-letter entries parsed and displayed correctly
- **Archive & stats** — every completed puzzle recorded with time, date, and solve method; streaks tracked per local calendar date
- **Colorblind mode** — deuteranopia-friendly dot indicator instead of color-only error feedback
- **Light, dark, and system theme**

---

## Offline by Design

Crosscue stores puzzles, progress, history, and stats locally in a SQLite
database on your device. There is no account, sync, advertising, or analytics.
When you choose to download a puzzle from an online source, the app makes the
network request needed to fetch that puzzle.

---

## Status

**Phase 1 — Android.** Core solving, importing, persistence, archive, stats, settings, and onboarding are feature-complete. Active development is tracked in [GitHub Issues](https://github.com/AtomicTrxn/crosscue/issues).

iOS is Phase 2.

---

## Get Started

Sideload the latest APK from [Releases](../../releases), or build from source:

```bash
cd crosscue
flutter pub get
flutter run
```

---

## Developer Docs

| Doc | What's inside |
|-----|---------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Commands, architecture summary, and contributor workflow |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer rules, feature structure, data flow, new-feature checklist |
| [MODELS.md](MODELS.md) | Every domain model, field list, and DB mapping |
| [CONVENTIONS.md](CONVENTIONS.md) | Hard coding rules — Freezed, Riverpod, Drift, routing, legal source guardrail |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Build, install, log capture, release pipeline, Play Store checklist |
| [Privacy Policy](https://atomictrxn.github.io/crosscue/privacy.html) | Public privacy policy for Play Store submission |
