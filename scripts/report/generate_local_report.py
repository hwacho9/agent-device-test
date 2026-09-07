#!/usr/bin/env python3
"""Generate a self-contained local index from JSON results and copied evidence."""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ALLOWED = {"pass", "fail", "not_run", "not_applicable"}
CHECK_NAMES = {"build": "Build", "visual": "Visual Regression", "e2e": "Runtime E2E"}


def empty(platform: str) -> dict:
    check = {"status": "not_run", "durationSeconds": 0, "log": None}
    return {
        "platform": platform, "generatedAt": None, "commitSha": None,
        "environment": {"device": None, "osVersion": None, "agentDeviceVersion": None},
        "checks": {
            "build": dict(check),
            "visual": {**check, "reference": None, "current": None, "diff": None},
            "e2e": {**check, "scenario": None, "video": None, "finalScreenshot": None,
                    "failureScreenshot": None, "appLog": None, "runnerLog": None},
        },
        "overallStatus": "not_run", "firstFailure": None,
    }


def load_result(path: Path, platform: str) -> dict:
    if not path.is_file():
        return empty(platform)
    try:
        result = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        result = empty(platform)
        result["overallStatus"] = "fail"
        result["firstFailure"] = {"check": "result_json", "exitCode": None, "log": None}
        return result
    for name in CHECK_NAMES:
        result.setdefault("checks", {}).setdefault(name, empty(platform)["checks"][name])
        if result["checks"][name].get("status") not in ALLOWED:
            result["checks"][name]["status"] = "fail"
    if result.get("overallStatus") not in ALLOWED:
        result["overallStatus"] = "fail"
    return result


class Assets:
    def __init__(self, output: Path):
        self.root = output / "assets"
        self.root.mkdir(parents=True, exist_ok=True)
        self.used: set[str] = set()

    def copy(self, source_value: str | None, platform: str, label: str) -> str | None:
        if not source_value:
            return None
        source = (ROOT / source_value).resolve()
        try:
            source.relative_to(ROOT)
        except ValueError:
            return None
        if not source.is_file():
            return None
        safe_label = re.sub(r"[^a-z0-9-]+", "-", label.lower()).strip("-")
        name = f"{platform}-{safe_label}{source.suffix.lower()}"
        counter = 2
        while name in self.used:
            name = f"{platform}-{safe_label}-{counter}{source.suffix.lower()}"
            counter += 1
        self.used.add(name)
        destination = self.root / name
        shutil.copy2(source, destination)
        if destination.suffix.lower() in {".log", ".txt"}:
            content = destination.read_text(errors="replace")
            content = content.replace(str(ROOT), "$REPO").replace(str(Path.home()), "$HOME")
            destination.write_text(content)
        return f"assets/{name}"


def badge(status: str) -> str:
    label = status.replace("_", " ").upper()
    return f'<span class="badge {html.escape(status)}">{html.escape(label)}</span>'


def media(value: str | None, kind: str, caption: str) -> str:
    caption_html = html.escape(caption)
    if not value:
        return f'<figure class="missing"><div>NOT GENERATED</div><figcaption>{caption_html}</figcaption></figure>'
    escaped = html.escape(value, quote=True)
    if kind == "video":
        body = f'<video controls preload="metadata"><source src="{escaped}" type="video/mp4"></video>'
    else:
        body = f'<a href="{escaped}"><img src="{escaped}" alt="{caption_html}"></a>'
    return f'<figure>{body}<figcaption>{caption_html} · <code>{html.escape(Path(value).name)}</code></figcaption></figure>'


def link(value: str | None, label: str) -> str:
    return f'<a href="{html.escape(value, quote=True)}">{html.escape(label)}</a>' if value else "NOT GENERATED"


