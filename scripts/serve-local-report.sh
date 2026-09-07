#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
port="${LOCAL_REPORT_PORT:-8080}"
python3 - "$port" <<'PY'
import socket, sys
port = int(sys.argv[1])
with socket.socket() as sock:
    try:
        sock.bind(("127.0.0.1", port))
    except OSError as error:
        raise SystemExit(
            f"Port {port} is unavailable: {error}\n"
            f"Try: LOCAL_REPORT_PORT={port + 1} ./scripts/serve-local-report.sh"
        )
PY
test -s artifacts/local-report/index.html || ./scripts/generate-local-report.sh
url="http://127.0.0.1:$port"
echo "Serving local-only report at $url"
if [[ "$(uname -s)" == Darwin && "${LOCAL_REPORT_NO_OPEN:-0}" != 1 ]]; then
    open "$url" >/dev/null 2>&1 || true
fi
exec python3 -m http.server "$port" --bind 127.0.0.1 --directory artifacts/local-report
