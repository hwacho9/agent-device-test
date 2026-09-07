#!/usr/bin/env python3
"""Standard-library verification for offline report and missing-artifact behavior."""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    (ROOT / "artifacts").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=ROOT / "artifacts", prefix="report-test-") as temporary:
        temp = Path(temporary)
        results = temp / "results"
        output = temp / "report"
        fixture = temp / "fixture"
        results.mkdir()
        fixture.mkdir()
        (fixture / "reference.png").write_bytes(b"png fixture")
        (fixture / "video.mp4").write_bytes(b"mp4 fixture")
        (fixture / "final.png").write_bytes(b"png fixture")
        reference = (fixture / "reference.png").relative_to(ROOT).as_posix()
        video = (fixture / "video.mp4").relative_to(ROOT).as_posix()
        final = (fixture / "final.png").relative_to(ROOT).as_posix()
        payload = {
            "platform": "android", "generatedAt": "2026-09-07T00:00:00+00:00",
            "commitSha": "test-sha",
            "environment": {"device": "test emulator", "osVersion": "35", "agentDeviceVersion": "0.20.10"},
            "checks": {
                "build": {"status": "pass", "durationSeconds": 1, "log": None},
                "visual": {"status": "pass", "durationSeconds": 2,
                    "reference": reference,
                    "current": None, "diff": None, "log": None},
                "e2e": {"status": "pass", "durationSeconds": 3,
                    "scenario": "Login → Home → Profile → Reminder ON → Save → Saved",
                    "video": video,
                    "finalScreenshot": final,
                    "failureScreenshot": None, "log": None, "appLog": None, "runnerLog": None},
            },
            "overallStatus": "pass", "firstFailure": None,
        }
        (results / "android.json").write_text(json.dumps(payload))
        subprocess.run([
            sys.executable, str(ROOT / "scripts/report/generate_local_report.py"),
            "--results-dir", str(results), "--output", str(output),
        ], cwd=ROOT, check=True)
        index = output / "index.html"
        document = index.read_text()
        assert "Android" in document and "iOS" in document
        assert "NOT GENERATED" in document
        assert not re.search(r"(?:https?:)?//", document, re.IGNORECASE)
        references = re.findall(r'(?:src|href)="([^"]+)"', document)
        assert any(value.endswith(".mp4") for value in references), "MP4 not referenced"
        assert any(value.endswith(".png") for value in references), "PNG not referenced"
        assert all(not Path(value).is_absolute() and (output / value).is_file() for value in references)
    ignored = subprocess.run(
        ["git", "check-ignore", "artifacts/local-report/index.html"], cwd=ROOT,
        stdout=subprocess.DEVNULL,
    ).returncode == 0
    assert ignored, "local report must be ignored by Git"
    print("Local report tests: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
