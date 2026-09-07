#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
workflow=.github/workflows/mobile-e2e.yml
ruby -e 'require "yaml"; YAML.safe_load_file(ARGV.fetch(0), aliases: true)' "$workflow"
python3 - "$workflow" <<'PY'
from pathlib import Path
import re,sys
text=Path(sys.argv[1]).read_text()
required=[
    "pull_request:", "workflow_dispatch:", "cancel-in-progress: true",
    "contents: read", "android-e2e:", "ios-e2e:", "pr-evidence:",
    "android-e2e-evidence", "ios-e2e-evidence", "if: always()",
    "github.event.pull_request.head.repo.full_name == github.repository",
    "PR_MEDIA_MODE: release", "EXPECTED_PR_HEAD_SHA:", "contents: write",
]
missing=[value for value in required if value not in text]
assert not missing, f"Missing workflow policies: {missing}"
for forbidden in ("pull_request_target", "updateDebugScreenshotTest", "SNAPSHOT_RECORD=1", "generate-local-report", "artifacts/local-report"):
    assert forbidden not in text, f"Forbidden in CI: {forbidden}"
uses=re.findall(r"^\s*uses:\s*(\S+)",text,re.MULTILINE)
assert uses and all("@" in value and not value.endswith(("@main","@master","@latest")) for value in uses), uses
assert text.count("continue-on-error: true") == 2, "Only the two non-core artifact downloads may continue on error"
assert "secrets.PR_MEDIA_TOKEN" not in text, "Broad user credentials must not be stored for media publication"
print("Workflow syntax and policy checks: PASS")
PY
