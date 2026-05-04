# Agent Instructions: Crosscue (Crossword App)

## Core Principles
- **Mobile-First (Flutter):** All UI must be adaptive and follow Material 3/Cupertino principles.
- **Offline-First:** The app relies on local `.puz`/`.ipuz` imports and local SQLite (Drift) for progress.
- **Security-First:** Treat all imported files as untrusted. Validate dimensions, size, and types before parsing.
- **Legal Guardrails:** Never implement automated downloaders for "prohibited" or "needs_review" sources (e.g., NYT, LA Times, The Guardian) without explicit permission.

## Tech Stack & Dev Commands
- **Language:** Dart / Flutter
- **State Management:** Riverpod + Freezed (use immutable patterns)
- **Database:** Drift (SQLite) — **Do not use Hive or Isar**.
- **Navigation:** `go_router`
- **Code Generation:** `flutter pub run build_runner build` (Always run this after changing `@freezed` or `drift` models).
- **Splash Screen:** `dart run flutter_native_splash:create` (Run after updating `flutter_native_splash` config).
- **Linting:** `flutter analyze`

## Engineering Guidelines
- **Architecture:** Clean Architecture (Data $\to$ $Domain$ $\to$ Presentation).
- **Grid Rendering:** Use `CustomPainter` (Canvas) for high-performance, resolution-independent rendering. **Do not use SVG.**
- **Data Integrity:** Use `io-ts` style runtime validation at the data boundary (importing files).
- **State Split:** Keep `SolutionGrid` (immutable) separate from `PlayerGrid` (mutable progress).
- **Undo/Redo:** Implement using a snapshot history stack (max 20 steps) in memory.
- **Design Constraint:** Use `DynamicColor` for Material You support on Android 12+.

## Testing & Verification
- **Parser Test:** Verify `.puz` and `.ipuz` parsing with known-good fixtures.
- **Navigation Test:** Ensure cell tap $\to$ focus $\to$ direction toggle works as expected.
- **Regression:** Run `build_runner` to ensure all generated code is up-to-date.
- **Integration:** Ensure `PuzzleNotifier` autosaves to Drift after every cell change (debounced).
