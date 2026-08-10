#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"
PULL_SCRIPT="$REPO_ROOT/bin/pull-pi-files"
DEPLOY_SCRIPT="$REPO_ROOT/bin/deploy-pi-files"
TEST_ROOT=""

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_content() {
  local file="$1"
  local expected="$2"
  [[ -f "$file" ]] || fail "expected file to exist: $file"
  local actual
  actual="$(cat "$file")"
  [[ "$actual" == "$expected" ]] || fail "unexpected content in $file: expected [$expected], got [$actual]"
}

assert_file_exists() {
  local file="$1"
  [[ -f "$file" ]] || fail "expected file to exist: $file"
}

assert_file_missing() {
  local file="$1"
  [[ ! -e "$file" ]] || fail "expected path to be missing: $file"
}

assert_symlink_target() {
  local link="$1"
  local expected="$2"
  [[ -L "$link" ]] || fail "expected symlink: $link"
  local actual
  actual="$(readlink "$link")"
  [[ "$actual" == "$expected" ]] || fail "unexpected symlink target for $link: expected [$expected], got [$actual]"
}

setup_test_repo() {
  TEST_ROOT="$(mktemp -d)"
  mkdir -p "$TEST_ROOT/repo/bin" "$TEST_ROOT/source-home/.pi/agent" "$TEST_ROOT/deploy-home"
  cp "$PULL_SCRIPT" "$TEST_ROOT/repo/bin/pull-pi-files"
  cp "$DEPLOY_SCRIPT" "$TEST_ROOT/repo/bin/deploy-pi-files"
  chmod +x "$TEST_ROOT/repo/bin/pull-pi-files" "$TEST_ROOT/repo/bin/deploy-pi-files"
}

cleanup_test_repo() {
  if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
    rm -rf "$TEST_ROOT"
  fi
}

seed_source_pi_files() {
  local home="$1"
  mkdir -p \
    "$home/.pi/agent/extensions" \
    "$home/.pi/agent/bin" \
    "$home/.pi/agent/lib" \
    "$home/.pi/agent/tests" \
    "$home/.pi/agent/sessions" \
    "$home/.pi/agent/npm"
  printf 'agents\n' > "$home/.pi/agent/AGENTS.md"
  printf '{"packages":[]}\n' > "$home/.pi/agent/settings.json"
  printf 'extension\n' > "$home/.pi/agent/extensions/ai-eos-context.ts"
  printf '#!/usr/bin/env bash\npi-env\n' > "$home/.pi/agent/bin/pi-env"
  printf '#!/usr/bin/env bash\npi-personal\n' > "$home/.pi/agent/bin/pi-personal"
  printf '#!/usr/bin/env bash\npi-work\n' > "$home/.pi/agent/bin/pi-work"
  printf 'preload\n' > "$home/.pi/agent/lib/skip-startup-fd.mjs"
  printf 'test\n' > "$home/.pi/agent/tests/test-ai-eos-checkpointing.mjs"
  printf 'secret\n' > "$home/.pi/agent/auth.json"
  printf 'session\n' > "$home/.pi/agent/sessions/session.jsonl"
  printf 'cache\n' > "$home/.pi/agent/npm/cache-file"
}

test_pull_copies_only_curated_pi_files() {
  setup_test_repo
  trap cleanup_test_repo RETURN
  seed_source_pi_files "$TEST_ROOT/source-home"

  (cd /tmp && PI_SOURCE_HOME="$TEST_ROOT/source-home" "$TEST_ROOT/repo/bin/pull-pi-files") > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/repo/.pi/agent/AGENTS.md" "agents"
  assert_file_content "$TEST_ROOT/repo/.pi/agent/settings.json" '{"packages":[]}'
  assert_file_content "$TEST_ROOT/repo/.pi/agent/extensions/ai-eos-context.ts" "extension"
  assert_file_content "$TEST_ROOT/repo/.pi/agent/bin/pi-env" $'#!/usr/bin/env bash\npi-env'
  assert_file_content "$TEST_ROOT/repo/.pi/agent/lib/skip-startup-fd.mjs" "preload"
  assert_file_content "$TEST_ROOT/repo/.pi/agent/tests/test-ai-eos-checkpointing.mjs" "test"
  assert_file_missing "$TEST_ROOT/repo/.pi/agent/auth.json"
  assert_file_missing "$TEST_ROOT/repo/.pi/agent/sessions/session.jsonl"
  assert_file_missing "$TEST_ROOT/repo/.pi/agent/npm/cache-file"
}

