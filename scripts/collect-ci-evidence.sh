#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
platform="${1:-}"
[[ "$platform" == android || "$platform" == ios ]] || { echo 'Usage: collect-ci-evidence.sh android|ios' >&2; exit 2; }
destination="artifacts/ci-evidence/$platform"
rm -rf "$destination"
mkdir -p "$destination/runtime" "$destination/visual" "$destination/logs" "$destination/test-results"
printf 'platform=%s\ncollectedAt=%s\n' "$platform" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$destination/collection-status.txt"
result="artifacts/results/$platform.json"
[[ -f "$result" ]] && cp "$result" "$destination/$platform.json"
for name in "$platform-final.png" "$platform-clean-e2e.mp4" app.log runner.log result.txt; do
    [[ -f "artifacts/$platform/runtime/$name" ]] && cp "artifacts/$platform/runtime/$name" "$destination/runtime/"
done
if [[ -f "$result" ]] && python3 - "$result" <<'PY'
import json,sys
raise SystemExit(0 if json.load(open(sys.argv[1]))["checks"]["e2e"]["status"] == "fail" else 1)
PY
then
    [[ -f "artifacts/$platform/runtime/$platform-failure.png" ]] && cp "artifacts/$platform/runtime/$platform-failure.png" "$destination/runtime/"
fi
if [[ -d "artifacts/$platform/visual" ]]; then
    while IFS= read -r file; do
        relative="${file#artifacts/$platform/visual/}"
        mkdir -p "$destination/visual/$(dirname "$relative")"
        cp "$file" "$destination/visual/$relative"
    done < <(find "artifacts/$platform/visual" -type f \( -name '*.png' -o -name 'validation.log' -o -name 'validate-20*.log' \) | sort)
fi
if [[ "$platform" == ios ]]; then
    python3 - "artifacts/$platform/visual" "$destination/visual/actual" <<'PY'
from pathlib import Path
import re
import shutil
import sys
from urllib.parse import unquote, urlparse

logs = Path(sys.argv[1])
destination = Path(sys.argv[2])
paths = set()
for log in logs.glob("validate-20*.log"):
    for match in re.findall(r'"(file://[^"\n]+/tmp/ScreenSnapshotTests/[^"\n]+\.png)"', log.read_text(errors="replace")):
        paths.add(Path(unquote(urlparse(match).path)))
for source in sorted(paths):
    if source.is_file():
        destination.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination / source.name)
PY
fi
if [[ "$platform" == android ]]; then
    while IFS= read -r file; do cp "$file" "$destination/test-results/"; done < <(find shared/build/test-results -type f -name '*.xml' 2>/dev/null | sort)
else
    [[ -f artifacts/ios/build/build.log ]] && cp artifacts/ios/build/build.log "$destination/logs/"
fi
while IFS= read -r log; do python3 scripts/report/sanitize_logs.py "$log"; done < <(find "$destination" -type f -name '*.log' | sort)
if find "$destination" -type f \( -name '*.html' -o -name '*.apk' \) | grep -q .; then
    echo 'Refusing to collect HTML or APK in CI evidence' >&2
    exit 1
fi
echo "Collected $destination"
