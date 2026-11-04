#!/usr/bin/env bash
# Brings the Android device (CI emulator) back to a usable adb state and
# prints its serial on stdout. T-018, ADVISOR_REPLY-004 Action 2 (ESC-004):
# on ff28a4f the emulator left `adb devices` between two attempts, so the
# second attempt failed with "No supported devices found".
#
# A healthy device (state 'device', boot completed) is not touched.
#
# Usage: serial="$(bash tool/ci/android_device_ready.sh [emulator-log])"
# Env:   DEVICE_WAIT_SECONDS (default 180) limits each of the two waits.
# Diagnostics go to stderr; on failure it prints `adb devices -l` and the
# last 200 lines of the emulator log, then exits non-zero. It never hides a
# crash: a device that does not come back is a failure.
set -euo pipefail

log="${1:-}"
wait_s="${DEVICE_WAIT_SECONDS:-180}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
adb="${ADB:-$sdk/platform-tools/adb}"

fail() {
  echo "::error title=android device not ready::$1" >&2
  echo "---- adb devices -l ----" >&2
  "$adb" devices -l >&2 || true
  if [ -n "$log" ] && [ -f "$log" ]; then
    echo "---- last 200 lines of $log ----" >&2
    tail -n 200 "$log" >&2 || true
  fi
  exit 1
}

# Restart adb only when the device is not already usable: on 348f41d an
# unconditional restart before a healthy first attempt was followed by a hang
# after the APK install, so a healthy device is left alone.
state="$("$adb" get-state 2>/dev/null | tr -d '\r' || true)"
boot="$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
if [ "$state" = "device" ] && [ "$boot" = "1" ]; then
  echo "android device already usable; adb not restarted" >&2
else
  echo "android device not usable (state='${state}', boot='${boot}'); restarting adb" >&2
  "$adb" kill-server >/dev/null 2>&1 || true
  "$adb" start-server >&2 || fail "adb start-server failed"
fi

timeout "$wait_s" "$adb" wait-for-device >&2 \
  || fail "no device within ${wait_s}s (adb wait-for-device)"

deadline=$((SECONDS + wait_s))
until [ "$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  [ "$SECONDS" -lt "$deadline" ] || fail "sys.boot_completed is not 1 within ${wait_s}s"
  sleep 3
done

serial="$("$adb" devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
[ -n "$serial" ] || fail "no device in state 'device' after boot"
echo "android device ready: $serial" >&2
echo "$serial"
