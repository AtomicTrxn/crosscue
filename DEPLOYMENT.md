# Deployment & Debugging Guide — Crosscue

## Environment

| Tool | Path |
|------|------|
| Flutter SDK | `flutter` on `PATH`, or set `FLUTTER=/path/to/flutter/bin/flutter` |
| ADB | `adb` (on `$PATH` via Android SDK) |
| Target emulator | Any Android emulator/device shown by `adb devices` |
| Project root | `crosscue/` |

All `flutter` and `adb` commands below assume you are **inside the project root** unless stated otherwise.

---

## Running the App

### Start the emulator (if not already running)
```bash
emulator -avd <avd-name> &
# Wait until `adb devices` shows your target as "device"
adb devices
```

### Run with hot-reload support (recommended during development)
```bash
flutter run -d <device-id>
```
Key commands while `flutter run` is active:
- `r` — Hot reload (preserves state)
- `R` — Hot restart (clears state)
- `q` — Quit

### Run headless (background, logs to file)
```bash
truncate -s 0 /tmp/crosscue_flutter_debug.log   # clear stale output first
flutter run -d <device-id> --no-pub >> /tmp/crosscue_flutter_debug.log 2>&1 &
```
Then tail the log:
```bash
tail -f /tmp/crosscue_flutter_debug.log
```

---

## Building & Installing Manually

Use this when you need to push a specific build without keeping `flutter run` alive.

```bash
# 1. Build debug APK
flutter build apk --debug --no-pub

# 2. Install via adb
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Launch the app
adb -s <device-id> shell am start -n com.crosscue.crosscue/.MainActivity
```

> **Why not `flutter install`?** The `flutter install` command targets the release APK by default and doesn't accept `--no-pub`. Using `adb install -r` directly is more reliable for debug builds.

---

## Capturing Logs

### Flutter print output
Flutter's `print()` statements appear under the `I/flutter` logcat tag:
```bash
adb -s <device-id> logcat | grep "I/flutter"
```

### Filtered live monitoring (recommended)
```bash
adb -s <device-id> logcat -v brief | grep --line-buffered -E "flutter|Exception|Error|FATAL"
```

### Save to file for later review
```bash
truncate -s 0 /tmp/crosscue_flutter_monitor.log
adb -s <device-id> logcat -v brief 2>/dev/null \
  | grep --line-buffered -E "flutter|Exception|Error|FATAL" \
  >> /tmp/crosscue_flutter_monitor.log 2>&1 &
# Then read it:
cat /tmp/crosscue_flutter_monitor.log
```

### Clear logcat buffer (before a fresh test)
```bash
adb -s <device-id> logcat -c
```

---

## Code Generation

Run after any change to `@freezed` models, `@riverpod` notifiers, or Drift tables:
```bash
dart run build_runner build
```

Or watch mode during active development:
```bash
dart run build_runner watch
```

---

## Linting

Run the full pipeline, not individual checks:

```bash
make ci
```

`make ci` runs format → analyze → test → generated-files check → build APK in the correct order, matching CI exactly. Running individual commands (e.g. `flutter analyze` alone) is only appropriate when iterating on a specific failure — **always finish with `make ci` before pushing**.

---

## Pull Request Workflow

All code and documentation changes should land through a pull request into
`main`. Run commands from the **repo root**, not the Flutter project
subdirectory, unless a command explicitly says otherwise.

### Create a branch

```bash
git checkout main
git pull --ff-only origin main
git checkout -b feature/short-description
```

### Verify locally

**Always run `make ci` from the repo root before pushing — no exceptions:**

```bash
make ci
```

This mirrors the full CI pipeline (format → analyze + test + generated → build APK). Individual targets exist for iterating on a specific failure, but `make ci` must be the final check before any push or PR:

```bash
make format      # formatting check only
make analyze     # flutter analyze only
make test        # flutter test only
make generated   # build_runner + git diff check
make build       # debug APK build only
```

The pre-push hook runs `make ci` automatically whenever you push to `main`,
blocking the push if any check fails. For all other branches, pushes are
unblocked — `make ci` must be run manually before opening a PR.

To bypass the hook in an emergency: `git push --no-verify`

### Commit and push

Run from the repo root:

```bash
git add <specific files — never git add .>
git commit -m "$(cat <<'EOF'
Short imperative summary (≤ 72 chars)

Longer explanation of why, not what.
Reference sprint if relevant.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
git push -u origin feature/short-description
```

