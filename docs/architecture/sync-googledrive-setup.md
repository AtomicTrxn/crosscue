# Google Drive sync — one-time setup (Android)

The Android counterpart to [`sync-icloud-setup.md`](sync-icloud-setup.md).
`GoogleDriveSyncTransport` (`core/sync/transport/google_drive_sync_transport.dart`)
stores blobs in the app's hidden **AppData** folder via the Drive API. Until
the Google Cloud OAuth client below exists, sign-in fails gracefully and the
transport stays in `SyncSignedOut` (no-op) — so the code ships safely without
this, it just doesn't *do* anything yet.

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

3. **Android OAuth 2.0 Client ID** (Credentials → Create credentials → OAuth
   client ID → Android)
   - **Package name:** `dev.tomhess.crosscue`
   - **SHA-1 certificate fingerprint** — add one client per signing key:
     - **Debug:**
       ```
       keytool -list -v -keystore ~/.android/debug.keystore \
         -alias androiddebugkey -storepass android -keypass android
       ```
     - **Release / upload key:** from your release keystore, e.g.
       ```
       keytool -list -v -keystore <release-keystore> -alias <alias>
       ```
       (If you use Play App Signing, also add the **App signing key** SHA-1
       from Play Console → Setup → App integrity.)

   No `google-services.json` is required — `google_sign_in` matches the OAuth
   client by package name + SHA-1.

## Notes

- Scope: `drive.appdata` only. The AppData folder is invisible in the user's
  Drive UI and isolated per app — the same trust model as the iCloud container.
- The interactive sign-in (`GoogleDriveSyncTransport.signIn()`) is now wired:
  the orchestrator's `enable()` calls it, and the Settings/onboarding toggle
  drives the Google prompt (#157). Until the OAuth client above exists the
  prompt fails gracefully and the transport stays inert — so the app ships
  safely; it just can't actually sign in yet.
