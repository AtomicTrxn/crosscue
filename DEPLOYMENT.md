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

## Running the App on iOS

iOS development requires macOS with Xcode + CocoaPods. Android sections above
use ADB and emulators; iOS uses `xcrun simctl` and the Simulator app.

### Boot a simulator

```bash
xcrun simctl list devices available | grep -iE "iPhone 17 Pro Max|iPad Pro 13"
xcrun simctl boot <udid>
open -a Simulator
```

### Run with hot-reload

Same as Android — just specify the iOS device UDID (or device name; `flutter
devices` lists everything visible):

```bash
cd crosscue && flutter run --debug -d <udid>
```

`r` / `R` / `q` work the same as Android.

### Build and install manually

```bash
cd crosscue
flutter build ios --debug --no-pub --simulator    # Runner.app for simulators
flutter build ipa --release                        # signed IPA for TestFlight

xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted dev.tomhess.crosscue
```

Release IPAs are signed for App Store distribution and can only be installed
via TestFlight or the App Store, not directly on a simulator.

### Open in Xcode for breakpoints / signing

```bash
open crosscue/ios/Runner.xcworkspace
```

Always use `.xcworkspace`, not `.xcodeproj` — CocoaPods integration requires
the workspace.

### Capturing iOS logs

Live stream from a simulator:
```bash
xcrun simctl spawn booted log stream --level debug \
  --predicate 'subsystem == "dev.tomhess.crosscue"'
```

For physical devices, use Console.app (filter by device + process "Runner")
or `idevicesyslog` from libimobiledevice.

### Common iOS pitfalls

- **`No Accounts` / `No profiles for ...` during archive** — the Release config
  uses manual signing pinned to the `Crosscue App Store` provisioning profile.
  Local Release builds require the profile installed at
  `~/Library/MobileDevice/Provisioning Profiles/`. Debug and Profile use
  automatic signing and just need your Apple ID in Xcode → Settings → Accounts.
- **`Cannot find 'ICloudSyncHandler' in scope`** — `ICloudSyncHandler.swift`
  must be registered in `Runner.xcodeproj` (`PBXBuildFile`, `PBXFileReference`,
  Runner group, and Sources build phase). See commit `c4c1e39`.
- **`NSProcessInfo.isiOSAppOnVision` not found** — `device_info_plus` 12.4.0
  uses an iOS 17 SDK symbol. Make sure local Xcode is 15+; the release
  workflow pins via `maxim-lobanov/setup-xcode@v1`.
- **CocoaPods flapping `inputPaths`/`outputPaths` in `Runner.xcodeproj/project.pbxproj`**
  — benign noise from CocoaPods regenerating build phase metadata. Don't
  commit; revert or ignore.
- **`Provisioning profile doesn't support the iCloud capability`** — the App ID
  has iCloud capability enabled with "Xcode 6 / CloudKit-compatible" mode but
  the profile was issued before that change. Re-issue the profile in the
  Apple Developer portal and update `APPLE_PROVISIONING_PROFILE_BASE64`.

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

## Integration Tests

