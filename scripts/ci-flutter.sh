#!/usr/bin/env bash
# Resolves (and caches) the exact Flutter SDK pinned by
# .github/workflows/ci.yml's FLUTTER_VERSION, so `make ci` checks the same
# toolchain hosted CI enforces instead of whatever Flutter happens to be on
# PATH. `dart format`'s and `build_runner`'s output can differ across even
# patch versions — a local/CI mismatch here passes clean locally and then
# fails hosted CI on push, burning a real Actions run for nothing.
#
# Prints the pinned SDK's bin/ directory on stdout. Everything else goes to
# stderr so `$(scripts/ci-flutter.sh)` command substitution stays clean.
#
# Usage: PATH="$(scripts/ci-flutter.sh)/bin:$PATH" (or see Makefile)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(grep -m1 "FLUTTER_VERSION:" "$REPO_ROOT/.github/workflows/ci.yml" \
  | sed -E "s/.*'([^']+)'.*/\1/")"

if [[ -z "$VERSION" ]]; then
  echo "✗ Could not parse FLUTTER_VERSION from .github/workflows/ci.yml" >&2
  exit 1
fi

CACHE_DIR="${CROSSCUE_PINNED_FLUTTER_CACHE:-$HOME/.cache/crosscue/flutter-$VERSION}"

if [[ ! -x "$CACHE_DIR/bin/flutter" ]]; then
  echo "▶ setting up pinned Flutter $VERSION at $CACHE_DIR (one-time; cached after)" >&2
  mkdir -p "$(dirname "$CACHE_DIR")"

  # Prefer a worktree off a local Flutter git checkout (fast, no network) if
  # the version's tag is already reachable there; otherwise clone it fresh.
  LOCAL_FLUTTER_BIN="$(command -v flutter || true)"
  LOCAL_FLUTTER_GIT=""
  if [[ -n "$LOCAL_FLUTTER_BIN" ]]; then
    LOCAL_FLUTTER_GIT="$(cd "$(dirname "$LOCAL_FLUTTER_BIN")/.." && pwd)"
  fi

  if [[ -n "$LOCAL_FLUTTER_GIT" && -d "$LOCAL_FLUTTER_GIT/.git" ]] \
     && git -C "$LOCAL_FLUTTER_GIT" rev-parse "$VERSION" >/dev/null 2>&1; then
    git -C "$LOCAL_FLUTTER_GIT" worktree add --detach "$CACHE_DIR" "$VERSION" >&2
  else
    git clone --depth 1 --branch "$VERSION" \
      https://github.com/flutter/flutter.git "$CACHE_DIR" >&2
  fi

  # Warms the SDK (downloads the pinned Dart SDK/engine artifacts) so the
  # first real check isn't silently slow and doesn't race a bare git worktree.
  "$CACHE_DIR/bin/flutter" --version >&2
fi

echo "$CACHE_DIR/bin"
