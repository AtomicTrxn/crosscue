# Challenge-board invite deep links

Plumbing for `https://crosscue.app/join/<boardId>?token=<secret>` invite links
(issues #203 / #159). These open the installed app directly via **Android App
Links** and **iOS Universal Links** — no Firebase Dynamic Links.

## What lives where

| Concern | Location |
|---------|----------|
| Parse / validate invite URIs | `crosscue/lib/features/challenge_boards/util/invite_link.dart` |
| Route: `/join/:boardId` → `/challenge/join?board=&token=` | `crosscue/lib/core/routing/app_router.dart` |
| Auto-launch preview→confirm→join | `crosscue/lib/features/challenge_boards/presentation/screens/challenge_boards_screen.dart` |
| Android App Links intent-filter + `autoVerify` | `crosscue/android/app/src/main/AndroidManifest.xml` |
| iOS Associated Domains + `FlutterDeepLinkingEnabled` | `crosscue/ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist` |
| Hosted association files + web fallback | this directory |

## Hosting on `crosscue.app` (Cloudflare)

Serve these from the apex domain:

- `.well-known/apple-app-site-association` → `https://crosscue.app/.well-known/apple-app-site-association`
  - **Content-Type: `application/json`**, served over HTTPS, **no redirect**, no `.json` extension.
- `.well-known/assetlinks.json` → `https://crosscue.app/.well-known/assetlinks.json`
  - **Content-Type: `application/json`**.
- `join.html` → rendered for `https://crosscue.app/join/*` requests **from browsers without the app** (installed apps intercept the URL before the page loads). Keep the `boardId`/`token` in the URL so the user can retry after install.

## ⚠️ Before this works on devices

1. **Android — fill the signing fingerprint.** Replace
   `REPLACE_WITH_PLAY_APP_SIGNING_SHA256_FINGERPRINT` in `assetlinks.json` with
   the **SHA-256** of the cert that actually signs the shipped app:
   - Play App Signing: Play Console → *Release → Setup → App signing* → SHA-256.
   - Local keystore: `keytool -list -v -keystore <ks> -alias <alias>` → SHA256.
   You may list multiple fingerprints (e.g. upload + Play signing).

2. **iOS — provisioning.** The `applinks:crosscue.app` Associated Domains
   entitlement requires the App ID to have the *Associated Domains* capability
   and the provisioning profile re-issued (same caveat as the widget App
   Groups). `appID` in the AASA is `<TeamID>.<bundleId>` =
   `ZS9BL7472D.dev.tomhess.crosscue`.

3. **Backend.** The join itself depends on the challenge Worker being deployed
   and `CHALLENGE_API_BASE_URL` injected at build (#198); until then the app
   runs the join flow against sample data.

## QA matrix (device)

| State | iOS (Universal Link) | Android (App Link) |
|-------|----------------------|--------------------|
| Installed, app cold | opens app → board preview | opens app → board preview |
| Installed, app warm | routes in place | routes in place |
| Not installed | `join.html` fallback | `join.html` fallback |
| Malformed/foreign link | lands on Challenge tab | lands on Challenge tab |

Verify Android with
`adb shell am start -a android.intent.action.VIEW -d "https://crosscue.app/join/abc?token=xyz"`
and iOS with a Notes-app link tap (Universal Links don't fire from Safari's
address bar).