Widget-level unit tests live under `crosscue/test/`. End-to-end tests that drive
the real app on a connected simulator or device live under
`crosscue/integration_test/` and use the [`integration_test`](https://docs.flutter.dev/cookbook/testing/integration/introduction)
package.

| File | What it covers |
|------|----------------|
| `integration_test/app_launch_test.dart` | Launch smoke test — boots the app, asserts MaterialApp renders, no error-screen text leaks. ~6 s on warm cache. |
| `integration_test/seed_and_solve_test.dart` | Seeds a 3×3 puzzle via the production `ImportRepository`, bypasses onboarding through `appSettingsProvider`, navigates home → solve, asserts the solve screen renders (clues, keyboard, timer). ~20 s on warm cache. |
| `integration_test/rebus_and_navigation_test.dart` | Rebus entry via the cell long-press menu, then router-driven navigation to Stats and Settings (QA checklist §4/§6/§7). |
| `integration_test/lifecycle_and_theme_test.dart` | Background/resume persistence and a live dark-mode toggle from Settings (QA checklist §5/§8). |

### Running

`scripts/run-ios-integration-tests.sh` boots a simulator, runs **every**
`integration_test/*_test.dart`, and drops a screenshot per test into
`design/qa/ios-<git-sha>/`:

```bash
scripts/run-ios-integration-tests.sh             # auto-picks/boots a simulator
scripts/run-ios-integration-tests.sh "iPhone 16" # or a name / UDID
```

The same suite runs on demand in CI via the **Integration tests (iOS)**
workflow (`.github/workflows/integration-test-ios.yml`, `workflow_dispatch`
only — it's costly, so it's not part of the per-PR gate).

To run a single test by hand:

```bash
cd crosscue
xcrun simctl list devices available | grep -i "iPhone"
xcrun simctl boot <udid>
open -a Simulator
flutter test integration_test/seed_and_solve_test.dart -d <udid>
```

### Running on Android (single test)

```bash
emulator -avd <avd-name> &
flutter test integration_test/<file>.dart -d <android-device-id>
```

### Conventions

- **Never use `pumpAndSettle`.** Crosscue has long-running Riverpod listeners
  (stats stream, solve timer) that keep the widget tree from going idle — the
  default 10-minute timeout will fire. Use a fixed-budget pump helper:
  ```dart
  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    const slice = Duration(milliseconds: 200);
    final ticks = (total.inMilliseconds / slice.inMilliseconds).ceil();
    for (var i = 0; i < ticks; i++) {
      await tester.pump(slice);
    }
  }
  ```
- **Bypass onboarding programmatically** rather than tapping Skip — the
  tutorial keyboard widget held focus that didn't release cleanly on dismiss
  in earlier integration runs. Set the flag via
  `appSettingsProvider.setHasSeenOnboarding(true)` and invalidate
  `hasSeenOnboardingProvider`.
- **TAG every step** with `debugPrint('TAG step=N ...')`. The framework's
  generic `_pendingExceptionDetails != null` failure hides underlying
  exceptions; TAG checkpoints let you locate exactly which step bumped
  the framework's error queue.
- **Restore the test binding's `FlutterError.onError` after `app.main()`.**
  The app installs its own crash handler, which otherwise swallows the real
  failure and surfaces only the opaque `_pendingExceptionDetails` assertion.
  Save `FlutterError.onError` before `app.main()` and reassign it after.
- **Never `pump()` while the app is `paused`.** In the live integration
  binding the paused engine stops servicing frames, so the pump hangs forever.
  Drive lifecycle states (`inactive → hidden → paused` and back) without a
  pump between them — observers fire synchronously, so state is assertable
  without a frame.
- **Navigate by route, not by tapping "featured" UI.** The featured puzzle is
  non-deterministic across sim reruns. Push by id via
  `ref.read(appRouterProvider).push(Routes.solveFor(...))`, and read the live
  `solveProvider` family key off the open `SolveScreen` widget (go_router
  decodes the path param, so it differs from the encoded value you pushed).

### Coverage

The four integration tests above cover QA-checklist sections 1, 3, 4, 5, 6,
and 7 (partially). Sections requiring a human on a real device — share-sheet
import (§2), Dynamic Type (§8), iPad multitasking (§9), edge cases (§10), and
true force-quit — remain a manual pass via
[`docs/qa/ios-release-checklist.md`](docs/qa/ios-release-checklist.md). See
[#106](https://github.com/AtomicTrxn/crosscue/issues/106) (closed) for the
build-out history.

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
targeting `main`. Merge only after CI is green.

Remote: use the repository's configured `origin` URL (`git remote -v`).

### CI coverage

`.github/workflows/ci.yml` emits two required checks on pull requests
targeting `main`:

```
Static checks   format → analyze → generated files
Test            flutter test
```

| Check | App-affecting change | Documentation-only change |
|-------|----------------------|---------------------------|
| **Static checks** | `flutter pub get` → format → analyze → generated files | reports success without Flutter setup |
| **Test** | `flutter pub get` → `flutter test` | reports success without Flutter setup |

All app checks use Flutter `3.41.9`. CI does not build an APK — release
artifacts are produced by the release workflow against an explicit tag.

---

## Release Pipeline

Releases are dispatch-only — pushing a tag does **not** publish anything.
You tag the commit, then run the **Release** workflow against that tag. A
single dispatch builds both platforms in parallel and publishes one
GitHub Release with both artifacts attached.

| `test_flight` | `play_store` | Builds | Publishes |
|---------------|--------------|--------|-----------|
| `true` (default) | `false` (default) | Signed APK + signed IPA | GitHub Release w/ both files + IPA to TestFlight |
| `true` | `true` + `track` | + signed AAB | + AAB to the chosen Play Store track |
| `false` | `false` | APK only | GitHub Release w/ APK; iOS job skipped |
| `false` | `true` + `track` | APK + AAB | GitHub Release w/ APK; AAB to Play Store; no IPA |

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

**Android:**

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` file (from the command above) |
| `KEY_ALIAS` | `crosscue` (or whatever alias you chose) |
| `KEY_PASSWORD` | The key password you entered |
| `STORE_PASSWORD` | The keystore password you entered |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Console service account JSON (used only when dispatching with `play_store: true`) |

**Android — Actions variables** (Settings → Secrets and variables → Actions →
**Variables**, not Secrets — these are not sensitive):

| Variable | Value |
|----------|-------|
| `GOOGLE_OAUTH_SERVER_CLIENT_ID` | Web OAuth client ID for Google Drive sign-in, passed to the APK/AAB builds as `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID`. Leave unset and Android sync stays inert (sign-in fails gracefully). The web client ID is public — embedded in every shipped app — so it's a variable, not a secret. Full setup: [`docs/architecture/sync-googledrive-setup.md`](docs/architecture/sync-googledrive-setup.md). |

**iOS:**

| Secret | Value |
|--------|-------|
| `APPLE_DEVELOPER_CERTIFICATE_BASE64` | `base64 -i path/to/Distribution.p12 \| pbcopy` |
| `APPLE_DEVELOPER_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | `base64 -i path/to/Crosscue_App_Store.mobileprovision \| pbcopy` |
| `APPLE_API_KEY` | Base64-encoded App Store Connect API `.p8` private key (`base64 -i AuthKey_XXXX.p8 \| pbcopy`) |
| `APPLE_API_KEY_ID` | The key's 10-character Key ID (e.g. `ABC123DEF4`) |
| `APPLE_API_ISSUER_ID` | The Issuer ID (UUID) shown above the keys list in App Store Connect |

The TestFlight upload authenticates with the App Store Connect API key trio
(`APPLE_API_KEY` / `APPLE_API_KEY_ID` / `APPLE_API_ISSUER_ID`) rather than an
Apple ID + app-specific password — scoped role, individually revocable. The
old `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, and `APPLE_DEVELOPMENT_TEAM_ID`
secrets are no longer read by `release.yml` (the team ID is hardcoded in the
`ExportOptions.plist` step); they can be deleted from the repo secrets once
this is merged.

### One-time setup: iOS (Apple Developer portal + App Store Connect)

1. **Apple Developer Program enrollment** ($99/year) under team `ZS9BL7472D`.
2. **App ID `dev.tomhess.crosscue`** registered in
   https://developer.apple.com/account/resources/identifiers/list with iCloud
   capability enabled in **Xcode 6 / CloudKit-compatible mode** (not "Xcode 5
   Compatible" — the modern entitlement set is required because
   `Runner.entitlements` declares `com.apple.developer.icloud-services`).
3. **iCloud Container `iCloud.dev.tomhess.crosscue`** created and linked
   to the App ID.
4. **iOS Distribution certificate** generated and exported as `.p12` with a
   strong password.
5. **App Store provisioning profile** `Crosscue App Store` issued against the
   App ID **after** the iCloud capability is enabled. Re-issue (and update
   the `APPLE_PROVISIONING_PROFILE_BASE64` secret) any time the App ID's
   capability set changes.
6. **App Store Connect API key** at
   https://appstoreconnect.apple.com/access/integrations/api → Team Keys.
   Create a key with the **App Manager** role, download the `.p8` once (it is
   not re-downloadable), and capture the Key ID and the Issuer ID. Populate
   the `APPLE_API_KEY` (base64 of the `.p8`), `APPLE_API_KEY_ID`, and
   `APPLE_API_ISSUER_ID` secrets.
7. **App Store Connect app record** for bundle `dev.tomhess.crosscue` at
   https://appstoreconnect.apple.com/apps. TestFlight uploads will fail with
   `Cannot determine the Apple ID from Bundle ID` until this exists.

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

1. **Bump the version on main** via a PR. Edit `crosscue/pubspec.yaml`:
   ```yaml
   version: 1.2.3+10203   # name+code; code follows the formula below
   ```
   Open a PR, let CI pass, merge.

2. **Tag the merge commit on main** and push the tag:
   ```bash
   git checkout main && git pull
   git tag v1.2.3
   git push origin v1.2.3
   ```
   The tag is just a marker — pushing it does **not** trigger a build.

3. **Dispatch the Release workflow** from the GitHub Actions UI (or via
   `gh workflow run`):
   ```bash
   # Default: APK + IPA + GitHub Release + TestFlight (Android-only on GH Release):
   gh workflow run release.yml -f tag=v1.2.3

   # Default + Play Store internal testing:
   gh workflow run release.yml -f tag=v1.2.3 -f play_store=true -f track=internal

   # Android-only emergency patch (skip iOS):
   gh workflow run release.yml -f tag=v1.2.3 -f test_flight=false
   ```

The workflow checks out the **tag** (not whatever branch you dispatched
from), so main can move between tagging and dispatch without affecting the
build.

**Release title:** the workflow publishes `Crosscue v1.2.3`. Keep release
context in the generated release body rather than overloading the title.

**Version code formula:** `major × 10000 + minor × 100 + patch`
- `v1.0.0` → `10000`
- `v1.1.0` → `10100`
- `v1.0.3` → `10003`

### Play Store tracks

Available tracks: `internal` (default — internal testing, no review),
`alpha` (closed testing), `beta` (open testing), `production`.

The Play Store upload requires the `PLAY_SERVICE_ACCOUNT_JSON` secret for a
Play Console service account that has the app-level permissions needed for
the chosen track. For `internal` or `alpha`, that means at least **Release
apps to testing tracks**; add broader production permissions only when the
workflow is meant to publish to production.

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

> **Re-confirm before Android (Google Drive) sync goes live.** These answers
> stay accurate while Drive sync is inert: the *developer* collects nothing —
> synced data goes to the user's own Google Drive AppData folder, never to a
> Crosscue server (same model already accepted for iCloud). But before the
> Android sync default-on flip (tracked in
> [#176](https://github.com/AtomicTrxn/crosscue/issues/176)), deliberately
> re-review the Data Safety form: confirm Google Play still treats "stored in the
> user's own Drive via the `drive.appdata` scope" as *not collected/not shared*,
> and update the answers + privacy policy if that interpretation has changed.

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
      selected Play Store track when dispatched with `play_store: true`.
- [x] `PLAY_SERVICE_ACCOUNT_JSON` GitHub Secret added for the Play Console
      service account. For `internal` or `alpha` tracks, grant app-level
      **Release apps to testing tracks** permission. Verify the secret exists
      with `gh secret list`.
- [x] First AAB upload to a testing track completed via `workflow_dispatch`
      with `play_store: true`.

### Post-launch updates required if scope changes
- Re-review and update privacy policy + Data Safety form before adding analytics,
  notifications, remote crash reporting, or any new data collection
- GDPR/UK GDPR review required before EU/UK distribution if remote data
  collection is introduced

---

## App Store Submission Checklist

Complete these steps before submitting to the App Store for the first time.
Human review is required before publishing — this is not legal advice.

### Privacy policy (required before submission)
- [x] Published at `https://atomictrxn.github.io/crosscue/privacy.html`.
- [x] In-app Settings → Privacy & Data → Privacy policy opens it via `url_launcher`.
- [x] URL filed in App Store Connect → App Privacy.

### App Store Connect — App Privacy form
Crosscue current-release answers (mirrors Play Console):

| Question | Answer |
|----------|--------|
| Do you or your third-party partners collect data from this app? | No |
| Data Types | None |
| Data Used to Track You | None |
| Data Linked to User | None |
| Data Not Linked to User | None |

### Export Compliance
- [x] `ITSAppUsesNonExemptEncryption = false` in `crosscue/ios/Runner/Info.plist`.
      The only crypto in the app is SHA-256 hashing of imported puzzle bytes to
      derive content-addressable IDs — exempt from EAR encryption export
      controls. This flag bypasses the encryption questionnaire on every
      TestFlight upload after it lands in the build.

### Visual assets

Source PNGs are versioned under `design/store/ios/` so they can be refreshed
or diffed against future releases:

| App Store Connect slot | Source folder | Dimensions |
|------------------------|---------------|------------|
| 6.7-Inch Display (iPhone) | `design/store/ios/iphone-6.7/` | 1284 × 2778 |
| 12.9-Inch Display (iPad) | `design/store/ios/ipad-12.9/` | 2048 × 2732 |

Apple downscales the 6.7" set for all smaller iPhone classes and the 12.9"
set for smaller iPad classes — no need to upload duplicate sets unless you
want to override the auto-scale.

> **Why not the newer 6.9" / 13" sizes?** Captures from iPhone 17 Pro Max
> (1320 × 2868) and iPad Pro M5 13" (2064 × 2752) are rejected by the
> current App Store Connect upload UI, which only accepts up to
> 1284 × 2778 / 2048 × 2732. If/when Apple adds dedicated 6.9" / 13" slots,
> re-capture on the newer simulators (`iPhone 17 Pro Max` / `iPad Pro 13-inch
> (M5)`) — the existing files in this folder were resized from those
> captures, so a recapture replaces them exactly.

Per-version release notes live as `design/store/ios/release-notes-X.Y.Z.txt`.

App preview videos are optional. Skip for v1.0; reconsider for v1.1+.

### Age rating
Answer "None" to every question in the App Store Connect questionnaire →
result is **4+**.

### Release pipeline
- [x] `.github/workflows/release.yml` `ios` job builds and uploads a signed
      `.ipa` to TestFlight via `xcrun altool` (authenticated with an App Store
      Connect API key) on macos-latest with Xcode pinned via
      `maxim-lobanov/setup-xcode@v1`.
- [x] `APPLE_*` secrets configured (see Release Pipeline § One-time setup).
- [x] First IPA upload to TestFlight completed via `workflow_dispatch` with
      `test_flight: true` (the default).
- [x] App Store Connect app record exists for bundle `dev.tomhess.crosscue`.

### Post-launch updates required if scope changes
- Re-review and update the privacy policy + App Privacy form before adding any
  analytics, push notifications, or remote data collection.
- Regenerate the App Store provisioning profile (and update
  `APPLE_PROVISIONING_PROFILE_BASE64`) whenever the App ID's capability set
  changes — e.g. enabling Push Notifications, adding a new iCloud container.
- Rotate the App Store Connect API key (`APPLE_API_KEY` / `APPLE_API_KEY_ID` /
  `APPLE_API_ISSUER_ID`) if it leaks or before broadening repo access — keys
  have scoped roles and can be revoked individually in App Store Connect.

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
Supported local puzzle formats (`.puz` and `.ipuz`) have no registered MIME
types on Android. Using `FileType.custom` with those extensions produces an
empty MIME list and throws a `PlatformException` that leaves the UI stuck in
the picking state.

**Fix:** Use `FileType.any` and validate the extension client-side:
```dart
result = await FilePicker.platform.pickFiles(
  type: FileType.any,   // NOT FileType.custom
  withData: true,
);
// Then:
final ext = file.extension?.toLowerCase() ?? '';
if (!{'puz', 'ipuz'}.contains(ext)) { ... }
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
| Revealed-cell amber (`revealedCellBg`) | Provenance state, intentionally fixed across themes. |
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
