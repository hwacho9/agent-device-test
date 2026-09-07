#!/usr/bin/env python3
"""Create the stable-marker PR summary without inferring PASS from artifacts."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MARKER = "<!-- agent-device-mobile-e2e-report -->"
SCENARIO = "Login → Home → Profile → Reminder ON → Save → Saved"


def find_result(platform: str, explicit: Path | None) -> Path | None:
    candidates = [explicit] if explicit else [
        ROOT / f"artifacts/results/{platform}.json",
        ROOT / f"artifacts/downloaded/{platform}/{platform}.json",
    ]
    return next((candidate for candidate in candidates if candidate and candidate.is_file()), None)


def load(platform: str, explicit: Path | None) -> tuple[dict, Path | None]:
    path = find_result(platform, explicit)
    if not path:
        return {"checks": {}, "overallStatus": "not_run"}, None
    try:
        return json.loads(path.read_text()), path
    except (OSError, json.JSONDecodeError):
        return {"checks": {}, "overallStatus": "fail", "firstFailure": {"check": "result_json"}}, path


def status(result: dict, check: str) -> str:
    value = result.get("checks", {}).get(check, {}).get("status", "not_run")
    return {"pass": "PASS", "fail": "FAIL", "not_run": "NOT RUN", "not_applicable": "N/A"}.get(value, "FAIL")


def evidence_state(base: Path | None, platform: str, name: str) -> str:
    if base is None:
        return "NOT GENERATED"
    artifact_root = base.parent
    candidates = [
        artifact_root / "runtime" / name,
        ROOT / "artifacts" / platform / "runtime" / name,
    ]
    return "AVAILABLE IN WORKFLOW ARTIFACT" if any(path.is_file() for path in candidates) else "NOT GENERATED"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--android-json", type=Path)
    parser.add_argument("--ios-json", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts/pr/pr-summary.md")
    parser.add_argument("--run-url", default=os.environ.get("GITHUB_SERVER_URL", "") and f"{os.environ.get('GITHUB_SERVER_URL')}/{os.environ.get('GITHUB_REPOSITORY')}/actions/runs/{os.environ.get('GITHUB_RUN_ID')}")
    args = parser.parse_args()
    android, android_path = load("android", args.android_json)
    ios, ios_path = load("ios", args.ios_json)
    sha = android.get("commitSha") or ios.get("commitSha") or os.environ.get("GITHUB_SHA") or "NOT AVAILABLE"
    generated = android.get("generatedAt") or ios.get("generatedAt") or dt.datetime.now(dt.timezone.utc).isoformat()
    run_url = args.run_url or "NOT AVAILABLE"
    rows = []
    for result, platform in ((android, "Android"), (ios, "iOS")):
        rows.extend((f"| {platform} Build | {status(result, 'build')} |", f"| {platform} Visual | {status(result, 'visual')} |", f"| {platform} Runtime E2E | {status(result, 'e2e')} |"))
    evidence = [
        ("Android final screenshot", evidence_state(android_path, "android", "android-final.png")),
        ("Android E2E video", evidence_state(android_path, "android", "android-clean-e2e.mp4")),
        ("iOS final screenshot", evidence_state(ios_path, "ios", "ios-final.png")),
        ("iOS E2E video", evidence_state(ios_path, "ios", "ios-clean-e2e.mp4")),
    ]
    body = f"""{MARKER}
## agent-device Mobile E2E

| Check | Result |
|---|---|
{chr(10).join(rows)}

### Scenario

{SCENARIO}

### Evidence

{chr(10).join(f'- {label}: {value}' for label, value in evidence)}
- Workflow artifacts: current Actions run
- Direct PR attachments: NOT ATTACHED — `gh pr comment` 2.96.0 exposes no file-upload option; the official issue-comment API accepts comment text only. PNG/MP4 remain in the two workflow artifacts.
- Local HTML: NOT UPLOADED

### Execution

- Commit: `{sha}`
- Workflow run: {run_url}
- Executed at: {generated}
"""
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(body)
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
