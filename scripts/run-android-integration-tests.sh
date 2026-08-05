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
# Each test gets both Flutter's test timeout and a process watchdog. The
# watchdog covers failures outside the Dart test framework (for example, a
# device install/attach that never returns). Override for local diagnostics.
TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-600}"
PROCESS_TIMEOUT_SECONDS="${PROCESS_TIMEOUT_SECONDS:-720}"

run_with_timeout() {
  "$@" &
  local test_pid=$!
  (
    sleep "$PROCESS_TIMEOUT_SECONDS"
    if kill -0 "$test_pid" 2>/dev/null; then
      echo "ERROR: timed out after ${PROCESS_TIMEOUT_SECONDS}s: $*" >&2
      kill -TERM "$test_pid" 2>/dev/null || true
      sleep 5
      kill -KILL "$test_pid" 2>/dev/null || true
    fi
  ) &
  local watchdog_pid=$!
  local status=0
  wait "$test_pid" || status=$?
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  return "$status"
}

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
  # Scope logcat to this test only, so a failure's dump isn't drowned in
  # noise from earlier tests or emulator boot.
  adb -s "$SERIAL" logcat -c 2>/dev/null || true
  if run_with_timeout flutter test "$test_file" -d "$SERIAL" --timeout "${TEST_TIMEOUT_SECONDS}s"; then
    echo "    PASS: $name"
  else
    echo "    FAIL: $name"
    fail=1
    # A hang here has no Dart-side output to explain it (e.g. the app never
    # reached the VM service handshake) — the device-side logcat and process
    # list are the only signal for what actually happened.
    adb -s "$SERIAL" logcat -d > "$OUT_DIR/$name.logcat.txt" 2>&1 || true
    adb -s "$SERIAL" shell ps -A > "$OUT_DIR/$name.ps.txt" 2>&1 || true
  fi
  # Best-effort final-frame screenshot. (Per-step capture would need the
  # integration_test_driver_extended harness — a future enhancement.)
  adb -s "$SERIAL" exec-out screencap -p > "$OUT_DIR/$name.png" 2>/dev/null || true
  # Subsequent tests cannot make a failing release candidate healthy, and
  # stopping here keeps CI feedback prompt when the device/test runner breaks.
  if [[ "$fail" -ne 0 ]]; then
    break
  fi
done

echo ""
if [[ "$fail" -ne 0 ]]; then
  echo "==> Integration suite FAILED. Screenshots in $OUT_DIR" >&2
  exit 1
fi
echo "==> Integration suite PASSED. Screenshots in $OUT_DIR"
