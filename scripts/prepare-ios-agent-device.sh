#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
bash scripts/boot-ios.sh
# Require actual installation before preparing the runner.
xcrun simctl get_app_container "$DEMO_IOS_UDID" "$IOS_APP_ID" >/dev/null
mkdir -p artifacts/ios/runtime
agent-device prepare ios-runner --platform ios --udid "$DEMO_IOS_UDID" --session demo-ios --timeout 180000 2>&1 | tee artifacts/ios/runtime/prepare.log
