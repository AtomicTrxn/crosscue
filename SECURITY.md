# Security Policy

## Reporting a vulnerability

Please report security issues **privately** — do not open a public GitHub
issue for anything exploitable.

- **Email:** `atomhess@gmail.com` (subject line starting with `[SECURITY]`)
- You should receive an acknowledgement within **7 days**. This is a solo
  side project, not a staffed security team — but reports are taken
  seriously and fixes for confirmed issues are prioritized over feature work.
- There is **no bug bounty**. Credit in the release notes is offered if you
  want it.

## Scope

In scope:

- The Crosscue app (Flutter, iOS + Android) in this repository.
- The Challenge Boards Worker (`crosscue/backend/challenge_boards/`) and its
  production deployment.
- The release pipeline (GitHub Actions workflows in `.github/workflows/`).

Out of scope:

- Vulnerabilities requiring a compromised device, a compromised
  iCloud/Google account, or physical access.
- Denial-of-service / volumetric testing against the production Worker.
  Please test against a local Worker (`npm run dev` — see
  `crosscue/backend/challenge_boards/README.md`); it runs the identical code.
- Third-party services (Cloudflare, Apple, Google, Crosshare).

## Supported versions

Only the **latest released version** (App Store / Play Store / GitHub
Releases) receives security fixes. There are no maintained older branches.

## Design documentation

The system's trust boundaries, defended threats, and explicitly accepted
risks are documented in
[`docs/architecture/threat-model.md`](docs/architecture/threat-model.md).
Reading it first will tell you whether a finding is a known, accepted
trade-off (e.g., honor-system result submission) or a genuine gap.
