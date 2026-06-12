# Challenge-board invite deep links

Plumbing for `https://crosscue.pages.dev/join/<boardId>?token=<secret>` invite
links (issues #203 / #159). These open the installed app directly via
**Android App Links** and **iOS Universal Links** — no Firebase Dynamic Links.

The `crosscue.app` apex was never registered; invite links are served from
Cloudflare Pages instead (free). Both hosts are wired everywhere (entitlement,
manifest, client parser), so the apex can be added later without breaking
already-shared `pages.dev` links.

## What lives where

| Concern | Location |
|---------|----------|
| Parse / validate invite URIs (`kInviteLinkHosts`) | `crosscue/lib/features/challenge_boards/util/invite_link.dart` |
| Route: `/join/:boardId` → `/challenge/join?board=&token=` | `crosscue/lib/core/routing/app_router.dart` |
| Auto-launch preview→confirm→join | `crosscue/lib/features/challenge_boards/presentation/screens/challenge_boards_screen.dart` |
| Android App Links intent-filter + `autoVerify` | `crosscue/android/app/src/main/AndroidManifest.xml` |
| iOS Associated Domains + `FlutterDeepLinkingEnabled` | `crosscue/ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist` |
| Invite-link generation host (`PUBLIC_APP_URL`) | `crosscue/backend/challenge_boards/wrangler.toml` |
| Hosted association files + web fallback | this directory |

## Hosting on Cloudflare Pages (`crosscue.pages.dev`)

This directory is deployed as-is as a Cloudflare Pages project named
`crosscue`, which yields the host `crosscue.pages.dev`. **If that project name
is taken**, pick another and update the host string in each centralized spot:
`kInviteLinkHosts` (Flutter), `PUBLIC_APP_URL` (wrangler.toml, three envs),
the Android manifest `<data>` element, and the iOS entitlement.

One-time setup, then deploy (both from the repo root):

```sh
npx wrangler pages project create crosscue --production-branch=main
npx wrangler pages deploy deeplinks --project-name=crosscue
```

What Pages serves:

- `.well-known/apple-app-site-association` →
  `https://crosscue.pages.dev/.well-known/apple-app-site-association`
  - Apple requires **Content-Type: `application/json`**, HTTPS, **no
    redirect**, no `.json` extension. The file is extensionless, so
    **`_headers`** forces the content type.
- `.well-known/assetlinks.json` →
  `https://crosscue.pages.dev/.well-known/assetlinks.json`
  - Served as `application/json` automatically (has the extension).
- `join.html` → rendered for `https://crosscue.pages.dev/join/*` requests
  **from browsers without the app** (installed apps intercept the URL before
  the page loads). **`_redirects`** contains a single 200 rewrite
  (`/join/* /join.html 200`) so any `/join/<boardId>` URL serves the fallback
  page while the `boardId`/`token` stay in the URL — the visitor can retry the
  same link after installing.

### Adding `crosscue.app` later

If/when the apex domain is registered, attach it as a Pages custom domain
(Pages project → *Custom domains* → add `crosscue.app`). The association
files, app entitlements, manifest, and client parser already list both hosts,
so old `pages.dev` invites keep working alongside apex ones; flip the Worker's
`PUBLIC_APP_URL` when the apex should become the generated host.

## ⚠️ Before this works on devices

1. **Android — fill the signing fingerprint.** Replace
   `REPLACE_WITH_PLAY_APP_SIGNING_SHA256_FINGERPRINT` in `assetlinks.json` with
   the **SHA-256** of the cert that actually signs the shipped app:
   - Play App Signing: Play Console → *Release → Setup → App signing* → SHA-256.
   - Local keystore: `keytool -list -v -keystore <ks> -alias <alias>` → SHA256.
   You may list multiple fingerprints (e.g. upload + Play signing).

2. **iOS — provisioning.** The Associated Domains entitlement
   (`applinks:crosscue.app` + `applinks:crosscue.pages.dev`) requires the App
   ID to have the *Associated Domains* capability and the provisioning profile
   re-issued (same caveat as the widget App Groups) — already in place since
   the 2026-06-12 dual-profile setup (#251). `appID` in the AASA is
   `<TeamID>.<bundleId>` = `ZS9BL7472D.dev.tomhess.crosscue`.

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
`adb shell am start -a android.intent.action.VIEW -d "https://crosscue.pages.dev/join/abc?token=xyz"`
and iOS with a Notes-app link tap (Universal Links don't fire from Safari's
address bar).
