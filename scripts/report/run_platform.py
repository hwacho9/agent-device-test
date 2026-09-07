#!/usr/bin/env python3
"""Run one platform pipeline and write its result contract from process exit codes."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCENARIO = "Login → Home → Profile → Reminder ON → Save → Saved"


def relative(path: Path | None) -> str | None:
    if path is None or not path.exists():
        return None
    return path.resolve().relative_to(ROOT).as_posix()


def first_image(directory: Path, preferred: str) -> Path | None:
    if not directory.exists():
        return None
    candidates = sorted(directory.rglob("*.png"))
    return next((item for item in candidates if preferred in item.name), candidates[0] if candidates else None)


def output(command: list[str]) -> str | None:
    try:
        return subprocess.run(
            command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, timeout=15, check=True,
        ).stdout.strip() or None
    except (OSError, subprocess.SubprocessError):
        return None


def environment(platform: str) -> dict[str, str | None]:
    agent_version = output(["agent-device", "--version"])
    if platform == "android":
        serial = os.environ.get("DEMO_ANDROID_SERIAL", "emulator-5580")
        device = output(["adb", "-s", serial, "shell", "getprop", "ro.product.model"])
        os_version = output(["adb", "-s", serial, "shell", "getprop", "ro.build.version.release"])
        return {"device": f"{device or 'NOT AVAILABLE'} ({serial})", "osVersion": os_version, "agentDeviceVersion": agent_version}

    udid = os.environ.get("DEMO_IOS_UDID", "")
    data = output(["xcrun", "simctl", "list", "devices", "-j"])
    name = None
    runtime = None
    if data:
        parsed = json.loads(data)
        for runtime_key, devices in parsed.get("devices", {}).items():
            for candidate in devices:
                if candidate.get("udid") == udid:
                    name = candidate.get("name")
                    runtime = runtime_key.rsplit(".", 1)[-1].replace("iOS-", "").replace("-", ".")
    return {"device": f"{name or 'NOT AVAILABLE'} ({udid or 'UDID unset'})", "osVersion": runtime, "agentDeviceVersion": agent_version}


def contract(platform: str) -> dict:
    empty = {"status": "not_run", "durationSeconds": 0, "log": None}
    return {
        "platform": platform,
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "commitSha": output(["git", "rev-parse", "HEAD"]),
        "environment": environment(platform),
        "checks": {
            "common": {**empty, "junit": None},
            "build": dict(empty),
            "visual": {**empty, "reference": None, "current": None, "diff": None},
            "e2e": {
                **empty, "scenario": SCENARIO, "video": None,
                "finalScreenshot": None, "failureScreenshot": None,
                "appLog": None, "runnerLog": None, "junit": None,
            },
        },
        "firstFailure": None,
        "overallStatus": "not_run",
    }


def write_result(result: dict, destination: Path) -> None:
    result["generatedAt"] = dt.datetime.now(dt.timezone.utc).isoformat()
    statuses = [result["checks"][name]["status"] for name in ("common", "visual", "build", "e2e")]
    result["overallStatus"] = "fail" if "fail" in statuses else ("pass" if all(value == "pass" for value in statuses) else "not_run")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")


def run_stage(result: dict, destination: Path, platform: str, name: str, command: list[str]) -> bool:
    log = ROOT / "artifacts" / platform / "ci" / f"{name}.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    print(f"[{platform.upper()}] {name}: {' '.join(command)}", flush=True)
    with log.open("w") as handle:
        process = subprocess.Popen(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        assert process.stdout is not None
        for line in process.stdout:
            sys.stdout.write(line)
            handle.write(line)
        code = process.wait()
    check = result["checks"][name]
    check.update(status="pass" if code == 0 else "fail", durationSeconds=round(time.monotonic() - started, 3), log=relative(log))
    if code and result["firstFailure"] is None:
        result["firstFailure"] = {"check": name, "exitCode": code, "log": relative(log)}
    write_result(result, destination)
    return code == 0


def fill_artifacts(result: dict, platform: str) -> None:
    artifacts = ROOT / "artifacts" / platform
    runtime = artifacts / "runtime"
    preferred = "ProfileSaved"
    if platform == "android":
        build_log = artifacts / "build" / "build.log"
        reference = first_image(ROOT / "androidApp/src/screenshotTestDebug/reference", preferred)
        current = first_image(artifacts / "visual/actual", preferred)
        visual_log = artifacts / "visual/validation.log"
        junit = ROOT / "shared/build/test-results/testAndroidHostTest/TEST-com.example.agentdevicee2edemo.shared.DemoSessionTest.xml"
    else:
        build_log = artifacts / "build/build.log"
        reference = first_image(ROOT / "iosApp/AgentDeviceE2EDemoSnapshotTests/__Snapshots__", preferred)
        current = first_image(artifacts / "visual/current", preferred)
        visual_logs = sorted((artifacts / "visual").glob("validate-20*.log"))
        visual_log = visual_logs[-1] if visual_logs else artifacts / "visual/validation.log"
        junit = ROOT / "shared/build/test-results/testAndroidHostTest/TEST-com.example.agentdevicee2edemo.shared.DemoSessionTest.xml"
    result["checks"]["common"]["junit"] = relative(junit)
    result["checks"]["build"]["sourceLog"] = relative(build_log)
    result["checks"]["visual"].update(
        reference=relative(reference), current=relative(current),
        diff=relative(first_image(artifacts / "visual/diff", preferred)),
        sourceLog=relative(visual_log),
    )
    e2e = result["checks"]["e2e"]
    e2e.update(
        video=relative(runtime / f"{platform}-clean-e2e.mp4"),
        finalScreenshot=relative(runtime / f"{platform}-final.png"),
        failureScreenshot=relative(runtime / f"{platform}-failure.png") if e2e["status"] == "fail" else None,
        appLog=relative(runtime / "app.log"), runnerLog=relative(runtime / "runner.log"),
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("platform", choices=("android", "ios"))
    parser.add_argument("--without-recording", action="store_true", help="Use replay without producing an MP4")
    args = parser.parse_args()
    destination = ROOT / "artifacts/results" / f"{args.platform}.json"
    result = contract(args.platform)
    write_result(result, destination)

    common_ok = run_stage(result, destination, args.platform, "common", ["./gradlew", ":shared:testAndroidHostTest"])
    visual_ok = run_stage(result, destination, args.platform, "visual", ["bash", f"scripts/{args.platform}-visual.sh", "validate"])
    build_ok = run_stage(result, destination, args.platform, "build", ["bash", f"scripts/build-{args.platform}.sh"])

    if common_ok and visual_ok and build_ok:
        e2e_script = f"scripts/replay-{args.platform}-e2e.sh" if args.without_recording else f"scripts/record-{args.platform}-clean.sh"
        run_stage(result, destination, args.platform, "e2e", ["bash", e2e_script])
    else:
        result["checks"]["e2e"]["log"] = None

    result["environment"] = environment(args.platform)
    fill_artifacts(result, args.platform)
    write_result(result, destination)
    print(f"[RESULT] {result['overallStatus'].upper()} {destination.relative_to(ROOT)}")
    return 0 if result["overallStatus"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
