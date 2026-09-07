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
    if explicit:
        candidates = [explicit]
    elif os.environ.get("GITHUB_ACTIONS") == "true":
        candidates = [ROOT / f"artifacts/downloaded/{platform}/{platform}.json"]
    else:
        candidates = [ROOT / f"artifacts/results/{platform}.json"]
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


def evidence_path(base: Path | None, platform: str, name: str) -> Path | None:
    candidates = []
    if base is not None:
        candidates.append(base.parent / "runtime" / name)
    if os.environ.get("GITHUB_ACTIONS") == "true":
        candidates.append(ROOT / "artifacts" / "downloaded" / platform / "runtime" / name)
    else:
        candidates.append(ROOT / "artifacts" / platform / "runtime" / name)
    return next((path for path in candidates if path.is_file() and path.stat().st_size > 0), None)


def evidence_state(base: Path | None, platform: str, name: str) -> str:
    return "AVAILABLE IN WORKFLOW ARTIFACT" if evidence_path(base, platform, name) else "NOT GENERATED"


def attachment_section(
    items: list[tuple[str, str, str, Path | None]], mode: str, media_urls: dict[str, str]
) -> tuple[str, list[str]]:
    statuses = []
    media = []
    for platform, label, kind, path in items:
        if path is None:
            statuses.append(f"- {label}: NOT GENERATED")
            continue
        if mode == "attach":
            statuses.append(f"- {label}: ATTACHED")
            relative = Path(os.path.relpath(path.resolve(), ROOT)).as_posix()
            if kind == "image":
                media.append(f"#### {platform} final screenshot\n\n![{label}]({relative})")
            else:
                # A video reference must be the only content in its paragraph so
                # gh can replace it with a URL that GitHub renders as a player.
                media.append(f"#### {platform} E2E video\n\n![]({relative})")
        elif mode == "release":
            url = media_urls.get(path.name)
            if not url:
                statuses.append(f"- {label}: FAILED — release asset URL unavailable")
            elif kind == "image":
                statuses.append(f"- {label}: UPLOADED")
                media.append(f"#### {platform} final screenshot\n\n![{label}]({url})")
            else:
                statuses.append(f"- {label}: UPLOADED")
                media.append(f"#### {platform} E2E video\n\n[▶ Open {label}]({url})")
        elif mode == "failed":
            statuses.append(f"- {label}: FAILED — use the workflow artifact")
        else:
            statuses.append(f"- {label}: NOT ATTACHED")
    media_section = "\n\n### Media\n\n" + "\n\n".join(media) if media else ""
    return media_section, statuses


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--android-json", type=Path)
    parser.add_argument("--ios-json", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts/pr/pr-summary.md")
    parser.add_argument("--run-url", default=os.environ.get("GITHUB_SERVER_URL", "") and f"{os.environ.get('GITHUB_SERVER_URL')}/{os.environ.get('GITHUB_REPOSITORY')}/actions/runs/{os.environ.get('GITHUB_RUN_ID')}")
    parser.add_argument("--attachment-mode", choices=("none", "attach", "release", "failed"), default="none")
    parser.add_argument("--media-urls-json", type=Path)
    parser.add_argument("--release-url")
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
    attachments = [
        ("Android", "Android final screenshot", "image", evidence_path(android_path, "android", "android-final.png")),
        ("Android", "Android E2E video", "video", evidence_path(android_path, "android", "android-clean-e2e.mp4")),
        ("iOS", "iOS final screenshot", "image", evidence_path(ios_path, "ios", "ios-final.png")),
        ("iOS", "iOS E2E video", "video", evidence_path(ios_path, "ios", "ios-clean-e2e.mp4")),
    ]
    media_urls = {}
    if args.media_urls_json:
        try:
            media_urls = json.loads(args.media_urls_json.read_text())
        except (OSError, json.JSONDecodeError):
            media_urls = {}
    media_section, attachment_statuses = attachment_section(attachments, args.attachment_mode, media_urls)
    release_line = f"- Published media release: {args.release_url}\n" if args.release_url else ""
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
{release_line}{chr(10).join(attachment_statuses)}
- Local HTML: NOT UPLOADED
{media_section}

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
