#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
bash scripts/build-ios.sh
bash scripts/install-ios.sh
bash scripts/prepare-ios-agent-device.sh
mkdir -p artifacts/ios/runtime/explorations
script="artifacts/ios/runtime/explorations/$(date -u +%Y%m%dT%H%M%SZ)-$$.ad"
echo '[AI OBSERVE] Opening fresh iOS session; inspect the actual snapshot below.'
agent-device open "$IOS_APP_ID" --platform ios --udid "$DEMO_IOS_UDID" --session demo-ios --foreground --save-script "$script"
echo "Exploration recording armed: $script"
echo 'Codex: continue from current snapshots, verify each state, then close. Bootstrap alone is not a successful Agent Pass.'
