#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
bash scripts/install-android.sh
mkdir -p artifacts/android/runtime/explorations
script="artifacts/android/runtime/explorations/$(date -u +%Y%m%dT%H%M%SZ)-$$.ad"
echo '[AI OBSERVE] Opening fresh Android session; inspect the actual snapshot below.'
agent-device open "$ANDROID_APP_ID" --platform android --serial "${DEMO_ANDROID_SERIAL:-emulator-5580}" --session demo-android --foreground --save-script "$script"
echo "Exploration recording armed: $script"
echo 'Codex: continue by reading current snapshots and choosing actions. This bootstrap does not execute a prewritten replay or claim PASS.'
