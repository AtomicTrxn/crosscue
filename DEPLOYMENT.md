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
adb -s <device-id> shell am start -n dev.tomhess.crosscue/.MainActivity
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

`make ci` runs the same checks required by hosted PR CI: static checks plus the
test suite. Running individual commands (e.g. `flutter analyze` alone) is only
appropriate when iterating on a specific failure — **always finish with
`make ci` before pushing**.

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

This mirrors hosted PR CI. Individual targets exist for iterating on a specific
failure, but `make ci` must be the final check before any push or PR:

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
EOF
)"
git push -u origin feature/short-description
```

Then open a pull request targeting `main`. GitHub Actions runs CI on every PR
and on every push to `main`. Merge only after CI is green.

Remote: use the repository's configured `origin` URL (`git remote -v`).

### CI coverage

`.github/workflows/ci.yml` emits two required checks on ordinary pull requests
and pushes to `main`:

```
Static checks   format → analyze → generated files
Test            flutter test
```

| Check | App-affecting change | Documentation-only change |
|-------|----------------------|---------------------------|
| **Static checks** | `flutter pub get` → format → analyze → generated files | reports success without Flutter setup |
| **Test** | `flutter pub get` → `flutter test` | reports success without Flutter setup |

All app checks use Flutter `3.41.9`. The debug APK job exists only for reusable
workflow callers that explicitly request it; ordinary PR CI does not build an
APK. Release workflows run the full app checks and build signed release
artifacts instead.

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
# Bump pubspec.yaml version first, commit, push, then tag
git tag v1.2.3
git push origin v1.2.3
```

This triggers `.github/workflows/release.yml`, which:
1. Runs full CI (static checks + tests)
2. Builds a signed release APK with version name `1.2.3` and version code `10203`
3. Publishes a GitHub Release at `v1.2.3` with the APK attached and auto-generated release notes

**Release title:** always the bare version number — `v1.2.3`. All context goes in the release body, not the title.

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

## Play Store Submission Checklist

Complete these steps before submitting to Google Play for the first time.
Human review is required before publishing — this is not legal advice.

### Privacy policy (required before submission)
- [x] Publish a privacy policy at a stable public URL:
      `https://atomictrxn.github.io/crosscue/privacy.html`
- [x] In-app `Settings → Privacy & Data → Privacy policy` opens the public
      URL via `url_launcher` (see [privacy_screen.dart](crosscue/lib/features/settings/presentation/screens/privacy_screen.dart)).
- [x] Privacy policy URL filed in Play Console → App Content → Privacy Policy.

### Play Console — Data Safety form
Crosscue current-release answers:

| Question | Answer |
|----------|--------|
| Data collected? | No |
| Data types | None collected by Crosscue |
| Shared with third parties? | No |
| Encrypted in transit? | Not applicable |
| Users can request deletion? | Yes |
| Required for core function? | Not applicable |

### App content & targeting
- [x] Confirmed app is **not** targeted at children under 13 in the store listing.
- [x] Play Console → App Content → Target Audience completed.
- [x] Data Safety form filed in Play Console (answers above).
- [x] `android:hasFragileUserData="true"` set on the application in
      [AndroidManifest.xml](crosscue/android/app/src/main/AndroidManifest.xml)
      so Android 10+ offers the user a data-preservation prompt on uninstall.

### Release build hardening
- [x] R8 / resource shrinking enabled for the release build type in
      [build.gradle.kts](crosscue/android/app/build.gradle.kts); app-level
      keep rules live in `android/app/proguard-rules.pro`. Always smoke-test
      a release APK (`flutter build apk --release`) and install it on a
      device before tagging a release — minification can break plugin
      reflection in ways debug builds will not catch.

### Release pipeline
- [x] `.github/workflows/release.yml` builds a signed AAB and uploads to the
      Play Store internal track when triggered with `play_store: true`.
- [x] `PLAY_SERVICE_ACCOUNT_JSON` GitHub Secret added (Google Cloud service
      account with the Release Manager role on the Play Console). Verify
      with `gh secret list`.
- [ ] Use `workflow_dispatch` with `play_store: true` to trigger the first
      AAB upload to the internal track.

### Post-launch updates required if scope changes
- Re-review and update privacy policy + Data Safety form before adding analytics,
  notifications, remote crash reporting, or any new data collection
- GDPR/UK GDPR review required before EU/UK distribution if remote data
  collection is introduced

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

### Dark-mode QA checklist

Toggle `Settings → Theme → Dark` (or set the system theme) and walk every
screen before tagging a release. Direct `CrosscueColors.*Light` /
`CrosscueColors.*Dark` references are forbidden outside the theme files
(see [design_tokens.dart](crosscue/lib/core/theme/design_tokens.dart)); always
read theme-aware tokens via `context.crosscue*` or `Theme.of(context).cw`
(`CrosswordTheme`).

Acceptable exceptions (intentional brand-fixed colors):

| Location | Rationale |
|----------|-----------|
| Completion sheet barrier (`barrierDeepNavy`) | Brand celebration color, identical in both themes. |
| Confetti palette (`confettiPalette`) | Fixed 4-color brand palette. |
| Completed-cell green (`completedCellBg`, `completedCellFg`) | Celebration accent — green-on-green stays bright in both themes. |
| Onboarding `_AddPuzzleIllustration` | Mock of the light Today screen; explicit light-mode tokens by design. |
| Difficulty palette in stats (`primary`, hardcoded green/orange) | Fixed category palette, not theme-derived. |

Screens to verify in both light + dark:

| Screen | Things to confirm |
|--------|-------------------|
| Home / Today | Streak counter, "Past puzzles" rows, FAB contrast. |
| Solve screen | Grid borders, keyboard letter contrast, clue panel rows (active/cross/referenced highlights), pause overlay. |
| Completion sheet | Drag handle, time label, divider lines, PB row, share/view/reset buttons. |
| Archive | Filter chips, progress-pie track, list-tile metadata text. |
| Stats | Section headers, difficulty bars, completion-rate ring. |
| Settings + Privacy | Row dividers, switches, destructive "Clear all data" tile. |
| Onboarding | Step dots, mock app-bar text, instruction card on navy backdrop. |

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