test_deploy_copies_curated_files_and_creates_profile_symlinks() {
  setup_test_repo
  trap cleanup_test_repo RETURN
  mkdir -p "$TEST_ROOT/repo/.pi/agent/extensions" "$TEST_ROOT/repo/.pi/agent/bin" "$TEST_ROOT/repo/.pi/agent/lib" "$TEST_ROOT/repo/.pi/agent/tests"
  printf 'agents\n' > "$TEST_ROOT/repo/.pi/agent/AGENTS.md"
  printf '{"packages":[]}\n' > "$TEST_ROOT/repo/.pi/agent/settings.json"
  printf 'extension\n' > "$TEST_ROOT/repo/.pi/agent/extensions/ai-eos-context.ts"
  printf '#!/usr/bin/env bash\npi-env\n' > "$TEST_ROOT/repo/.pi/agent/bin/pi-env"
  printf '#!/usr/bin/env bash\npi-personal\n' > "$TEST_ROOT/repo/.pi/agent/bin/pi-personal"
  printf '#!/usr/bin/env bash\npi-work\n' > "$TEST_ROOT/repo/.pi/agent/bin/pi-work"
  printf 'preload\n' > "$TEST_ROOT/repo/.pi/agent/lib/skip-startup-fd.mjs"
  printf 'test\n' > "$TEST_ROOT/repo/.pi/agent/tests/test-ai-eos-checkpointing.mjs"
  mkdir -p "$TEST_ROOT/deploy-home/.ai-eos/memory"
  printf 'orientation\n' > "$TEST_ROOT/deploy-home/.ai-eos/AGENT_ORIENTATION_PROMPT.md"
  printf 'user\n' > "$TEST_ROOT/deploy-home/.ai-eos/USER.md"
  printf 'soul\n' > "$TEST_ROOT/deploy-home/.ai-eos/SOUL.md"
  printf 'memory\n' > "$TEST_ROOT/deploy-home/.ai-eos/MEMORY.md"

  (cd /tmp && HOME="$TEST_ROOT/deploy-home" "$TEST_ROOT/repo/bin/deploy-pi-files") > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/deploy-home/.pi/agent/extensions/ai-eos-context.ts" "extension"
  assert_file_content "$TEST_ROOT/deploy-home/.pi/agent/bin/pi-work" $'#!/usr/bin/env bash\npi-work'
  [[ -x "$TEST_ROOT/deploy-home/.pi/agent/bin/pi-work" ]] || fail "expected pi-work to be executable"
  assert_symlink_target "$TEST_ROOT/deploy-home/.pi-personal/extensions" "$TEST_ROOT/deploy-home/.pi/agent/extensions"
  assert_symlink_target "$TEST_ROOT/deploy-home/.pi-work/extensions" "$TEST_ROOT/deploy-home/.pi/agent/extensions"
  assert_symlink_target "$TEST_ROOT/deploy-home/.pi-work/USER.md" "$TEST_ROOT/deploy-home/.ai-eos/USER.md"
  assert_symlink_target "$TEST_ROOT/deploy-home/.pi-personal/MEMORY.md" "$TEST_ROOT/deploy-home/.ai-eos/MEMORY.md"
  [[ -d "$TEST_ROOT/deploy-home/.pi-work/sessions" ]] || fail "expected profile-local sessions directory"
}

test_deploy_refuses_missing_ai_eos_by_default() {
  setup_test_repo
  trap cleanup_test_repo RETURN
  mkdir -p "$TEST_ROOT/repo/.pi/agent"
  printf 'agents\n' > "$TEST_ROOT/repo/.pi/agent/AGENTS.md"

  if (cd /tmp && HOME="$TEST_ROOT/deploy-home" "$TEST_ROOT/repo/bin/deploy-pi-files") > "$TEST_ROOT/output.txt" 2>&1; then
    fail "expected deploy to fail without AI-EOS"
  fi

  grep -q 'AI-EOS orientation file is missing' "$TEST_ROOT/output.txt" || fail "missing AI-EOS failure message"
}

run_test() {
  local name="$1"
  echo "Running $name"
  "$name"
}

run_test test_pull_copies_only_curated_pi_files
run_test test_deploy_copies_curated_files_and_creates_profile_symlinks
run_test test_deploy_refuses_missing_ai_eos_by_default

echo "All pi files sync tests passed"
