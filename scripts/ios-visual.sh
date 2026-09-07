#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
mode="${1:-validate}"
[[ "$mode" == record || "$mode" == validate ]] || { echo 'Usage: ios-visual.sh record|validate' >&2; exit 2; }
record=0
[[ "$mode" != record ]] || record=1
mkdir -p artifacts/ios/visual/{reference,diff,xcresult}
run="$mode-$(date -u +%Y%m%dT%H%M%SZ)-$$"
if [[ "$mode" == validate ]]; then before="$(python3 scripts/reference-digest.py iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__)"; fi
export SNAPSHOT_ARTIFACTS="$ROOT/artifacts/ios/visual/diff"
xcodebuild -project iosApp/AgentDeviceE2EDemo.xcodeproj -scheme AgentDeviceE2EDemo -destination "platform=iOS Simulator,id=$DEMO_IOS_UDID" -derivedDataPath artifacts/ios/build/DerivedData -resultBundlePath "artifacts/ios/visual/xcresult/$run.xcresult" -only-testing:AgentDeviceE2EDemoSnapshotTests -parallel-testing-enabled NO "SNAPSHOT_RECORD=$record" CODE_SIGNING_ALLOWED=NO test 2>&1 | tee "artifacts/ios/visual/$run.log"
if [[ "$mode" == validate ]]; then
    after="$(python3 scripts/reference-digest.py iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__)"
    [[ "$before" == "$after" ]] || { echo "FAIL: reference changed" >&2; exit 1; }
fi
cp -R iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__/. artifacts/ios/visual/reference/
