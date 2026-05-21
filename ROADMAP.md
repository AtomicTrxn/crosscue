# Crosscue Roadmap

Durable follow-up trail for the project. Move items here only when they are
still worth tracking after the current cleanup pass.

## Backlog

- Continue revamping `onboarding_screen.dart` when that flow gets broader
  product/design attention.
- **Integration test suite expansion** — PRs 3-5 of
  [#106](https://github.com/AtomicTrxn/crosscue/issues/106). Cover grid-cell
  taps + letter input + rebus, app-lifecycle persistence and dark-mode
  toggle, and a `scripts/run-ios-integration-tests.sh` runner wired into
  optional CI. PRs 1 & 2 already landed and exercise launch + home → solve.
- **iCloud sync in-app UI** — [issue #9](https://github.com/AtomicTrxn/crosscue/issues/9).
  The Dart transport + Swift handler ship and the Apple-side
  entitlements / container were configured during iOS 1.0. The UI
  surface to actually opt users in is the remaining work.
- **Migrate altool to App Store Connect API key** — replace
  `APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD` in `release.yml` with
  `APPLE_API_KEY + APPLE_API_KEY_ID + APPLE_API_ISSUER_ID`. Better
  scoping + revocation; recommended before broadening repo access.

## Recently closed — iOS 1.0 launch

Milestone [`iOS 1.0 Release`](https://github.com/AtomicTrxn/crosscue/milestone/2)
finished during the v1.2.7 release push:

- Apple Developer enrollment, App ID, distribution cert, App Store
  provisioning profile (regenerated for iCloud entitlements), App Store
  Connect app record (#89, #91).
- macOS-runner release workflow — signed `.ipa` archived, IPA + APK both
  attached to the GitHub Release, IPA uploaded to TestFlight; one
  dispatch ships both platforms (#90, PR #102, PR #104).
- App Store Connect listing: subtitle, description, keywords, privacy
  form, age rating, category, support URL, export compliance
  (`ITSAppUsesNonExemptEncryption = false` in `Info.plist`).
- Visual assets versioned under `design/store/ios/iphone-6.7/` (1284×2778)
  and `design/store/ios/ipad-12.9/` (2048×2732), plus release notes
  (#92).
- README + DEPLOYMENT.md cross-platform; new `docs/qa/ios-release-checklist.md`
  (#94, #93).
- Integration test scaffold landed — `integration_test/app_launch_test.dart`
  and `integration_test/seed_and_solve_test.dart` (PRs 1 & 2 of #106).
  Surfaced and fixed two real prod bugs along the way:
  `ICloudSyncHandler.swift` not registered in `Runner.xcodeproj`
  (`c4c1e39`) and `SolveScreenState.dispose` calling `ref.read` on an
  unmounted element (`7e4675f`). Rebus modal red-screen (#105) fixed
  via PR #107.

## Recently closed from the review pass

- Removed duplicate annotations and hot-path RegExp allocations.
- Centralized archive status presentation and shared Home/Archive puzzle rows.
- Moved solve-side effects out of `build` and switched archive/home data to
  reactive Drift streams.
- Split solve screen widgets and moved grid mutation helpers into domain code.
- Finished the theme-token cleanup for the reviewed screens.
- Replaced production `print` calls with app logging/reporting.
- Made route usage guardable with a test instead of relying on convention only.
- Split `crossword_grid.dart` into layout, input handling, and cell-effect
  animation parts.
- Back navigation on branch-root screens — no longer needed; deferred
  indefinitely.
- Mirrored import test structure: moved `crosshare_downloader_test.dart` to
  `data/downloaders/` and `source_registry_test.dart` to `data/sources/`.
