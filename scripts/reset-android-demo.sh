#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
serial="${DEMO_ANDROID_SERIAL:-emulator-5580}"
actual="$(adb -s "$serial" emu avd name | tr -d '\r' | head -1)"
[[ "$actual" == "$DEMO_AVD" ]] || { echo "Unexpected AVD: $actual" >&2; exit 1; }
adb -s "$serial" shell am force-stop "$ANDROID_APP_ID"
adb -s "$serial" shell pm clear "$ANDROID_APP_ID"
adb -s "$serial" shell am start -W -n "$ANDROID_APP_ID/.MainActivity"
