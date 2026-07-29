# App Store Connect copy — Crosscue 1.4.5

Paste-ready copy for the iOS 1.4.5 release. Text in square brackets must be
resolved by the account holder before submission.

## Product page

### App name

Crosscue

### Subtitle

Private crossword solving

### Promotional text

Bring your own crosswords, solve offline, track streaks, and compare daily-mini
times with friends—without accounts, ads, analytics, or tracking.

### Description

Crosscue is a fast, privacy-first crossword solver for people who want the
puzzle, not the strings attached.

SOLVE YOUR PUZZLES

• Import .puz and .ipuz crossword files
• Download supported daily mini crosswords in the app
• Navigate naturally between across and down clues
• Use rebus entries, pencil mode, mistake highlighting, and reveal tools
• Keep your progress with automatic saving

BUILD A SOLVING HABIT

• Browse completed and in-progress puzzles in your archive
• Track solve times, completion rates, streaks, and personal records
• Share a clean result card without exposing puzzle answers
• Use widgets and shortcuts to get back to solving quickly

CHALLENGE FRIENDS—OPTIONALLY

Create a private, invite-only Challenge Board and compare daily-mini solve times
with friends. No account is required: choose a handle, share an invite link, and
start solving. Adding an avatar photo is always optional.

PRIVATE BY DESIGN

• No ads
• No analytics
• No tracking
• No account required
• Core solving works offline
• Optional iCloud sync keeps your puzzle library on your Apple devices

Crosscue includes accessibility support for VoiceOver, Dynamic Type, keyboard
navigation, reduced motion, and high-contrast display settings.

Your puzzles are yours. Open one and get solving.

### Keywords

crossword,puzzle,solver,rebus,offline,mini,streak,word game,brain,archive

### What's New in This Version

Crosscue 1.4.5 is a maintenance update with reliability and accessibility
improvements. It also clarifies how optional Challenge Boards avatar photos are
stored and removed when you clear your Challenge Boards data.

## URLs and ownership

### Support URL

${APP_STORE_SUPPORT_URL}

[REQUIRED: publish or confirm a dedicated support page that displays the
support contact resolved from `${APP_SUPPORT_EMAIL}`. Do not submit with only a
generic project or repository URL.]

### Marketing URL

https://github.com/AtomicTrxn/crosscue

### Privacy Policy URL

https://atomictrxn.github.io/crosscue/privacy.html

### Privacy Choices URL

https://atomictrxn.github.io/crosscue/delete-data.html

### Copyright

2026 ${APP_STORE_COPYRIGHT_HOLDER}

[REQUIRED: resolve `${APP_STORE_COPYRIGHT_HOLDER}` from the ignored local
submission config and confirm that it is the person or legal entity that owns
the exclusive rights to Crosscue.]

## App Review Information

### Contact

First name: ${APP_STORE_REVIEW_FIRST_NAME}
Last name: ${APP_STORE_REVIEW_LAST_NAME}
Email: ${APP_STORE_REVIEW_EMAIL}
Phone: ${APP_STORE_REVIEW_PHONE}

### Sign-in

Sign-in required: No
Demo account required: No

### Notes

No sign-in or demo account is required. Crosscue is offline-first: import a
.puz/.ipuz file or download a daily mini in the app, then solve. All core
features—solving, import, archive, stats, and settings—work without an account
or network connection.

Challenge Boards is optional and appears in the Challenge tab. It is anonymous
and invite-only: there is no account, only a chosen handle. It lets friends
compare daily-mini solve times through a private invite link. Because a board
requires another participant or device to be meaningful, a fresh install shows
a “create or join a board” empty state. This is expected. To exercise the
feature, tap Challenge, create a board, and share the generated invite link.

Camera and Photo Library access are used only when the user chooses a custom
Challenge Boards avatar. The app includes a location usage description because
a bundled photo-picker component references location APIs when reading photo
metadata. Crosscue does not request, record, or transmit the user's location,
and it does not show a location permission prompt.

Crosscue has no ads, analytics, or tracking. The only data sent to a
Crosscue-operated server is optional Challenge Boards data: an anonymous player
identifier, chosen handle, solve-result metadata, and an avatar image only when
the user selects one. Avatar images are used only within Challenge Boards and
are deleted when the user clears Challenge Boards data in Settings > Privacy &
Data > Clear all data. These practices are disclosed in App Privacy and the
privacy policy.

## App Privacy selections

These are form selections rather than public product-page copy. Confirm them
against the final binary and Apple's current taxonomy before submission.

Data collection: Yes, only when the user enables Challenge Boards.

Data types:

• User ID: anonymous player identifier and chosen handle
• Photos: optional avatar image
• Gameplay Content / Other Usage Data: solve time, completion type, puzzle
source, and puzzle date

Purpose: App Functionality
Used for tracking: No

The current implementation treats this data as pseudonymous and not linked to a
real-world identity because Crosscue collects no account, name, or email
address. The account holder must make the final “linked to the user” selection
after reviewing Apple's current definition.

## Screenshot assets

Use the existing localized screenshot sets:

• iPhone 6.7-inch: `design/store/ios/iphone-6.7/`
• iPad Pro 12.9-inch: `design/store/ios/ipad-12.9/`

Each set contains five images covering solving, rebus entries, the home/archive
view, statistics, and settings.

## Submission blockers

Before sending the version to App Review:

1. Resolve all `${...}` values from `config/app-submission.local.env`.
2. Confirm the legal rights holder used in the copyright field.
3. Publish or confirm a support URL that visibly provides real contact
   information.
4. Have the account holder confirm the App Privacy “linked to the user”
   classification.
