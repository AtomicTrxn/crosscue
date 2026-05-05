# Deployment & Debugging Guide — Crosscue

## Environment

| Tool | Path |
|------|------|
| Flutter SDK | `/Users/tomhess/flutter/bin/flutter` |
| ADB | `adb` (on `$PATH` via Android SDK) |
| Target emulator | Pixel 9 — `emulator-5554` (`sdk gphone64 arm64`) |
| Project root | `/Users/tomhess/Claude/Crossword/crosscue/crosscue/` |

All `flutter` and `adb` commands below assume you are **inside the project root** unless stated otherwise.

---

## Running the App

### Start the emulator (if not already running)
```bash
emulator -avd Pixel_9 &
# Wait until `adb devices` shows emulator-5554 as "device"
adb devices
```

### Run with hot-reload support (recommended during development)
```bash
/Users/tomhess/flutter/bin/flutter run -d emulator-5554
```
Key commands while `flutter run` is active:
- `r` — Hot reload (preserves state)
- `R` — Hot restart (clears state)
- `q` — Quit

### Run headless (background, logs to file)
```bash
truncate -s 0 /tmp/flutter_debug.log   # clear stale output first
/Users/tomhess/flutter/bin/flutter run -d emulator-5554 --no-pub >> /tmp/flutter_debug.log 2>&1 &
```
Then tail the log:
```bash
tail -f /tmp/flutter_debug.log
```

---

## Building & Installing Manually

Use this when you need to push a specific build without keeping `flutter run` alive.

```bash
# 1. Build debug APK
/Users/tomhess/flutter/bin/flutter build apk --debug --no-pub

# 2. Install via adb
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Launch the app
adb -s emulator-5554 shell am start -n com.crosscue.crosscue/.MainActivity
```

> **Why not `flutter install`?** The `flutter install` command targets the release APK by default and doesn't accept `--no-pub`. Using `adb install -r` directly is more reliable for debug builds.

---

## Capturing Logs

### Flutter print output
Flutter's `print()` statements appear under the `I/flutter` logcat tag:
```bash
adb -s emulator-5554 logcat | grep "I/flutter"
```

### Filtered live monitoring (recommended)
```bash
adb -s emulator-5554 logcat -v brief | grep --line-buffered -E "flutter|Exception|Error|FATAL"
```

### Save to file for later review
```bash
truncate -s 0 /tmp/flutter_monitor.log
adb -s emulator-5554 logcat -v brief 2>/dev/null \
  | grep --line-buffered -E "flutter|Exception|Error|FATAL" \
  >> /tmp/flutter_monitor.log 2>&1 &
# Then read it:
cat /tmp/flutter_monitor.log
```

### Clear logcat buffer (before a fresh test)
```bash
adb -s emulator-5554 logcat -c
```

---

## Code Generation

Run after any change to `@freezed` models, `@riverpod` notifiers, or Drift tables:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or watch mode during active development:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## Linting

```bash
/Users/tomhess/flutter/bin/flutter analyze
```
Target: **0 issues**. Fix all errors and warnings before committing.

---

## Deploying to GitHub

Run from the **repo root** (`/Users/tomhess/Claude/Crossword/`), not the project subdirectory.

```bash
git add <specific files — never git add .>
git commit -m "$(cat <<'EOF'
Short imperative summary (≤ 72 chars)

Longer explanation of why, not what.
Reference sprint if relevant.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
git push origin main
```
Remote: `https://github.com/AtomicTrxn/crossque.git`

---

## Debugging Runbook

### App shows error screen ("Could not load puzzle")
The `SolveScreen` catches any exception thrown by `SolveNotifier.build()` and
displays it. Common causes:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Puzzle not found: local:…` | ID mismatch between home list and DB | Check `Uri.encodeComponent` / `decodeComponent` round-trip; verify DB row exists |
| `Invalid argument (computation)` | `Stream<T>.periodic` called without computation fn when `T` is non-nullable | Use `Stream<int>.periodic(duration, (i) => i)` |
| Null check / cast error during build | Drift query returned unexpected shape | Add `print` checkpoints in `SolveNotifier.build()` and tail logcat |

To add temporary checkpoints in `solve_notifier.dart`:
```dart
// ignore: avoid_print
print('[SolveNotifier] puzzleId=$puzzleId puzzle=${puzzle?.metadata.title}');
```

### App freezes on tap / "child into parent of itself" crash
**Cause:** Two widgets sharing the same `FocusNode` — Flutter's focus tree
detects a circular parent-child relationship and enters an infinite layout loop.

**Pattern to avoid:**
```dart
// ❌ WRONG — Focus widget and TextField both own _focusNode
Focus(
  focusNode: _focusNode,
  child: TextField(focusNode: _focusNode, ...),
)
```

**Correct pattern:**
```dart
// ✅ Attach key handler to the FocusNode directly in initState;
//    TextField is the sole widget owner of the node.
@override
void initState() {
  super.initState();
  _focusNode.onKeyEvent = _handleKeyEvent;
}

// In build — no outer Focus wrapper:
TextField(focusNode: _focusNode, ...)
```

### File picker spins indefinitely (Android)
`.puz`, `.ipuz`, and `.jpz` files have no registered MIME types on Android.
Using `FileType.custom` with those extensions produces an empty MIME list and
throws a `PlatformException` that leaves the UI stuck in the picking state.

**Fix:** Use `FileType.any` and validate the extension client-side:
```dart
result = await FilePicker.platform.pickFiles(
  type: FileType.any,   // NOT FileType.custom
  withData: true,
);
// Then:
final ext = file.extension?.toLowerCase() ?? '';
if (!{'puz', 'ipuz', 'jpz'}.contains(ext)) { ... }
```
Always wrap `pickFiles` in try/catch for `PlatformException`.

### Freezed compile errors ("Missing concrete implementations")
Freezed 3.x requires `abstract class` for **single-factory** classes.
Multi-factory (union) classes use plain `class`.

```dart
// ✅ Single factory — must be abstract
@freezed
abstract class Clue with _$Clue {
  const factory Clue({...}) = _Clue;
}

// ✅ Union type — plain class
@freezed
class ImportState with _$ImportState {
  const factory ImportState.idle() = ImportIdle;
  const factory ImportState.loading() = ImportLoading;
}
```

### Riverpod 3.x quick reference
- Generated provider name is derived from the **class name**, not the file:
  `ImportNotifier` → `importProvider` (not `importNotifierProvider`)
- No `valueOrNull` on `AsyncValue` — use pattern matching:
  ```dart
  SolveState? get _s => switch (state) {
    AsyncData(:final value) => value,
    _ => null,
  };
  ```
- Family providers: `@riverpod class SolveNotifier` with `String puzzleId`
  argument generates `solveProvider(puzzleId)`.
