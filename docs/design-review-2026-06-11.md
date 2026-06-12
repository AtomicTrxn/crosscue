# Crosscue — Project Design & Architecture Review

> **Status:** Snapshot (2026-06-11) — point-in-time; not edited after the
> fact. The documentation gaps it identified were resolved the same day
> (PRODUCT.md, SECURITY.md, ADRs 0001–0016, compatibility.md,
> threat-model.md, the Android QA checklist, and the docs-system changes);
> the remaining items are code tasks.

**Date:** 2026-06-11
**Scope:** Every Markdown document in the repo (root docs, `docs/**`, backend and
deeplink READMEs) reviewed as a body of work — project objectives, architecture
guidance, and planning posture. This is deliberately a **planning- and
design-level** review; it does not re-audit code. It complements (and
cross-references) the two prior code-facing reviews:
[`app-analysis-2026-06-07.md`](app-analysis-2026-06-07.md) and
[`code-review-2026-06-10.md`](code-review-2026-06-10.md).

---

## 1. What the project does well (keep doing)

This is an unusually well-documented codebase for a small team, and the docs are
load-bearing rather than decorative:

- **Docs match the code.** The 2026-06-10 review verified the layer rules in
  `ARCHITECTURE.md` hold in practice. Conventions cite the real bug that
  motivated each rule — the best possible justification format.
- **A real legal guardrail.** The puzzle-source license table in
  `CONVENTIONS.md` with dated approvals and a review checklist is genuinely rare
  and protects the project's biggest external legal risk.
- **Deliberate privacy posture.** Offline-first, no analytics, opt-in sync to
  the user's own cloud, hashed-at-rest server secrets, in-app deletion that
  reaches the server. The privacy policy reads like it was written by someone
  who understands the architecture (because it was).
