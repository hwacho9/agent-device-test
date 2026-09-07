#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
bash scripts/install-ios.sh
run="$(date -u +%Y%m%dT%H%M%SZ)-$$"
xcodebuild -project iosApp/AgentDeviceE2EDemo.xcodeproj -scheme AgentDeviceE2EDemo -destination "platform=iOS Simulator,id=$DEMO_IOS_UDID" -derivedDataPath artifacts/ios/build/DerivedData -resultBundlePath "artifacts/ios/build/smoke-$run.xcresult" -only-testing:AgentDeviceE2EDemoUITests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test 2>&1 | tee "artifacts/ios/build/smoke-$run.log"
