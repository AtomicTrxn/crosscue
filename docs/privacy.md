<!--
  MAINTAINER NOTE (not part of the policy text): this file IS the published
  policy — GitHub Pages builds from main:/docs (Jekyll) and serves it as
  https://atomictrxn.github.io/crosscue/privacy.html, the URL filed with both
  app stores. Whenever this file changes: bump the effective date, and after
  the change merges to main, verify the live page updated before the next
  store submission — see DEPLOYMENT.md store checklists.
-->

# Privacy Policy for Crosscue

**Effective date:** June 9, 2026

Crosscue is an offline-first crossword app for iOS and Android. This Privacy
Policy explains what information Crosscue stores, what information it does not
collect, and the choices available to you.

## Summary

- Crosscue does not require an account to solve puzzles.
- Crosscue does not include advertising or analytics.
- Crosscue does not collect your name, email, contacts, or location.
- Puzzle data, solve progress, settings, and optional crash logs are stored
  locally on your device.
- If you choose to download puzzles from an online puzzle source, your device
  connects directly to that third-party source to fetch the requested puzzle.
- If you choose to turn on sync, your puzzles, progress, and settings are
  stored in your own private cloud account — iCloud on iOS, Google Drive on
  Android — so they follow you across your devices. This data is never sent to
  the developer.
- If you choose to use **Challenge Boards** (optional private friend
  leaderboards), a limited set of data — an anonymous player identity, your
  chosen display name, which boards you join, and the time/outcome of your
  solves — is stored on a Crosscue-operated server so friends can compare
  results. This feature is off until you create or join a board, and you can
  delete this data at any time. See "Optional Challenge Boards" below.

## Information stored on your device

Crosscue stores the following information locally on your device so the app can
work:

- imported or downloaded crossword puzzle data
- solve progress, completion history, and puzzle statistics
- app settings such as theme, sound, haptics, and accessibility preferences
- an optional local crash log if you enable crash reporting in the app settings

The optional crash log is stored only on your device. It is not automatically
sent to the developer or to any third-party crash-reporting service.

## Information Crosscue does not collect

Crosscue does not collect:

- your name, email address, phone number, or mailing address
- account credentials
- location data
- contacts
- advertising identifiers
- analytics or usage-tracking data
- puzzle answers, guesses, clue text, or puzzle contents for remote telemetry

## Network access and third-party services

Crosscue may use network access when you choose to download puzzles from an
online puzzle source. In that case, your device sends the network request needed
to retrieve the requested puzzle to that third-party provider. Those providers
may process request information such as IP address, device/browser metadata, or
other technical data according to their own privacy practices.

Crosscue may also open external links, such as the project's GitHub page, in
your browser when you choose to follow them.

Crosscue does not currently use third-party analytics, advertising SDKs, or
remote crash-reporting services.

## Optional sync (iCloud on iOS, Google Drive on Android)

Crosscue offers an optional sync feature so your puzzles, solve progress, and
settings stay in sync across your devices. It uses **iCloud on iOS** and
**Google Drive on Android**. It is **off by default** — you opt in during
onboarding or from `Settings -> Sync`, and only when you are signed in to the
relevant cloud account on the device.

When sync is on:

- Your puzzle library, solve progress, completion history, and synced settings
  are stored in **your own private cloud account**:
  - On iOS, in your iCloud account (Apple's iCloud Drive), handled by Apple
    under [Apple's Privacy Policy](https://www.apple.com/legal/privacy/).
  - On Android, in a hidden, per-app folder of your Google Drive account
    (the Drive "app data" area, not visible among your normal Drive files),
    handled by Google under
    [Google's Privacy Policy](https://policies.google.com/privacy). Crosscue
    requests only the scope needed to read and write its own app data folder,
    not access to the rest of your Drive.
- Crosscue does not operate a server and never receives, stores, or processes
  this data — it moves directly between your devices and your own cloud account.
- You can turn sync off at any time in `Settings -> Sync`. Turning it off keeps
  the copy on your device; you can also choose **"Turn off and remove cloud
  copy"** to delete Crosscue's data from your iCloud or Google Drive account.

## Optional Challenge Boards (private friend leaderboards)

Crosscue offers an optional **Challenge Boards** feature: small, invite-only
boards where you and friends compare daily-puzzle results. Unlike sync, this
feature uses a server operated by the Crosscue developer (hosted on Cloudflare),
because comparing results between different people requires a shared service. It
is **off until you create or join a board**, and there is no public or global
leaderboard.

When you use Challenge Boards, the following is stored on the Crosscue server:

- an **anonymous player identity** (a random id and access token) created for
  you automatically — it is not tied to your name, email, or any account;
- your chosen **display name** (up to 10 characters);
- which **boards** you are a member of, and board names you create;
- **invite metadata** — only a hash of each board's invite secret, an invite
  version, and its expiry time;
- **solve result metadata** for eligible daily puzzles: the puzzle's source and
  date, your elapsed time, completion type (clean or assisted), and timestamps;
- compact **lifetime aggregate stats** (such as your average and best clean
  solve time per board);
- a small amount of internal board activity used to operate the feature.

Crosscue does **not** store your puzzle answers, guesses, clue text, or puzzle
contents on the server for Challenge Boards.

To let your anonymous player identity survive a device restore, Crosscue stores
a small **recovery bundle** in your own private cloud account (the same iCloud or
Google Drive app-data area used by sync). The server keeps only a hash of the
recovery secret, never the secret itself. This recovery works within the same
cloud (iPhone-to-iPhone via iCloud, Android-to-Android via Google Drive); it
does not move your identity between iOS and Android.

Time and leaderboards use **UTC**: weekly boards run Monday through Sunday UTC,
and labels indicate the UTC boundary.

**Retention.** Recent solve results are retained to compute weekly and lifetime
standings; internal board activity records are kept for a short window (about 14
days) and then purged automatically. When everyone leaves a board, it is
deleted.

**Deleting your Challenge Boards data.** Using `Settings -> Privacy & Data ->
Clear all data` deletes your server-side player record, board memberships, and
solve results in addition to wiping this device. If the server cannot be reached
at that moment, the app tells you and lets you retry. As with most online
services, copies may persist briefly in the provider's routine backups before
they age out.

## Exporting and importing data

Crosscue lets you export solve statistics as a local backup file and import a
backup file you choose. Exported files remain under your control unless you
decide to share or store them using another app or service. Any third-party app
or storage provider you choose for those files is governed by its own privacy
policy.

## Data retention and deletion

Data stored by Crosscue remains on your device until you delete it, uninstall
the app, or clear the app's data through your device's system settings.

You can delete Crosscue data from within the app by using:

`Settings -> Privacy & Data -> Clear all data`

This removes puzzles, progress, statistics, and settings stored by Crosscue on
the device. If you have used sync, see "Optional sync" above for removing the
copy stored in your iCloud or Google Drive account. If you have used Challenge
Boards, this action also deletes your server-side player record and board
participation, as described in "Optional Challenge Boards" above.

## Children's privacy

Crosscue is not directed to children under 13, and the app does not knowingly
collect personal information from children.

## Changes to this policy

If Crosscue's data practices change, this Privacy Policy will be updated before
those changes are released where required.

## Contact

For privacy questions about Crosscue, contact:

`atomhess@gmail.com`
