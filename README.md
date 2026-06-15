# Crosscue

**A crossword app for people who want the puzzle, not the strings attached.**

Crosscue is a fast, privacy-first crossword solver for iOS and Android. Import
your own `.puz` or `.ipuz` files, grab supported daily minis, chase your
streak, compare times with friends, and keep solving even when the network is
gone. No account. No ads. No analytics. Your puzzles stay yours.

---

## Why It Exists

Most crossword apps make you bring a subscription, an account, or a tolerance
for tracking. Crosscue tries to be the opposite: a serious solver that feels
light, capable, and a little playful.

It is built for the daily mini person, the Sunday-puzzle person, the
Bluetooth-keyboard person, and the "please just let me solve in peace" person.

## What You Can Do

- **Solve real crossword files**: import `.puz` and `.ipuz` puzzles from your
  device, files app, messages, or wherever your puzzles live.
- **Download supported daily minis**: Crosshare daily minis can be pulled right
  into the app, with author credit and source links.
- **Use a proper crossword grid**: tap to move, tap again to switch direction,
  swipe, type on-screen, or plug in a hardware keyboard.
- **Check or reveal without losing the thread**: check a letter, word, or full
  grid; reveal when you want help; keep mistakes and reveals distinct.
- **Pick up exactly where you left off**: autosave preserves grid progress,
  focus, and timer state.
- **Solve rebus puzzles**: multi-letter cells are parsed, displayed, entered,
  and saved correctly.
- **Track the habit**: archive, stats, streaks, completion history, best times,
  and shareable results are all local-first.
- **Make it readable**: light, dark, system theme, colorblind-friendly
  verification colors, and VoiceOver support across the solve screen.
- **Glance and jump back in**: Home/Lock-screen widgets show your streak and
  today's puzzle; shortcuts can open today's puzzle, stats, or your last solve.
- **Sync only if you ask**: iOS uses your private iCloud container; Android uses
  your Google Drive AppData space. Crosscue does not run a sync server.
- **Challenge friends privately**: optional invite-only Challenge Boards let a
  small group compare daily-mini times with pseudonymous handles and avatars.

## Privacy, Plainly

Crosscue's default mode is offline. Puzzles, progress, stats, settings, and
history live in a local SQLite database on your device.

Network access happens only for things you choose:

- downloading a puzzle from an online source,
- enabling cloud sync through your own iCloud or Google account,
- joining an optional Challenge Board.

Challenge Boards are the one Crosscue-operated online service. They are
private, invite-only, pseudonymous, and deletable in-app. They store only the
board data needed to compare times with friends. The rest of the app keeps
working if you never touch them.

Read the public [privacy policy](https://atomictrxn.github.io/crosscue/privacy.html)
or the source doc at [docs/privacy.md](docs/privacy.md).

## Current State

Crosscue is actively developed and available on iOS and Android builds.

Core solving, import, archive, stats, settings, widgets, shortcuts, optional
sync, and Challenge Boards are implemented. The project is now mostly in the
"make it sturdier, smoother, and store-ready" phase: release QA, platform
polish, backend hardening, dependency updates, and follow-on features are
tracked in [GitHub Issues](https://github.com/AtomicTrxn/crosscue/issues).

The current app version lives in [`crosscue/pubspec.yaml`](crosscue/pubspec.yaml)
(`version:`) — the single source of truth, read at runtime and never hardcoded
elsewhere ([ADR-0005](docs/architecture/decisions/0005-runtime-app-version.md)).

## Get Started

### iOS

Install via TestFlight while the App Store release is being prepared, or build
locally with Flutter and Xcode.

### Android

Sideload a debug or release APK, use the Play closed test when available, or
build locally with Flutter and Android Studio tooling.

### Build From Source

```bash
cd crosscue
flutter pub get
flutter run
```

Pick an explicit device when you have more than one attached:

```bash
flutter devices
flutter run -d <device-id>
```

Run the main verification pipeline from the repo root:

```bash
make ci
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for signing, simulator/device installs,
release builds, log capture, and store-checklist details.

## Project Map

```text
crosscue/                         Flutter app
crosscue/backend/challenge_boards Cloudflare Worker for Challenge Boards
deeplinks/                        Universal/App Links hosting files
docs/                             ADRs, QA checklists, runbooks, reviews
design/                           Store assets and color references
```

## Developer Docs

| Doc | What's inside |
|-----|---------------|
| [PRODUCT.md](PRODUCT.md) | Vision, product principles, roadmap themes, non-goals |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Commands, architecture summary, contributor workflow |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer rules, feature structure, data flow, performance budgets |
| [MODELS.md](MODELS.md) | Model semantics, invariants, ID formats, DB mapping |
| [CONVENTIONS.md](CONVENTIONS.md) | Coding rules for Freezed, Riverpod, Drift, routing, source licensing |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Build, install, release, signing, backup/restore, store checklists |
| [SECURITY.md](SECURITY.md) | Vulnerability disclosure policy |
| [docs/index.md](docs/index.md) | Index for ADRs, design docs, runbooks, QA, reviews, policies |
| [Crosscue Color Guide](design/Crosscue%20Color%20Guide.html) | Current color system reference |
| [Challenge Boards Worker](crosscue/backend/challenge_boards/README.md) | Backend setup and local development |

## The Vibe

Crosscue is opinionated in a quiet way: offline first, privacy first, solve
quality first. It wants to be the app you can open every morning without
negotiating with anything except the clues.
