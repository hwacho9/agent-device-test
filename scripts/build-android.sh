#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
mkdir -p artifacts/android/build
./gradlew :androidApp:assembleDebug 2>&1 | tee artifacts/android/build/build.log
apk="$ROOT/androidApp/build/outputs/apk/debug/androidApp-debug.apk"
test -s "$apk"
cp "$apk" artifacts/android/build/
stat -f '%N %z bytes' "$apk"
