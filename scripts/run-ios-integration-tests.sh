#!/usr/bin/env bash
#
# Boots an iOS simulator, runs the Flutter integration_test suite against it,
# and collects a screenshot of each test's final frame into
# design/qa/ios-<git-sha>/.
#
# Usage:
#   scripts/run-ios-integration-tests.sh [simulator-udid-or-name]
#
# Simulator resolution order:
#   1. the first argument (a UDID or a device name substring)
#   2. $SIMULATOR_UDID
#   3. the first already-booted iPhone simulator
#   4. the first available iPhone simulator (it will be booted)
#
# Exits non-zero if any integration test fails. Intended for manual local QA
# and the (manually dispatched) integration-test-ios CI workflow.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/crosscue"

# Extract a simulator UDID (uppercase-hex with dashes, 36 chars) from a name or
# UDID hint, falling back to a booted, then any available, iPhone.
resolve_sim() {
  local hint="${1:-${SIMULATOR_UDID:-}}"
  if [[ -n "$hint" ]]; then
    xcrun simctl list devices | grep -F "$hint" \
      | grep -oE '[0-9A-F-]{36}' | head -1 && return 0
  fi
  xcrun simctl list devices booted | grep -i iphone \
    | grep -oE '[0-9A-F-]{36}' | head -1 && return 0
  xcrun simctl list devices available | grep -i iphone \
    | grep -oE '[0-9A-F-]{36}' | head -1 && return 0
}

UDID="$(resolve_sim "${1:-}" || true)"
if [[ -z "${UDID:-}" ]]; then
  echo "ERROR: no iOS simulator found. Install one via Xcode > Settings > Components." >&2
  exit 1
fi

echo "==> Simulator: $UDID"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true

SHA="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
OUT_DIR="$REPO_ROOT/design/qa/ios-$SHA"
mkdir -p "$OUT_DIR"
echo "==> Screenshots: $OUT_DIR"

cd "$APP_DIR"
flutter pub get >/dev/null

fail=0
shopt -s nullglob
tests=(integration_test/*_test.dart)
if [[ ${#tests[@]} -eq 0 ]]; then
  echo "ERROR: no integration tests found in crosscue/integration_test/." >&2
  exit 1
fi

for test_file in "${tests[@]}"; do
  name="$(basename "$test_file" .dart)"
  echo ""
  echo "──> $name"
  if flutter test "$test_file" -d "$UDID"; then
    echo "    PASS: $name"
  else
    echo "    FAIL: $name"
    fail=1
  fi
  # Best-effort final-frame screenshot. (Per-step capture would need the
  # integration_test_driver_extended harness — a future enhancement.)
  xcrun simctl io "$UDID" screenshot "$OUT_DIR/$name.png" >/dev/null 2>&1 || true
done

echo ""
if [[ "$fail" -ne 0 ]]; then
  echo "==> Integration suite FAILED. Screenshots in $OUT_DIR" >&2
  exit 1
fi
echo "==> Integration suite PASSED. Screenshots in $OUT_DIR"
