#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
python3 scripts/report/generate_local_report.py "$@"
