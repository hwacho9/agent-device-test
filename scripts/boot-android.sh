#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$ROOT/artifacts/android/runtime"
serial="${DEMO_ANDROID_SERIAL:-emulator-5580}"
if ! adb -s "$serial" get-state >/dev/null 2>&1; then
    nohup emulator -avd "$DEMO_AVD" -port 5580 -no-snapshot -no-boot-anim -no-audio -gpu swiftshader > "$ROOT/artifacts/android/runtime/emulator.log" 2>&1 &
fi
for ((i=0; i<180; i++)); do
    if [[ "$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]]; then
        for setting in window_animation_scale transition_animation_scale animator_duration_scale; do adb -s "$serial" shell settings put global "$setting" 0; done
        adb -s "$serial" shell wm size 1080x2400
        adb -s "$serial" shell wm density 420
        echo "Ready: $serial"; exit 0
    fi
    sleep 1
done
echo "FAIL: Emulator boot timed out. See artifacts/android/runtime/emulator.log" >&2
exit 1
