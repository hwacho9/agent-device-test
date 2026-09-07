#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
state="$(xcrun simctl list devices -j | python3 -c 'import json,sys,os; d=[x for v in json.load(sys.stdin)["devices"].values() for x in v if x["udid"]==os.environ["DEMO_IOS_UDID"] and x.get("isAvailable")]; print(d[0]["state"] if d else "MISSING")')"
[[ "$state" != MISSING ]] || { echo 'Requested Simulator missing' >&2; exit 1; }
if [[ "$state" != Booted ]]; then xcrun simctl boot "$DEMO_IOS_UDID"; fi
xcrun simctl bootstatus "$DEMO_IOS_UDID" -b
