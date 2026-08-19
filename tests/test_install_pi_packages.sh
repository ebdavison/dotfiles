#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"
SCRIPT_UNDER_TEST="$REPO_ROOT/bin/install-pi-packages"
TEST_ROOT=""

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_repo() {
  TEST_ROOT="$(mktemp -d)"
  mkdir -p "$TEST_ROOT/repo/bin" "$TEST_ROOT/home/.pi-personal" "$TEST_ROOT/home/.pi-work" "$TEST_ROOT/fake-bin"
  cp "$SCRIPT_UNDER_TEST" "$TEST_ROOT/repo/bin/install-pi-packages"
  chmod +x "$TEST_ROOT/repo/bin/install-pi-packages"
  cat > "$TEST_ROOT/fake-bin/pi" <<'PI'
#!/usr/bin/env bash
printf '%s|%s|%s\n' "${PI_ENV:-}" "${PI_CODING_AGENT_DIR:-}" "$*" >> "$PI_TEST_LOG"
PI
  chmod +x "$TEST_ROOT/fake-bin/pi"
  printf '{"packages":["npm:pi-obsidian"]}\n' > "$TEST_ROOT/home/.pi-personal/settings.json"
  printf '{"packages":["npm:pi-subagents"]}\n' > "$TEST_ROOT/home/.pi-work/settings.json"
}

cleanup_repo() {
  if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
    rm -rf "$TEST_ROOT"
  fi
}

run_installer() {
  (cd /tmp && HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/fake-bin:$PATH" PI_TEST_LOG="$TEST_ROOT/pi.log" "$TEST_ROOT/repo/bin/install-pi-packages" "$@")
}

assert_log_line_count() {
  local expected="$1"
  local actual
  actual="$(wc -l < "$TEST_ROOT/pi.log" | tr -d ' ')"
  [[ "$actual" == "$expected" ]] || fail "expected $expected pi calls, got $actual"
}

test_default_reconciles_personal_and_work_profiles() {
  setup_repo
  trap cleanup_repo RETURN

  run_installer > "$TEST_ROOT/output.txt"

  assert_log_line_count 2
  grep -Fq "personal|$TEST_ROOT/home/.pi-personal|update --extensions" "$TEST_ROOT/pi.log" || fail "missing personal update call"
  grep -Fq "work|$TEST_ROOT/home/.pi-work|update --extensions" "$TEST_ROOT/pi.log" || fail "missing work update call"
}

test_profile_option_reconciles_only_requested_profile() {
  setup_repo
  trap cleanup_repo RETURN

  run_installer --profile personal > "$TEST_ROOT/output.txt"

  assert_log_line_count 1
  grep -Fq "personal|$TEST_ROOT/home/.pi-personal|update --extensions" "$TEST_ROOT/pi.log" || fail "missing personal update call"
  if grep -Fq "work|" "$TEST_ROOT/pi.log"; then
    fail "did not expect work update call"
  fi
}

run_test() {
  local name="$1"
  echo "Running $name"
  "$name"
}

run_test test_default_reconciles_personal_and_work_profiles
run_test test_profile_option_reconciles_only_requested_profile

echo "All pi package installer tests passed"
