#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
mkdir -p artifacts
summary="artifacts/run-all-$(date -u +%Y%m%dT%H%M%SZ)-$$.txt"
failed=0
step() {
    local name="$1"; shift
    if "$@"; then echo "$name: PASS" | tee -a "$summary"; return 0
    else echo "$name: FAIL" | tee -a "$summary"; failed=1; return 1; fi
}
common_ok=0
if step common-tests ./gradlew :shared:testAndroidHostTest; then common_ok=1; fi
if step android-visual bash scripts/android-visual.sh validate; then
    if step android-build bash scripts/build-android.sh; then
        if [[ "$common_ok" == 1 ]]; then step android-e2e bash scripts/replay-android-e2e.sh || true
        else echo 'android-e2e: BLOCKED by common tests' | tee -a "$summary"; fi
    else echo 'android-e2e: BLOCKED by Android build' | tee -a "$summary"; fi
else echo 'android-build/android-e2e: BLOCKED by Android visual' | tee -a "$summary"; fi
if step ios-visual bash scripts/ios-visual.sh validate; then
    if step ios-build bash scripts/build-ios.sh; then
        if [[ "$common_ok" == 1 ]]; then step ios-e2e bash scripts/replay-ios-e2e.sh || true
        else echo 'ios-e2e: BLOCKED by common tests' | tee -a "$summary"; fi
    else echo 'ios-e2e: BLOCKED by iOS build' | tee -a "$summary"; fi
else echo 'ios-build/ios-e2e: BLOCKED by iOS visual' | tee -a "$summary"; fi
cat "$summary"
exit "$failed"