Then open a pull request targeting `main`. GitHub Actions runs CI on every PR
and on every push to `main`. Merge only after CI is green.

Remote: use the repository's configured `origin` URL (`git remote -v`).

### CI coverage

`.github/workflows/ci.yml` runs in three sequential stages. A stage only
starts if all jobs in the previous stage passed.

```
Stage 1   Format
             │
Stage 2   Analyze ── Test ── Generated files   (parallel)
             │
Stage 3   Build debug APK
```

| Stage | Job | Command |
|-------|-----|---------|
| 1 | **Format** | `flutter pub get` → `dart format --output=none --set-exit-if-changed .` |
| 2 | **Analyze** | `flutter pub get` → `flutter analyze` |
| 2 | **Test** | `flutter pub get` → `flutter test` |
| 2 | **Generated files** | `flutter pub get` → `dart run build_runner build` → `git diff --exit-code` |
| 3 | **Build debug APK** | Java 17 → `flutter pub get` → `flutter build apk --debug --no-pub` |

All jobs use Flutter `3.41.9`. Format runs `flutter pub get` first so the
formatter can resolve the SDK constraint and apply the correct style. The APK
build artifact is not uploaded or retained after the job finishes.

---

## Release Pipeline

| Trigger | Builds | Publishes |
|---------|--------|-----------|
| Push a `v*.*.*` tag | Signed APK | GitHub Release with APK attached |
| `workflow_dispatch` with `play_store: true` | Signed APK + AAB | GitHub Release + Play Store internal track |

### One-time setup: create a keystore

Run this once locally and keep the keystore file safe (outside the repo):

```bash
keytool -genkey -v \
  -keystore ~/crosscue-release.jks \
  -alias crosscue \
  -keyalg RSA -keysize 2048 -validity 10000
```

Encode it for GitHub Secrets:
```bash
base64 -i ~/crosscue-release.jks | pbcopy   # macOS — copies to clipboard
```

### One-time setup: add GitHub Secrets

Go to **GitHub → repo → Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` file (from the command above) |
| `KEY_ALIAS` | `crosscue` (or whatever alias you chose) |
| `KEY_PASSWORD` | The key password you entered |
| `STORE_PASSWORD` | The keystore password you entered |

### Local release signing (optional)

To build a release-signed APK locally, create `crosscue/android/key.properties` (gitignored):

```properties
storeFile=/Users/you/crosscue-release.jks
keyAlias=crosscue
storePassword=your-store-password
keyPassword=your-key-password
```

Then:
```bash
cd crosscue && flutter build apk --release --no-pub
```

### Cutting a release

```bash
git checkout main && git pull
git tag v1.2.3
git push origin v1.2.3
```

This triggers `.github/workflows/release.yml`, which:
1. Runs full CI (format → analyze → test → generated → debug APK)
2. Builds a signed release APK with version name `1.2.3` and version code `10203`
3. Publishes a GitHub Release at `v1.2.3` with the APK attached and auto-generated release notes

**Version code formula:** `major × 10000 + minor × 100 + patch`
- `v1.0.0` → `10000`
- `v1.1.0` → `10100`
- `v1.0.3` → `10003`

### Play Store upload

When ready to ship to Google Play, use `workflow_dispatch` from the Actions tab:
- Select **Release** workflow → **Run workflow**
- Enter the tag (must already exist) and set `play_store: true`

This builds both the APK and a signed AAB, attaches the APK to the GitHub Release, and uploads the AAB to the Play Store internal track. Requires an additional secret `PLAY_SERVICE_ACCOUNT_JSON` (a Google Cloud service account key with the **Release Manager** role on the Play Console) and the commented-out upload step in `release.yml` to be uncommented.

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

### Solve lifecycle QA checklist

Use this when touching `SolveScreen` lifecycle or autosave behavior:

| Transition | Expected result |
|------------|-----------------|
| Foreground → background (`paused`) | Timer pauses and current progress is saved. |
| Hidden / split-screen (`hidden`) | Same as paused. |
| Phone-call style interruption (`inactive`) | No forced pause; brief interruptions keep the timer running. |
| Background → foreground (`resumed`) | User-paused puzzles stay paused; the pause overlay controls resume. |
| App detached / process teardown (`detached`) | Pending autosave is flushed before disposal when possible. |
| System kill after background | No special callback required; progress was already autosaved on pause. |

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
