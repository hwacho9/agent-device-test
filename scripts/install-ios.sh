#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
bash "$ROOT/scripts/boot-ios.sh"
app="$ROOT/artifacts/ios/build/DerivedData/Build/Products/Debug-iphonesimulator/AgentDeviceE2EDemo.app"
test -s "$app/Frameworks/Shared.framework/Shared"
if xcrun simctl get_app_container "$DEMO_IOS_UDID" "$IOS_APP_ID" >/dev/null 2>&1; then xcrun simctl uninstall "$DEMO_IOS_UDID" "$IOS_APP_ID"; fi
xcrun simctl install "$DEMO_IOS_UDID" "$app"
xcrun simctl launch "$DEMO_IOS_UDID" "$IOS_APP_ID" -AppleLanguages '(en)' -AppleLocale en_US