- **Decision records exist** — `completion-authority.md` and `sync-design.md`
  document options considered, verdicts, and named trade-offs ("autosave is
  debounced — last 500 ms is lost on kill, by design").
- **One CI source of truth** (`make ci` mirrors hosted PR checks), dispatch-only
  releases, and runbook-quality deployment docs.

The recommendations below are about scaling this discipline as the project's
scope grows — specifically the shift from "offline-first app" to "offline-first
app **plus a small online service**," which is where most of the new risk lives.

---

## 2. Strategic gaps — the missing "why" layer

The docs are excellent at *how* (conventions, runbooks) and *what*
(architecture, models), but there is **no document that states the project's
objectives, target users, or roadmap**. GitHub Issues track tactical work, but
nothing ties issues to goals. Consequences visible in the docs themselves:

- Dead scaffolding accumulates because there's no decision forum: the
  entitlement/paid-tier stub (F4) and the reminders/notifications keys (F3)
  have sat undecided across two reviews.
- iOS keeps pulling ahead of Android (widget, App Intents, branded share —
  P1/P2/P3) with no stated policy on whether iOS-first is deliberate.
- The product identity ("Your puzzles. Your device. No strings attached.") is
  now in quiet tension with a growing server surface (Challenge Boards), and
  the principle that resolves that tension is scattered across README and
  privacy.md rather than stated once, normatively.

### Recommendation 2.1 — Write a short `PRODUCT.md` (1–2 pages)

Capture, once:

1. **Vision & target user** — e.g., "serious-casual solvers who want NYT-grade
   mechanics without subscriptions or surveillance."
2. **Product principles**, stated as testable rules. The most important one is
   already implicit everywhere and should be explicit:
   > *Every online feature must be (a) opt-in, (b) anonymous or
   > pseudonymous, (c) deletable in-app, and (d) degradable — the app must be
   > fully functional with it off.*
   Challenge Boards already passes this test; writing the rule down makes the
   *next* online feature (notifications? global stats?) decidable in minutes.
3. **Roadmap themes** (not dates) — e.g., solver depth, social, platform
   parity, content sources — and which theme each open issue serves.
4. **Explicit non-goals** — e.g., no public leaderboards, no accounts, no ads.
   `sync-design.md` does this well locally; do it once globally.

### Recommendation 2.2 — Make the three stalled decisions

Each needs a one-paragraph decision, not more analysis:

| Decision | Options | Forcing observation |
|---|---|---|
| **Monetization** (F4) | (a) delete the entitlement layer; (b) keep + write a one-page plan (tip jar? paid puzzle packs?) | The scaffold costs attention every review; `licensed_daily_reminder_enabled` couples it to the *other* undecided feature |
| **Reminders/notifications** (F3) | build (plugin + scheduler + settings UI) or remove keys | Settings sync already reserves keys for it — the longer it sits, the more it looks shipped |
| **Platform parity policy** (P1/P2) | "iOS-first, Android follows within N releases" or "parity required to ship" | Challenge Boards invites + widgets are now user-visible asymmetries; a stated policy converts complaints into roadmap |

### Recommendation 2.3 — Decide how product feedback works without analytics

The no-analytics stance is a feature, but it means there is currently **no
documented feedback loop at all**. Options compatible with the privacy posture:
store reviews/TestFlight feedback triage as a routine; an in-app "send
feedback" mail link; opt-in, user-visible local counters ("you've solved 214
puzzles") that users can choose to share. Document whichever is chosen — the
point is that "how do we know feature X worked?" should have an answer.

---

## 3. Architecture-level recommendations

### 3.1 The compatibility matrix is now the project's hardest problem — name it

Crosscue now has **five independently versioned contracts**:

1. Drift local DB schema (v7+)
2. Sync blob envelope (`SyncBlob.schemaVersion = 1`) + manifest format
3. Worker D1 schema (numbered migrations)
4. Worker HTTP API (prose contract in `API.md`, unversioned paths)
5. Widget payload (`crosscue_widget_v1`)

Each is individually handled well (additive migrations, forward-compat skip,
"keep Worker compatible with oldest fielded app"). What's missing is the
**cross-version interaction policy**, and one latent design risk hides there:

> **Sync divergence under mixed app versions.** `SyncBlob.decode()` returns
> null for blobs with a newer `schemaVersion` — the reader skips them. Correct
> for safety, but consider device A on app v1.4 (schema 1) and device B on
> v2.0 (schema 2): B's writes are invisible to A, A keeps writing schema-1
> blobs, and last-writer-wins namespaces (sessions, settings) can now
> ping-pong or silently fork depending on which device syncs last. "Skip" is
> a *read* policy; there is no stated *write/upgrade* policy.

**Recommendation:** add a `docs/architecture/compatibility.md` that states, in
one table: each contract, its current version, who reads/writes it, the
guaranteed support window (e.g., "Worker supports app versions ≥ X", "sync
schema N readable by app versions ≥ Y"), and the bump procedure. For sync
specifically, decide the mixed-version rule now — reasonable options:
(a) a device that *sees* newer-schema blobs surfaces "update the app to keep
syncing" and stops pushing to that namespace, or (b) schema bumps are reserved
for major versions with a documented flag-day. Either is fine; undocumented is
not.

### 3.2 Add an API version + minimum-client mechanism to the Worker **before** the user base grows

`API.md` has no version in its paths and the client sends no version
identifier. The deployment doc's rule — "keep Worker changes compatible with
the oldest app version still in the field — shipped clients cannot be forced
to update" — is currently absolute because **there is no force-update or
deprecation lever at all**. That is the kind of constraint that becomes
permanent the day the first stranger installs the app.

**Recommendation (cheap now, expensive later):**
- Client sends `X-Crosscue-Client: <platform>/<semver>` on every request.
- Worker gains a `426`/structured `client_too_old` response and a config-level
  `MIN_SUPPORTED_CLIENT` (a Wrangler var — no schema change).
- App treats `client_too_old` as a friendly "please update" state on the
  Challenge tab (the rest of the app is offline and unaffected — the
  degradability principle from §2.1 pays off here).

This also gives you the kill-switch you'll want if the honor-system results
endpoint is ever abused.

### 3.3 Treat the Crosshare scraper as the single point of failure it has become

`crosshare_downloader.dart` is an **HTTP + HTML scraper**, and it now
underpins three headline features: the daily-mini home section, the
auto-download path, and — critically — **Challenge Boards eligibility**
(`sourceId: crosshare_daily_mini` is the only accepted source). A Crosshare
markup change breaks the social feature for every user simultaneously, and no
doc names this risk.

**Recommendations (design level):**
1. Add a **scheduled CI canary** (weekly cron workflow) that runs the live
   fetch/parse against crosshare.org and opens an issue on failure — turning a
   user-reported outage into a pre-noticed one.
2. Document the **degradation story**: what the Challenge tab and home section
   show when the source is down (stale-but-honest beats broken).
3. Consider reaching out to Crosshare for a stable feed/API — the legal
   approval is already in place, and the ask is small.
4. Longer term, the Worker is the natural place for a **source-of-record
   puzzle-id registry** (the deferred D4 "canonical-source policy" in the #159
   breakdown) — it would also decouple board eligibility from client-side
   scraping success.

### 3.4 Finish the Challenge Boards convention reconciliation before the next feature lands on it

F2 from the 2026-06-07 analysis (31/39 files with blanket lint ignores, a
parallel theme/nav stack, non-standard folder layout) is the one place the
"docs match the code" claim breaks. The planning point: **every new Challenge
Boards feature inherits the divergence**, so the cost of the cleanup is
monotonically increasing. Avatars, ownership/succession (#250), and preset
refreshes (#249) have already been built on top of it.

**Recommendation:** schedule the conventions pass as a gating predecessor to
the next significant Challenge Boards feature, and add the missing enforcement
so it can't recur: an architecture test that fails on `// ignore_for_file:` in
`lib/features/**` (allowlist generated files), and one that forbids importing
feature-local theme files from outside `core/theme`. The repo already has
"mechanical architecture enforcement in tests" per the 2026-06-10 review —
extend that mechanism rather than relying on review vigilance.

### 3.5 Adopt lightweight ADRs; stop growing the ARCHITECTURE.md changelog

"Recent Architectural Decisions" in `ARCHITECTURE.md` is an unbounded
append-only list (already ~10 entries spanning 13 months) inside a file that
must stay readable as a *current-state* reference. Meanwhile the best decision
docs (`completion-authority.md`, `sync-design.md`) already follow an
options→verdict→consequences shape — they're ADRs in all but name.

**Recommendation:** create `docs/architecture/decisions/` with numbered ADRs
(`0001-completion-authority.md`, …), each with a status line
(Accepted / Superseded-by). Move the existing decision entries' *content*
there; `ARCHITECTURE.md` keeps a one-line link per decision. New rule: any
change that adds a "Recent Architectural Decisions" bullet writes an ADR
instead. This keeps the as-built doc current-state-only and gives decisions a
lifecycle (the rebus plan's "Status: shipped — historical plan of record"
header shows the need is already felt).

---

## 4. Documentation-system improvements

The doc *content* is strong; the doc *system* has drift risks.

### 4.1 Fix the index and define what lives where

`docs/index.md` lists 3 of the ~14 documents under `docs/` — it's missing the
entire `architecture/` folder, the QA checklist, and both prior reviews.
There are also **two documentation roots** (repo root + `docs/`) with no
stated rule for which gets what.

**Recommendation:** one paragraph in `docs/index.md` defining the split —
suggested rule: *root = contributor-facing evergreen (how to build, code
rules); `docs/` = product/design/ops (decisions, runbooks, QA, policy,
reviews)* — plus a complete listing. Cheap, prevents the next doc from being
placed by coin flip.

### 4.2 Give every doc a lifecycle status

Three kinds of document currently look identical: **living references**
(ARCHITECTURE.md), **point-in-time snapshots** (`app-analysis-2026-06-07.md`),
and **historical plans of record** (`rebus-entry.md`, the #159 breakdown —
whose "Status snapshot (2026-06-09)" was partially stale within days as
workstreams completed). A reader cannot tell whether a statement is a current
invariant or a 2026-06-09 observation.

**Recommendation:** a one-line header convention on every doc under `docs/`:
`> Status: Living | Snapshot (YYYY-MM-DD) | Historical — superseded by <link>`.
Snapshots are then *never edited* — corrections go in the living docs they
informed. (The code-review tracker, which deliberately updates a Status column,
is "Living" until all findings close, then flips to Historical.)

### 4.3 Reduce code-mirroring in MODELS.md and ARCHITECTURE.md

`MODELS.md` hand-transcribes constructor signatures and field lists;
`ARCHITECTURE.md` hand-transcribes per-feature file trees. Both *will* drift
(the providers section already hedges: "categorical, not exhaustive, to avoid
going stale" — the right instinct, applied inconsistently). The valuable,
non-derivable content is the **semantics**: ID formats, the
`PuzzleStatus ↔ CompletionType` round-trip, "Grid can't be Freezed," the
DB↔domain mapping table.

**Recommendation:** prune both docs toward semantics + invariants + pointers
("see `puzzle_metadata.dart` for fields"), keeping prose only where the code
can't express the why. Don't build doc-generation tooling — just lower the
duplication surface.

### 4.4 Single-source the privacy policy

`docs/privacy.md` and the published `atomictrxn.github.io/crosscue/privacy.html`
are maintained as two artifacts. Store submissions point at the HTML; the repo
doc is the one reviews update. Divergence here is a *compliance* bug, not a
docs bug.

**Recommendation:** make the published page generated from `docs/privacy.md`
(or make the gh-pages copy a checked-in build artifact with a CI check that
they match). Add "regenerate the published policy" to both store-submission
checklists.

---

## 5. Quality-engineering recommendations

### 5.1 Contract-test the client↔Worker boundary

`API.md` is a prose contract; the Dart models and the Worker validators are
maintained by hand on each side. Nothing fails when they drift — the result
would be a runtime 400 in the field (and because result submission is
fire-and-forget from the solve path, possibly a *silent* one).

**Recommendation:** the lightest mechanism that works — a shared fixture file
of canonical request/response JSON (essentially `API.md`'s examples, made
executable), replayed by both the Worker tests (Miniflare) and a Dart
serialization test. Same fixtures, two consumers; `API.md` examples then have
a reason to stay true.

### 5.2 Write the Android QA checklist

`docs/qa/` contains only the iOS release checklist, yet Android ships to Play
internal on every release. The iOS checklist is excellent; Android needs the
equivalent (back-gesture behavior, share-sheet import via Intents,
predictive-back, R8-minified release smoke — the doc itself warns minification
"can break plugin reflection in ways debug builds will not catch," which is
precisely what a checklist should catch).

### 5.3 State performance budgets

Performance care is visible everywhere in the *implementation* docs
(CustomPainter over widgets-per-cell, the elapsed-seconds notifier isolated
off the rebuild path, post-first-frame scheduling) but there are **no stated
budgets**, so regressions are only caught by feel.

**Recommendation:** a short table in `ARCHITECTURE.md` or an ADR — e.g., cold
start to first frame < X ms on a reference device; solve-screen input latency
< 1 frame; no jank during grid paint at 21×21; sync pass network bytes for
an unchanged library ≈ one manifest GET. Even unmeasured, written budgets
make "is this acceptable?" answerable in review.

### 5.4 Make the integration suite's platform coverage deliberate

The integration tests run iOS-only in CI (`integration-test-ios.yml`,
dispatch-only). Android integration coverage relies on local runs. Given
Android-specific history (focus-node crashes, file-picker MIME issues — both
memorialized in CONVENTIONS.md), an Android leg of the same suite (also
dispatch-only is fine) closes a real gap.

---

## 6. Operations & security for the server era

The Worker docs cover deploy, migrate, rollback, logs — good. Three gaps, all
sized for a solo operator:

1. **Backup/restore runbook.** D1 offers point-in-time recovery (Time Travel),
   but no doc says how Crosscue would use it, what the recovery point
   objective is, or how to verify a restore. One page in DEPLOYMENT.md:
   how to list restore points, restore staging from prod, and the order of
   operations relative to Worker deploys.
2. **Alerting, not just logs.** `wrangler tail` is pull-based. Define the
   minimal push signal: Cloudflare notification on Worker error-rate spike +
   the §3.3 scraper canary + a weekly `gh` cron that checks the retention
   cron's `purge_board_events` log line ran. Without this, the first outage
   report comes from a friend's leaderboard not loading.
3. **A threat-model page + SECURITY.md.** The security *properties* are
   already strong (hashed secrets, rate limits, scoped tokens). What's missing
   is the document that says what the system defends against and what it
   accepts: honor-system results (accepted, bounded by sanity checks),
   long-lived bearer tokens (accepted; rotation = recovery-restore), invite
   links as capability URLs (accepted; regeneration locks out). Plus a
   `SECURITY.md` with a disclosure contact — the repo is public and has a
   server now.

---

## 7. Prioritized plan

Ordered by (risk reduction × cheapness), planning items only — code findings
remain tracked in the two prior reviews:

| # | Action | Section | Size |
|---|--------|---------|------|
| 1 | Decide the three stalled decisions (monetization, reminders, parity policy) | §2.2 | one sitting |
| 2 | `PRODUCT.md` — vision, principles (incl. the online-feature rule), roadmap themes, non-goals | §2.1 | 1–2 pages |
| 3 | Client version header + `client_too_old` lever in the Worker | §3.2 | small PR, huge option value |
| 4 | Crosshare canary workflow + documented degradation story | §3.3 | small |
| 5 | `compatibility.md` — five-contract matrix + mixed-version sync policy | §3.1 | 1 page + 1 decision |
| 6 | Challenge Boards conventions pass, gated before its next feature; add enforcement tests | §3.4 | the known F2 cleanup |
| 7 | Docs system: fix index, status headers, ADR folder migration | §4.1–4.2, §3.5 | mechanical |
| 8 | API contract fixtures shared by Worker + Dart tests | §5.1 | medium |
| 9 | Android QA checklist; Android integration-test leg | §5.2, §5.4 | medium |
| 10 | D1 backup runbook, error-rate alerting, threat model + SECURITY.md | §6 | 2–3 short docs |
| 11 | Prune MODELS.md/ARCHITECTURE.md code-mirroring; single-source privacy policy | §4.3–4.4 | opportunistic |
| 12 | Performance budgets table | §5.3 | half page |

The through-line: Crosscue's engineering discipline was built for an offline
app and it shows — the offline core is in excellent shape. The 2026 additions
(sync, Challenge Boards, widgets) quietly turned it into a distributed system
with five versioned contracts, an external scraping dependency, and an
operated service. The highest-leverage planning work is to give that new shape
the same explicitness the offline core already enjoys: stated objectives,
named compatibility guarantees, a force-upgrade lever, and an operator's
runbook — most of it documentation and small mechanisms, not rewrites.
