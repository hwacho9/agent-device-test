#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
selection="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data=json.load(sys.stdin)["devices"]
choices=[]
preferred_name="iPhone 17 Pro"
for runtime, devices in data.items():
    if "iOS" not in runtime: continue
    version=tuple(int(x) for x in runtime.rsplit("iOS-",1)[-1].split("-"))
    for device in devices:
        if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
            preferred=device["name"] == preferred_name
            choices.append((preferred, version, device["name"], device["udid"]))
if not choices: raise SystemExit("No available iPhone Simulator")
_,version,name,udid=max(choices)
print(udid+"|"+name+"|"+".".join(map(str,version)))
')"
IFS='|' read -r udid name version <<< "$selection"
echo "Selected $name / iOS $version / $udid"
if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "DEMO_IOS_UDID=$udid" >> "$GITHUB_ENV"
else
    echo "export DEMO_IOS_UDID=$udid"
fi
