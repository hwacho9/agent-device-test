#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
bash "$ROOT/scripts/boot-android.sh"
serial="${DEMO_ANDROID_SERIAL:-emulator-5580}"
apk="$ROOT/artifacts/android/build/androidApp-debug.apk"
test -s "$apk"
actual="$(adb -s "$serial" emu avd name | tr -d '\r' | head -1)"
[[ "$actual" == "$DEMO_AVD" ]] || { echo "Refusing to reset unexpected AVD: $actual" >&2; exit 1; }
if adb -s "$serial" shell pm path "$ANDROID_APP_ID" | grep -q package:; then adb -s "$serial" uninstall "$ANDROID_APP_ID"; fi
adb -s "$serial" install "$apk"
adb -s "$serial" shell am start -W -n "$ANDROID_APP_ID/.MainActivity"
