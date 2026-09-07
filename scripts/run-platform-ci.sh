#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
exec python3 scripts/report/run_platform.py "$@"
