#!/usr/bin/env python3
"""Redact local workspace/home prefixes from copied evidence logs."""

from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    replacements = [(str(ROOT), "$REPO"), (str(Path.home()), "$HOME")]
    github_workspace = os.environ.get("GITHUB_WORKSPACE")
    if github_workspace:
        replacements.insert(0, (github_workspace, "$REPO"))
    for value in sys.argv[1:]:
        path = Path(value)
        try:
            content = path.read_text(errors="replace")
        except OSError as error:
            raise SystemExit(f"Cannot sanitize {path}: {error}")
        for source, replacement in replacements:
            content = content.replace(source, replacement)
        path.write_text(content)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
