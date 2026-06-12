# Google Drive sync — one-time setup (Android)

> **Status:** Living — Google Cloud Console runbook; Android sync stays inert
> until these steps are done.

The Android counterpart to [`sync-icloud-setup.md`](sync-icloud-setup.md).
`GoogleDriveSyncTransport` (`core/sync/transport/google_drive_sync_transport.dart`)
stores blobs in the app's hidden **AppData** folder via the Drive API. Until
the Google Cloud OAuth clients below exist *and* the web client ID is wired in
(see step 4), sign-in fails gracefully and the transport stays in
`SyncSignedOut` (no-op) — so the code ships safely without this, it just
doesn't *do* anything yet.

Two OAuth clients are needed, because the app doesn't ship a
`google-services.json`:

- an **Android** client (package name + signing SHA-1) — identifies the app, and
- a **Web application** client — its ID is passed to `google_sign_in` as
  `serverClientId` (required on Android for `authenticate()`; see the plugin's
  README). The web client ID is **not** a secret — it's embedded in every
  shipped app — so it's fine to put in a build flag / CI variable.

## What you need to do (Google Cloud Console)

1. **Project + API**
   - Create or pick a Google Cloud project.
   - **APIs & Services → Library → enable the Google Drive API.**

2. **OAuth consent screen**
   - User type **External**. Fill in app name, support email, developer email.
   - **Scopes → add** `https://www.googleapis.com/auth/drive.appdata` (the
     hidden per-app folder — not the broad Drive scope).
   - While the app is unverified the consent screen stays in **Testing**: add
     your tester Google accounts under **Test users** (only they can sign in).
     Use `atomhess@gmail.com` (the project's personal account) at minimum.

3. **OAuth 2.0 Client IDs** (APIs & Services → Credentials → Create credentials
   → OAuth client ID). Create **both**:

   a. **Android** client
      - **Package name:** `dev.tomhess.crosscue`
      - **SHA-1 certificate fingerprint** — add one Android client per signing
        key you want to work:
        - **Debug** (for `flutter run` on a device/emulator — already known):
          ```
          6B:25:E8:37:4C:F0:0E:82:1F:10:A0:82:A8:57:D2:BA:4E:F9:73:5C
          ```
          (Regenerate any time with:
          `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`)
        - **Play App Signing** (for Play-distributed builds — the cert Google
          re-signs with): Play Console → **Test and release → Setup → App
          integrity → App signing key certificate → SHA-1**.
        - **Upload key** (the key the AAB is signed with before upload): Play
          Console → same **App integrity** page → **Upload key certificate →
          SHA-1**. (Equivalently, from the release keystore:
          `keytool -list -v -keystore <release.jks> -alias <alias>`.)

   b. **Web application** client
      - No redirect URIs are needed for the mobile flow.
      - **Copy its Client ID** — this is the `serverClientId` for step 4. It
        looks like `1234567890-abc...def.apps.googleusercontent.com`.

4. **Wire the web client ID into the app** (`serverClientId`)

   The transport reads it from a compile-time define
   `GOOGLE_OAUTH_SERVER_CLIENT_ID` (empty → inert). Supply it at build time:

   - **Local run / debug:**
     ```
     flutter run --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<web-client-id>
     ```
   - **Release CI:** set a repo **Actions variable** (not a secret — it's
     public) named `GOOGLE_OAUTH_SERVER_CLIENT_ID`
     (GitHub → repo → Settings → Secrets and variables → Actions → Variables).
     `release.yml` already passes it to both the APK and AAB builds.

## Notes

- Scope: `drive.appdata` only. The AppData folder is invisible in the user's
  Drive UI and isolated per app — the same trust model as the iCloud container.
- The interactive sign-in (`GoogleDriveSyncTransport.signIn()`) is wired: the
  orchestrator's `enable()` calls it, and the Settings/onboarding toggle drives
  the Google prompt (#157). It needs **both** OAuth clients above plus the
  `serverClientId` define; missing any of them makes `authenticate()` fail (the
  Android Credential Manager often reports this as a "canceled" error), and the
  transport stays inert.
- No `google-services.json` is required — `google_sign_in` matches the Android
  client by package name + SHA-1, and uses the web client ID only as the
  `serverClientId`.