def render_platform(platform: str, result: dict, assets: Assets) -> str:
    title = "Android" if platform == "android" else "iOS"
    visual = result["checks"]["visual"]
    e2e = result["checks"]["e2e"]
    copied = {}
    for key, label in (("reference", "visual-reference"), ("current", "visual-current"), ("diff", "visual-diff")):
        copied[key] = assets.copy(visual.get(key), platform, label)
    for key, label in (("video", "e2e-video"), ("finalScreenshot", "final-screenshot"),
                       ("failureScreenshot", "failure-screenshot"), ("log", "e2e-log"),
                       ("appLog", "app-log"), ("runnerLog", "runner-log")):
        copied[key] = assets.copy(e2e.get(key), platform, label)
    visual_log = assets.copy(visual.get("log") or visual.get("sourceLog"), platform, "visual-log")
    first = result.get("firstFailure")
    first_failure = "None" if not first else f"{first.get('check', 'unknown')} (exit {first.get('exitCode', 'unknown')})"
    return f'''
    <section id="{platform}">
      <h2>{title}</h2>
      <p>Overall {badge(result.get("overallStatus", "not_run"))} · First failure: {html.escape(first_failure)}</p>
      <h3>Visual Regression</h3>
      <p>{badge(visual.get("status", "not_run"))} · {visual.get("durationSeconds", 0)} s · Log: {link(visual_log, "open")}</p>
      <div class="media-grid">
        {media(copied["reference"], "image", "Approved reference used for comparison")}
        {media(copied["current"], "image", "Current render produced by validation")}
        {media(copied["diff"], "image", "Diff emitted only when available")}
      </div>
      <h3>Runtime E2E</h3>
      <p>{badge(e2e.get("status", "not_run"))} · {e2e.get("durationSeconds", 0)} s</p>
      <p class="scenario">{html.escape(e2e.get("scenario") or "Scenario NOT GENERATED")}</p>
      <div class="media-grid">
        {media(copied["video"], "video", "Deterministic replay recording")}
        {media(copied["finalScreenshot"], "image", "Final state after assertions")}
        {media(copied["failureScreenshot"], "image", "Failure state, when E2E fails")}
      </div>
      <p>Execution log: {link(copied["log"], "open")} · App log: {link(copied["appLog"], "open")} · Runner log: {link(copied["runnerLog"], "open")}</p>
    </section>'''


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", type=Path, default=ROOT / "artifacts/results")
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts/local-report")
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    assets = Assets(output)
    results = {name: load_result(args.results_dir / f"{name}.json", name) for name in ("android", "ios")}

    rows = []
    for platform, result in results.items():
        for check, label in CHECK_NAMES.items():
            rows.append(f"<tr><td>{platform.title()} {label}</td><td>{badge(result['checks'][check]['status'])}</td></tr>")
    overall = "fail" if any(item["overallStatus"] == "fail" for item in results.values()) else (
        "pass" if all(item["overallStatus"] == "pass" for item in results.values()) else "not_run"
    )
    first = results["android"] if results["android"].get("generatedAt") else results["ios"]
    environments = "".join(
        f"<li>{name.title()}: {html.escape(str(value['environment'].get('device') or 'NOT AVAILABLE'))} · "
        f"OS {html.escape(str(value['environment'].get('osVersion') or 'NOT AVAILABLE'))}</li>"
        for name, value in results.items()
    )
    agent_versions = sorted({str(value["environment"].get("agentDeviceVersion")) for value in results.values() if value["environment"].get("agentDeviceVersion")})
    document = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>agent-device local evidence</title><style>
:root{{--bg:#f4f7f5;--card:#fff;--ink:#18211d;--muted:#637069;--accent:#087f68;--border:#dce5e0;--fail:#b42318;--warn:#8a5b00}}
*{{box-sizing:border-box}} body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.55 system-ui,-apple-system,sans-serif}}
main{{max-width:1180px;margin:auto;padding:32px 20px 64px}} section{{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:24px;margin:20px 0;box-shadow:0 6px 24px #173d2b0b}}
h1,h2,h3{{line-height:1.2}} h1{{font-size:clamp(28px,5vw,48px);margin-bottom:6px}} h2{{margin-top:0}} .eyebrow{{color:var(--accent);font-weight:700;letter-spacing:.08em;text-transform:uppercase}}
table{{border-collapse:collapse;width:100%}} td,th{{text-align:left;padding:10px;border-bottom:1px solid var(--border)}} .badge{{display:inline-block;border-radius:999px;padding:3px 9px;font-weight:800;font-size:12px;background:#e8ecea}}
.badge.pass{{background:#d9f7e8;color:#05603a}} .badge.fail{{background:#fee4e2;color:var(--fail)}} .badge.not_run,.badge.not_applicable{{background:#fff2cc;color:var(--warn)}}
.media-grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px}} figure{{margin:0;border:1px solid var(--border);border-radius:12px;overflow:hidden;background:#fafcfb}} img,video{{width:100%;max-height:520px;display:block;object-fit:contain;background:#111}} figcaption{{padding:10px;color:var(--muted);font-size:13px;overflow-wrap:anywhere}}
.missing div{{min-height:180px;display:grid;place-items:center;color:var(--muted);font-weight:800;background:repeating-linear-gradient(135deg,#f7f9f8,#f7f9f8 10px,#eef2f0 10px,#eef2f0 20px)}} code{{font-size:12px}} a{{color:var(--accent)}} .scenario{{font-weight:650}}
@media(max-width:600px){{main{{padding:20px 12px}}section{{padding:16px}}td,th{{padding:8px 5px}}}}
</style></head><body><main>
<p class="eyebrow">Local evidence · offline</p><h1>agent-device Mobile E2E</h1>
<section><h2>Summary</h2><p>Overall {badge(overall)}</p><table><thead><tr><th>Check</th><th>Result</th></tr></thead><tbody>{''.join(rows)}</tbody></table>
<p>Commit: <code>{html.escape(str(first.get('commitSha') or 'NOT AVAILABLE'))}</code><br>Generated: {html.escape(str(first.get('generatedAt') or 'NOT AVAILABLE'))}<br>agent-device: {html.escape(', '.join(agent_versions) or 'NOT AVAILABLE')}</p><ul>{environments}</ul></section>
{render_platform('android', results['android'], assets)}
{render_platform('ios', results['ios'], assets)}
</main></body></html>'''
    if re.search(r"(?:https?:)?//", document, re.IGNORECASE):
        raise SystemExit("Refusing to generate a report containing an external URL")
    (output / "index.html").write_text(document)
    print(f"Generated {output / 'index.html'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
