#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
mkdir -p artifacts/ios/build
xcodebuild -project iosApp/AgentDeviceE2EDemo.xcodeproj -scheme AgentDeviceE2EDemo -configuration Debug -sdk iphonesimulator -destination "platform=iOS Simulator,id=$DEMO_IOS_UDID" -derivedDataPath "$ROOT/artifacts/ios/build/DerivedData" CODE_SIGNING_ALLOWED=NO build 2>&1 | tee artifacts/ios/build/build.log
app="$ROOT/artifacts/ios/build/DerivedData/Build/Products/Debug-iphonesimulator/AgentDeviceE2EDemo.app"
test -s "$app/AgentDeviceE2EDemo"
test -s "$app/Frameworks/Shared.framework/Shared"
python3 - "$app" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); print(f'{p}: {sum(f.stat().st_size for f in p.rglob("*") if f.is_file())} bytes')
PY
