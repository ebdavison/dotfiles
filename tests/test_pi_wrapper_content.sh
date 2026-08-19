#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for wrapper in pi-env pi-personal pi-work; do
  path="$REPO_ROOT/.pi/agent/bin/$wrapper"
  [[ -f "$path" ]] || fail "missing wrapper: $path"
  grep -q 'AI_EOS_HOME' "$path" || fail "$wrapper does not export AI_EOS_HOME"
  grep -q 'AGENT_ORIENTATION_PROMPT.md' "$path" || fail "$wrapper does not enforce AI-EOS orientation"
  grep -q 'PI_SKIP_STARTUP_FD' "$path" || fail "$wrapper does not enable startup fd skip preload"
  if grep -q '/opt/Data/Personal/NextCloud/Notes/AI_Setup' "$path"; then
    fail "$wrapper still references old AI_Setup path"
  fi
done

echo "All Pi wrapper content tests passed"
