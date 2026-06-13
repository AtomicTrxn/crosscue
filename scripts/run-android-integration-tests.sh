#!/usr/bin/env bash
#
# Runs the Flutter integration_test suite against an Android device/emulator
# and collects a screenshot of each test's final frame into
# design/qa/android-<git-sha>/. The Android counterpart of
# run-ios-integration-tests.sh.
#
# Usage:
#   scripts/run-android-integration-tests.sh [adb-serial]
#
# Device resolution order:
#   1. the first argument (an adb serial, e.g. emulator-5554)
#   2. $ANDROID_SERIAL
#   3. the first device adb reports as "device"
#
# Expects an emulator/device to already be running (locally: `emulator -avd …`;
# in CI: provided by reactivecircus/android-emulator-runner). Exits non-zero if
# any integration test fails.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/crosscue"

# Resolve an adb serial from a hint, else the first ready device.
resolve_device() {
  local hint="${1:-${ANDROID_SERIAL:-}}"
  if [[ -n "$hint" ]]; then
    echo "$hint" && return 0
  fi
  adb devices | awk '$2 == "device" { print $1; exit }'
}

SERIAL="$(resolve_device "${1:-}" || true)"
if [[ -z "${SERIAL:-}" ]]; then
  echo "ERROR: no Android device found. Start one with 'emulator -avd <name>'." >&2
  exit 1
fi

echo "==> Device: $SERIAL"
adb -s "$SERIAL" wait-for-device

SHA="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
OUT_DIR="$REPO_ROOT/design/qa/android-$SHA"
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
  if flutter test "$test_file" -d "$SERIAL"; then
    echo "    PASS: $name"
  else
    echo "    FAIL: $name"
    fail=1
  fi
  # Best-effort final-frame screenshot. (Per-step capture would need the
  # integration_test_driver_extended harness — a future enhancement.)
  adb -s "$SERIAL" exec-out screencap -p > "$OUT_DIR/$name.png" 2>/dev/null || true
done

echo ""
if [[ "$fail" -ne 0 ]]; then
  echo "==> Integration suite FAILED. Screenshots in $OUT_DIR" >&2
  exit 1
fi
echo "==> Integration suite PASSED. Screenshots in $OUT_DIR"
