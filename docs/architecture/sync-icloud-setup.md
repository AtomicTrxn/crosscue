# iCloud sync — one-time iOS setup

> Reader: developer / release engineer activating the sync feature
> (issue [#9](https://github.com/AtomicTrxn/crosscue/issues/9), marked
> deferred). Design: [`sync-design.md`](sync-design.md). Status:
> [`sync-progress.md`](sync-progress.md).

The Dart side and the Swift `ICloudSyncHandler` already ship. The build
compiles and runs cleanly on iOS without sync activating —
`ICloudSyncTransport.account()` returns null and the orchestrator stays
in `SyncSignedOut` until both the Apple-side configuration AND an in-app
opt-in are in place.

**Apple-side status as of iOS 1.0 (v1.2.7):** steps 1, 2, and 3 below
were completed during the v1.2.7 release push — the App ID has iCloud
capability enabled (Xcode 6 / CloudKit-compatible mode), the iCloud
container `iCloud.dev.tomhess.crosscue` exists, and the App Store
provisioning profile carries the modern `icloud-services` +
`icloud-container-identifiers` + `ubiquity-container-identifiers`
entitlements. The `APPLE_PROVISIONING_PROFILE_BASE64` GitHub Secret
holds the regenerated profile. Verify with:

```bash
security cms -D -i /path/to/Crosscue_App_Store.mobileprovision \
  | grep -A1 -E "icloud-container-identifiers|icloud-services|ubiquity-container-identifiers"
```

**What's still pending:** the in-app UI to actually let users sign in
to iCloud sync. The transport is dormant by design — when issue #9
moves from deferred to in-flight, the steps below stay as the
on-ramp reference. The verification section at the bottom is what
you'd run end-to-end when the in-app UI ships.

This guide walks through the three things that *must* happen on the
Apple side before sync can activate, plus how to verify it end-to-end.

## Prerequisites

- Active Apple Developer Program membership ($99/yr).
- App's bundle identifier registered in
  [developer.apple.com → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
  (currently `dev.tomhess.crosscue`).
- An iCloud-signed-in iOS device or simulator.

## Step 1 — Create the iCloud container

1. developer.apple.com → **Identifiers** → **+** → **iCloud Containers**.
2. Description: `Crosscue Sync`.
3. Identifier: `iCloud.dev.tomhess.crosscue` (the `iCloud.` prefix is
   mandatory; the rest matches the app's bundle id).
4. Continue → Register.

This container is what the app reads/writes under
`<container>/Documents/sync/`.

## Step 2 — Attach the container to the App ID

1. Identifiers → click `dev.tomhess.crosscue`.
2. Scroll to **iCloud** → check **Enable**.
3. **Edit** → check the `iCloud.dev.tomhess.crosscue` container created in
   Step 1.
4. Save.
5. Regenerate provisioning profiles if your CI uses pinned profiles
   (Xcode-managed signing picks up the change automatically).

## Step 3 — Add the capability in Xcode

1. Open `crosscue/ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** → **iCloud**.
4. Under **Services**, check **iCloud Documents**.
5. Under **Containers**, check `iCloud.dev.tomhess.crosscue`.

Xcode creates `Runner/Runner.entitlements` and adds the
`CODE_SIGN_ENTITLEMENTS` build setting to `Runner.xcodeproj` for both Debug
and Release configurations. The resulting entitlements file looks like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.icloud-container-identifiers</key>
  <array>
    <string>iCloud.dev.tomhess.crosscue</string>
  </array>
  <key>com.apple.developer.icloud-services</key>
  <array>
    <string>CloudDocuments</string>
  </array>
  <key>com.apple.developer.ubiquity-container-identifiers</key>
  <array>
    <string>iCloud.dev.tomhess.crosscue</string>
  </array>
</dict>
</plist>
```

Commit both files (`Runner.entitlements` and the modified `project.pbxproj`).

## Step 4 — Verify

On a device or simulator signed into iCloud, with **Settings → Apple ID →
iCloud → iCloud Drive → Crosscue** turned on:

```dart
// In a debug build or quick test screen:
final transport = ref.read(syncTransportProvider);
final account = await transport.account();
debugPrint('account: $account');     // expect non-null
```

A non-null result means the handler can see the ubiquity token and the
container directory exists. From there, drive an end-to-end sync via the
orchestrator and confirm files appear in
`~/Library/Mobile Documents/iCloud~dev~tomhess~crosscue/Documents/sync/`
on the host Mac (for simulator) or in the cloud on a real device.

## Step 5 — Two-device soak (manual)

1. Install the build on Device A and Device B, both signed into the same
   iCloud account, both with iCloud Drive on for Crosscue.
2. On A, import a puzzle, solve it.
3. Trigger sync (foreground app, or the manual button once the settings
   screen lands in Phase 4).
4. On B, trigger sync. Assert the puzzle + completion show up.
5. Repeat with a session conflict: leave A's solve in progress, complete
   it on B, sync B → A. A's session should be replaced via the
   best-progress override (see `sync-design.md` → Conflict resolution).

## Rollback

If anything goes wrong, the sync feature is off-by-default at the
`SyncOrchestrator` level (`enable()` is never called automatically in
Phase 2). Even with the entitlement attached, no writes happen until the
Phase 4 settings UI lands or someone calls `enable()` from code.

To fully revoke: in Xcode → Signing & Capabilities, click the trash icon
next to the **iCloud** capability. Rebuild. The Swift handler reverts to
returning nil from `account()` immediately.
