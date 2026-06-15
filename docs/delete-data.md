<!--
  MAINTAINER NOTE (not part of the user-facing text): this file IS the published
  data-deletion page. GitHub Pages builds from main:/docs (Jekyll) and serves it
  as https://atomictrxn.github.io/crosscue/delete-data.html — the URL filed in
  Google Play Console → Data safety → "Delete data URL". It is deliberately a
  dedicated page (not a section of the privacy policy) because the Play review
  wants the deletion steps to be the prominent focus of the linked page. Keep it
  in sync with docs/privacy.md ("Data retention and deletion" / "Optional
  Challenge Boards"): when deletion behavior changes, update both, bump the
  effective date, and verify the live page before the next store submission —
  see DEPLOYMENT.md store checklists.
-->

# Delete your Crosscue data

**App:** Crosscue (crossword solver for iOS and Android)
**Developer:** Tom Hess (AtomicTrxn)
**Effective date:** June 15, 2026

This page explains how to delete the data Crosscue stores, what is deleted, what
is kept, and how long anything is retained. For the full picture of what
Crosscue does and does not collect, see the
[Privacy Policy](https://atomictrxn.github.io/crosscue/privacy.html).

Crosscue is offline-first and account-free: most of your data never leaves your
device. There is no account to delete. Depending on which optional features you
turned on, your data can live in up to three places, and you control all three.

## 1. Delete everything on your device (one step)

In the app:

**`Settings → Privacy & Data → Clear all data`**

This single action removes everything Crosscue stored on the device:

- imported and downloaded puzzles
- solve progress, completion history, and statistics
- app settings (theme, sound, haptics, accessibility preferences)
- the optional local crash log (if you ever enabled crash reporting)

If you also used **Challenge Boards**, the same action deletes your server-side
data too — see step 2, which it performs automatically.

You can also remove on-device data without the app: uninstall Crosscue, or use
your device's system settings (**iOS:** delete the app; **Android:** Settings →
Apps → Crosscue → Storage → Clear storage).

## 2. Delete your Challenge Boards data (done automatically by step 1)

Challenge Boards is an optional, invite-only feature. It is the only part of
Crosscue that stores anything on a Crosscue-operated server (hosted on
Cloudflare). If you ever created or joined a board, that server holds:

- an **anonymous player identity** (a random id and access token — not tied to
  your name, email, or any account)
- your chosen **display name**
- which **boards** you belong to (and board names you created)
- **solve-result metadata** for eligible daily puzzles (puzzle source and date,
  your elapsed time, completion type, and timestamps)
- compact **lifetime aggregate stats** for each board

`Settings → Privacy & Data → Clear all data` (step 1) also sends a deletion
request to the server, which:

- removes you from every board (a board with no remaining members is deleted),
- deletes your challenge solve-result rows,
- anonymizes any residual membership records,
- and revokes your access token and recovery secret.

If the server can't be reached at that moment, the app tells you and lets you
retry, so the request isn't silently lost.

Crosscue never stores your puzzle answers, guesses, or clue text on the server.

## 3. Remove the copy in your own cloud (only if you turned on sync)

If you turned on **sync**, your puzzles, progress, and settings are stored in
**your own private cloud account** — iCloud on iOS, the hidden Google Drive
app-data folder on Android. This is your data in your account; Crosscue never
receives or stores it.

To delete that copy:

**`Settings → Sync → Turn off and remove cloud copy`**

This deletes Crosscue's data from your iCloud or Google Drive account. (Turning
sync off without choosing "remove cloud copy" leaves the cloud copy in place.)

## What is kept, and for how long

- **On your device / in your cloud:** nothing is kept after the steps above —
  the data is removed where you ran them.
- **On the Crosscue server:** after a deletion request, your player record is
  soft-deleted and your results are removed. Internal board-activity audit
  records are short-lived regardless — they are purged automatically on a
  rolling ~14-day window.
- **Provider backups:** as with most online services, copies may persist briefly
  in the hosting provider's routine backups before they age out. Crosscue does
  not use these for any purpose; they expire on the provider's schedule.

## Request deletion without the app

The in-app steps above are the fastest path and require no account. If you can't
use the app — for example, you've uninstalled it but want to confirm your
Challenge Boards data is gone — email **`atomhess@gmail.com`** with the subject
`Delete my data`. Because the identity is anonymous, please send the request
from a device that can still open the app (so it can supply your anonymous
player id), or include any board invite link you still have; we'll help locate
and remove the associated server record.

## Contact

For any question about deleting Crosscue data, contact:

`atomhess@gmail.com`
