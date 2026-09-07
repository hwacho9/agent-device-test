#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
mode="${1:-validate}"
mkdir -p artifacts/android/visual
if [[ "$mode" == record ]]; then
    ./gradlew :androidApp:updateDebugScreenshotTest 2>&1 | tee artifacts/android/visual/reference-generation.log
elif [[ "$mode" == validate ]]; then
    before="$(python3 scripts/reference-digest.py androidApp/src/screenshotTestDebug/reference)"
    status=0
    ./gradlew :androidApp:validateDebugScreenshotTest 2>&1 | tee artifacts/android/visual/validation.log || status=$?
    after="$(python3 scripts/reference-digest.py androidApp/src/screenshotTestDebug/reference)"
    [[ "$before" == "$after" ]] || { echo 'FAIL: reference changed during validation' >&2; exit 1; }
    python3 scripts/export-android-visual.py
    exit "$status"
else echo 'Usage: android-visual.sh record|validate' >&2; exit 2; fi
python3 scripts/export-android-visual.py
