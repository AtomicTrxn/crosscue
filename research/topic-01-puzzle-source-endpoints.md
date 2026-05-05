# Research Topic #1 — Puzzle Source Endpoints

Status: Resolved
Implementation Status: ⬜ Post-MVP — SourceRegistry foundation shipped in Sprint 8; actual downloaders remain blocked by topic-07 legal review before any source is enabled
Owner: Claude
Researched: 2026-04-30

## Research Question

What are the current fetch URLs, response formats, auth requirements, rate limits, and downloader strategies for Universal, LA Times, and Guardian puzzles? Are the Robocrosswords (2018) downloader patterns still valid?

## Decision To Unblock

What concrete fetch strategy should each puzzle source downloader implement in Phase 1, and what are the risks of each approach?

## Recommendation

This document identifies the technical endpoints for approved puzzle sources. 

**Scope Note:** Automated fetching is strictly limited to sources with explicit permission or free/unrestricted access. The scraping strategies for Universal, LA Times, and The Guardian (described below for historical/reference purposes) are **out of scope** for the current implementation and must not be enabled.

All automated fetching must adhere to the legal guardrails defined in [topic #7](topic-0pe-legal-tos-puzzle-sources.md).

---

## Source 1: Universal Crossword

### Endpoint

```
https://gamedata.services.amuniversal.com/c/uucom/l/U2FsdGVkX18YuMv20%2B8cekf85%2Friz1H%2FzlWW4bn0cizt8yclLsp7UYv34S77X0aX%0Axa513fPTc5RoN2wa0h4ED9QWuBURjkqWgHEZey0WFL8%3D/g/fcx/d/{YYYY-MM-DD}/data.json
```

The long middle segment is a static encrypted token baked into the URL — it does not rotate or require a login. Append the date in `YYYY-MM-DD` format.

### Request

- Method: `GET`
- Headers: Standard `User-Agent` (xword-dl sends `xword-dl/{version}`)
- Auth: None (token is embedded in the URL path)
- Retry pattern: 3 attempts with 2-second intervals on failure

### Response Format (JSON)

```json
{
  "Title": "Universal Crossword",
  "Author": "Constructor Name",
  "Editor": "Editor Name",
  "Copyright": "© 2024 Andrews McMeel Universal",
  "Width": 15,
  "Height": 15,
  "AllAnswer": "ABCDE....-.....",
  "AcrossClue": "1. Clue text|5. Clue text|...",
  "DownClue": "1. Clue text|2. Clue text|..."
}
```

Key field notes:
- `AllAnswer`: flat string, reading order left-to-right top-to-bottom; hyphens (`-`) represent black squares (map to `.` in standard .puz convention)
- `AcrossClue` / `DownClue`: pipe-delimited strings with `{number}. {text}` format
- Width/Height: always integers; standard puzzles are 15×15

### Rate Limiting

No documented rate limits. The static encrypted token in the URL suggests access is intentionally public. No authentication or cookie required. Standard per-request throttling (1–2 seconds between requests) is a safe courtesy default.

### Dart Implementation Notes

```dart
final date = DateFormat('yyyy-MM-dd').format(puzzleDate);
final url = 'https://gamedata.services.amuniversal.com/c/uucom/l/'
    'U2FsdGVkX18YuMv20%2B8cekf85%2Friz1H%2FzlWW4bn0cizt8yclLsp7UYv34S77X0aX%0A'
    'xa513fPTc5RoN2wa0h4ED9QWuBURjkqWgHEZey0WFL8%3D/g/fcx/d/$date/data.json';
final response = await dio.get(url);
// Parse response.data as Map<String, dynamic>
```

### Risks

- The static encrypted token could be rotated by AM Universal at any time with no notice, breaking the downloader until the new token is found in the xword-dl source or via browser inspection.
- No official documentation means no SLA or stability guarantee.

---

## Source 2: LA Times Crossword

### How It Works

The LA Times uses **AmuseLabs/PuzzleMe** as its crossword platform. There is no simple date → URL mapping. The flow is:

1. Fetch the **date-picker** page to get the puzzle ID for a given date
2. Use the puzzle ID to construct the **puzzle data URL**
3. The puzzle data URL may require a `loadToken` parameter extracted from the picker page

### Picker Endpoint

```
https://lat.amuselabs.com/lat/date-picker?set=latimes
```

For the Mini:
```
https://lat.amuselabs.com/lat/date-picker?set=latimes-mini
```

### Puzzle ID Pattern

- Standard: `tca_YYMMDD` (two-digit year) e.g. `tca_240115` for Jan 15 2024
- Mini: `latimes-mini-YYYYMMDD` (four-digit year) e.g. `latimes-mini-20240115`
- Exceptions exist — always derive from picker response rather than constructing blind

### Puzzle Data URL

```
https://lat.amuselabs.com/lat/crossword?id={puzzle_id}&set=latimes
```

### Authentication / Token

AmuseLabs picker pages embed a base64-encoded `rawsps` parameter. The flow:
1. GET the picker page for the target date
2. Extract `rawsps` query parameter from the page
3. Base64-decode it → JSON → extract `loadToken`
4. Append `&loadToken={token}` to the puzzle data URL

Additionally, an `fvlt` parameter is computed as an XOR hash of the set name, puzzle ID, and `uid` cookie value. This is an anti-hotlink measure, not true authentication.

### Response Format (JSON)

```json
{
  "title": "LA Times Crossword",
  "author": "Constructor Name",
  "copyright": "© Tribune Content Agency",
  "w": 15,
  "h": 15,
  "publishTime": 1705276800000,
  "box": [["A","B","C",...],[...],...],
  "placedWords": [
    {
      "word": "ANSWER",
      "x": 0, "y": 0,
      "acrossNotDown": true,
      "clue": { "text": "Clue text here" }
    }
  ],
  "cellInfos": [
    { "x": 3, "y": 1, "isCircled": true }
  ]
}
```

Key field notes:
- `box`: 2D array of solution letters; black squares are `""` or `null`
- `placedWords`: each word has `acrossNotDown` (boolean), position, and clue
- `publishTime`: Unix milliseconds timestamp
- `cellInfos`: optional array of cell decorations (circles, shading)

### Rate Limiting

AmuseLabs documentation states they are "introducing usage-based metering" but it was not active as of research date. No hard rate limit documented for public embeds. Standard 1–2 second courtesy delay between requests recommended.

### Dart Implementation Notes

This requires a two-step fetch. The token extraction logic needs to replicate the base64 decode + XOR computation. Consider implementing this in the `LatimesSource` class with a private `_fetchPickerToken(DateTime date)` method.

### Risks

- **Highest fragility of the three sources.** AmuseLabs actively maintains the picker/token system as an anti-scraping measure. Token algorithm changes would break the downloader.
- The `fvlt` XOR computation is undocumented and could change silently.
- AmuseLabs has a paid official API (`client_id` + `client_secret` via `support@amuselabs.com`) — if they enforce it, unofficial access would break.
- xword-dl had a 2024 patch specifically to fix LA Times picker robustness, suggesting it has broken before.

---

## Source 3: The Guardian Crossword

### Puzzle Types Available (All Free)

| Series | URL slug | Frequency |
|--------|----------|-----------|
| Cryptic | `/crosswords/series/cryptic` | Monday–Saturday |
| Quick | `/crosswords/series/quick` | Daily |
| Everyman | `/crosswords/series/everyman` | Sunday |
| Speedy | `/crosswords/series/speedy` | Monday |
| Prize | `/crosswords/series/prize` | Saturday |
| Quiptic | `/crosswords/series/quiptic` | Monday |
| Weekend | `/crosswords/series/weekend-crossword` | Saturday |

### Puzzle URL Pattern

```
https://www.theguardian.com/crosswords/{series}/{number}
```

e.g. `https://www.theguardian.com/crosswords/cryptic/29500`

There is no official JSON API endpoint. Puzzle data is embedded in the HTML page.

### How to Get Puzzle Number by Date

Fetch the series index page (e.g. `/crosswords/series/cryptic`). The page lists recent puzzles with their numbers and dates. Parse the list to find the puzzle number for the target date. Puzzle numbers are sequential integers — the series has been running since 1999.

### Data Extraction from HTML

The Guardian embeds crossword JSON in the page HTML in a `gu-island` element:

```html
<gu-island name="CrosswordComponent" props="{encoded JSON}">
```

The `props` attribute contains URL-encoded JSON with the full crossword data.

Alternatively (older pages may still use):
```html
<div class="js-crossword" data-crossword-data="{JSON}">
```

### Response Data Structure (decoded from props)

```json
{
  "crossword": {
    "id": "cryptic/29500",
    "number": 29500,
    "name": "Cryptic crossword No 29,500",
    "date": 1705276800000,
    "dimensions": { "rows": 15, "cols": 15 },
    "entries": [
      {
        "id": "1-across",
        "number": 1,
        "humanNumber": "1",
        "clue": "Clue text (6)",
        "direction": "across",
        "length": 6,
        "position": { "x": 0, "y": 0 },
        "separatorLocations": {},
        "solution": "ANSWER"
      }
    ],
    "creator": { "name": "Setter name" }
  }
}
```

Key field notes:
- `entries`: flat array for both across and down; `direction` field distinguishes them
- `position`: `x` = column (0-indexed), `y` = row (0-indexed)
- `date`: Unix milliseconds timestamp
- `solution`: present in the embedded HTML (answers are not hidden client-side)
- `separatorLocations`: used for hyphenated answers e.g. `{"3": ["-"]}` means hyphen after 3rd letter

### Rate Limiting

The Guardian has no documented rate limit for editorial content. Standard crawl courtesy (1–2 seconds between requests, cache locally) is appropriate. The Guardian's `robots.txt` typically allows crawling of editorial content.

### Dart Implementation Notes

```dart
// Step 1: fetch series page to find puzzle number by date
final seriesPage = await dio.get('https://www.theguardian.com/crosswords/series/cryptic');
// Parse HTML for puzzle links matching /crosswords/cryptic/\d+

// Step 2: fetch puzzle page
final puzzlePage = await dio.get('https://www.theguardian.com/crosswords/cryptic/$number');
// Extract gu-island[name=CrosswordComponent] props attribute
// URL-decode and JSON-parse the props value
```

Use the `html` Dart package for HTML parsing and extract the `gu-island` element's `props` attribute.

### Risks

- Guardian page structure has changed at least once (from `js-crossword` div to `gu-island` tag). Could change again.
- Two-step fetch (index page → puzzle page) adds latency and a second point of failure.
- No archive API — old puzzle discovery requires crawling index pages paginated back in time.

---

## Comparison with Robocrosswords (2018)

| Aspect | Robocrosswords approach | Current approach |
|--------|------------------------|-----------------|
| Universal | Uclick XML endpoint | AM Universal JSON API |
| LA Times | Direct URL with date | AmuseLabs picker + token |
| Guardian | Old HTML div structure | gu-island embedded JSON |

**Conclusion:** All three Robocrosswords patterns are outdated. Do not port them. If a source is legally approved later, use xword-dl's implementations as the technical reference.

---

## Recommended Dart Packages for Downloaders

| Package | Purpose |
|---------|---------|
| `dio` | HTTP client (already in stack) |
| `html` (pub.dev) | HTML parsing for Guardian gu-island extraction |
| `convert` (dart:convert) | base64 decode for AmuseLabs token |
| `intl` | DateFormat for URL construction |

---

## Future Licensed-Source Questions

These questions apply only after topic #7 clears a source legally. They are not Phase 1 launch decisions; Phase 1 remains local import-first per topic #16.

1. **Which legally cleared source ships first?** If Universal, LA Times, Guardian, or another publisher grants permission, choose the lowest-risk licensed integration instead of enabling multiple publishers at once.

2. **AmuseLabs token fragility — acceptable under a license?** If a licensed LA Times or AmuseLabs-based source is approved, decide whether token extraction is stable enough for production or whether the license needs an official feed/API path.

3. **Guardian puzzle type priority after approval** — if Guardian grants permission or an official API path is confirmed for crosswords, decide whether Quick, Cryptic, or both should be supported first.

4. **Publisher token/config rotation** — if a licensed source requires tokens or source-specific config, use an update path that does not require an app release, such as a signed remote config for approved source metadata.

5. **Offline pre-fetch timing for licensed daily sources** — once a daily source is allowed, decide between fetch-on-open and a randomized local prefetch window. Avoid server-triggered push unless backend sync/identity becomes a separate approved feature.

6. **Historical archive depth for licensed sources** — cap archive depth according to the publisher agreement, cache policy, and storage budget rather than assuming unlimited archive access.

---

## Sources

- [xword-dl GitHub](https://github.com/thisisparker/xword-dl) — primary reference for all three downloaders; actively maintained
- [xword-dl amuselabsdownloader.py](https://raw.githubusercontent.com/thisisparker/xword-dl/main/src/xword_dl/downloader/amuselabsdownloader.py) — AmuseLabs/LA Times picker token logic
- [xword-dl amuniversaldownloader.py](https://raw.githubusercontent.com/thisisparker/xword-dl/main/src/xword_dl/downloader/amuniversaldownloader.py) — Universal + USA Today downloaders
- [xword-dl guardiandownloader.py](https://raw.githubusercontent.com/thisisparker/xword-dl/main/src/xword_dl/downloader/guardiandownloader.py) — Guardian HTML scraper
- [guardian-crossword-scraper](https://github.com/txsl/guardian-crossword-scraper) — older Guardian scraper (reference only; outdated HTML structure)
- [AmuseLabs PuzzleMe API docs](https://amuselabs.com/docs/api/) — official API requires `client_id`/`client_secret` from AmuseLabs; not used in our approach
- [mycrossword React component](https://github.com/t-blackwell/mycrossword) — confirms Guardian JSON schema structure
