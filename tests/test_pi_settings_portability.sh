#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"
SETTINGS="$REPO_ROOT/.pi/agent/settings.json"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$SETTINGS" ]] || fail "missing $SETTINGS"

python3 - "$SETTINGS" <<'PY'
import json
import sys
from pathlib import Path
settings = json.loads(Path(sys.argv[1]).read_text())
extensions = settings.get("extensions", [])
if "./extensions/ai-eos-context.ts" not in extensions:
    raise SystemExit("settings.json should use settings-relative ./extensions/ai-eos-context.ts")
for entry in extensions:
    if isinstance(entry, str) and entry.startswith("/home/"):
        raise SystemExit(f"settings.json has non-portable home-specific extension path: {entry}")
PY

echo "All Pi settings portability tests passed"
