#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"
SCRIPT_UNDER_TEST="$REPO_ROOT/bin/install-agent-tools"
TEST_ROOT=""

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

setup_repo() {
  TEST_ROOT="$(mktemp -d)"
  mkdir -p "$TEST_ROOT/repo/bin" "$TEST_ROOT/home/.pi-personal" "$TEST_ROOT/home/.pi-work" "$TEST_ROOT/fake-bin"
  cp "$SCRIPT_UNDER_TEST" "$TEST_ROOT/repo/bin/install-agent-tools"
  chmod +x "$TEST_ROOT/repo/bin/install-agent-tools"
  printf '{"packages":["npm:pi-obsidian"]}\n' > "$TEST_ROOT/home/.pi-personal/settings.json"
  printf '{"packages":["npm:pi-subagents"]}\n' > "$TEST_ROOT/home/.pi-work/settings.json"
  : > "$TEST_ROOT/tool.log"
  write_fake_npm
  write_fake_curl
}

cleanup_repo() {
  if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
    rm -rf "$TEST_ROOT"
  fi
}

write_fake_command() {
  local command="$1"
  cat > "$TEST_ROOT/fake-bin/$command" <<'COMMAND'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" || "${1:-}" == "--help" ]]; then
  echo "fake tool"
fi
COMMAND
  chmod +x "$TEST_ROOT/fake-bin/$command"
}

write_fake_pi() {
  cat > "$TEST_ROOT/fake-bin/pi" <<'PI'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  echo "pi fake"
  exit 0
fi
printf 'pi|%s|%s|%s\n' "${PI_ENV:-}" "${PI_CODING_AGENT_DIR:-}" "$*" >> "$TOOL_LOG"
PI
  chmod +x "$TEST_ROOT/fake-bin/pi"
}

write_fake_npm() {
  cat > "$TEST_ROOT/fake-bin/npm" <<'NPM'
#!/usr/bin/env bash
set -euo pipefail
printf 'npm|%s\n' "$*" >> "$TOOL_LOG"
if [[ "${1:-}" == "install" && "${2:-}" == "-g" ]]; then
  case "${3:-}" in
    @earendil-works/pi-coding-agent)
      cat > "$FAKE_BIN/pi" <<'PI'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  echo "pi fake"
  exit 0
fi
printf 'pi|%s|%s|%s\n' "${PI_ENV:-}" "${PI_CODING_AGENT_DIR:-}" "$*" >> "$TOOL_LOG"
PI
      chmod +x "$FAKE_BIN/pi"
      ;;
    obsidian-headless)
      printf '#!/usr/bin/env bash\necho "ob fake"\n' > "$FAKE_BIN/ob"
      chmod +x "$FAKE_BIN/ob"
      ;;
    @openai/codex)
      printf '#!/usr/bin/env bash\necho "codex fake"\n' > "$FAKE_BIN/codex"
      chmod +x "$FAKE_BIN/codex"
      ;;
    @anthropic-ai/claude-code)
      printf '#!/usr/bin/env bash\necho "claude fake"\n' > "$FAKE_BIN/claude"
      chmod +x "$FAKE_BIN/claude"
      ;;
  esac
fi
NPM
  chmod +x "$TEST_ROOT/fake-bin/npm"
}

write_fake_curl() {
  cat > "$TEST_ROOT/fake-bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
printf 'curl|%s\n' "$*" >> "$TOOL_LOG"
cat <<'INSTALLER'
printf '#!/usr/bin/env bash\necho "herdr fake"\n' > "$FAKE_BIN/herdr"
chmod +x "$FAKE_BIN/herdr"
INSTALLER
CURL
  chmod +x "$TEST_ROOT/fake-bin/curl"
}

install_all_fake_tools() {
  write_fake_pi
  write_fake_command herdr
  write_fake_command ob
  write_fake_command codex
  write_fake_command claude
}

run_installer() {
  local input="$1"
  shift
  printf '%s' "$input" | (
    cd /tmp
    HOME="$TEST_ROOT/home" \
      PATH="$TEST_ROOT/fake-bin:/usr/bin:/bin" \
      TOOL_LOG="$TEST_ROOT/tool.log" \
      FAKE_BIN="$TEST_ROOT/fake-bin" \
      "$TEST_ROOT/repo/bin/install-agent-tools" "$@"
  )
}

assert_log_line_count() {
  local expected="$1"
  local actual
  actual="$(wc -l < "$TEST_ROOT/tool.log" | tr -d ' ')"
  [[ "$actual" == "$expected" ]] || fail "expected $expected tool calls, got $actual"
}

assert_file_exists() {
  [[ -x "$1" ]] || fail "expected executable: $1"
}

test_installs_approved_missing_tools_and_reconciles_profiles() {
  setup_repo
  trap cleanup_repo RETURN

  run_installer $'y\ny\ny\ny\ny\n' > "$TEST_ROOT/output.txt" 2>&1

  grep -Fxq 'npm|install -g @earendil-works/pi-coding-agent' "$TEST_ROOT/tool.log" || fail "missing Pi installation"
  grep -Fxq 'curl|-fsSL https://herdr.dev/install.sh' "$TEST_ROOT/tool.log" || fail "missing Herdr installation"
  grep -Fxq 'npm|install -g obsidian-headless' "$TEST_ROOT/tool.log" || fail "missing Obsidian Headless installation"
  grep -Fxq 'npm|install -g @openai/codex' "$TEST_ROOT/tool.log" || fail "missing Codex installation"
  grep -Fxq 'npm|install -g @anthropic-ai/claude-code' "$TEST_ROOT/tool.log" || fail "missing Claude Code installation"
  assert_file_exists "$TEST_ROOT/fake-bin/pi"
  assert_file_exists "$TEST_ROOT/fake-bin/herdr"
  assert_file_exists "$TEST_ROOT/fake-bin/ob"
  assert_file_exists "$TEST_ROOT/fake-bin/codex"
  assert_file_exists "$TEST_ROOT/fake-bin/claude"
  grep -Fq "pi|personal|$TEST_ROOT/home/.pi-personal|update --extensions" "$TEST_ROOT/tool.log" || fail "missing personal Pi reconciliation"
  grep -Fq "pi|work|$TEST_ROOT/home/.pi-work|update --extensions" "$TEST_ROOT/tool.log" || fail "missing work Pi reconciliation"
}

test_declining_missing_tools_makes_no_installation_or_reconciliation() {
  setup_repo
  trap cleanup_repo RETURN

  run_installer $'n\nn\nn\nn\nn\n' > "$TEST_ROOT/output.txt" 2>&1

  assert_log_line_count 0
  grep -Fq 'Pi package reconciliation skipped: pi is unavailable.' "$TEST_ROOT/output.txt" || fail "missing safe Pi skip message"
}

test_refuses_non_linux_before_prompting_or_tool_invocation() {
  setup_repo
  trap cleanup_repo RETURN
  printf '#!/usr/bin/env bash\necho Darwin\n' > "$TEST_ROOT/fake-bin/uname"
  chmod +x "$TEST_ROOT/fake-bin/uname"

  if run_installer '' > "$TEST_ROOT/output.txt" 2>&1; then
    fail "expected non-Linux host to be rejected"
  fi

  assert_log_line_count 0
  grep -Fq 'install-agent-tools supports Linux only.' "$TEST_ROOT/output.txt" || fail "missing Linux-only failure message"
}

test_profile_option_limits_reconciliation_when_tools_exist() {
  setup_repo
  trap cleanup_repo RETURN
  install_all_fake_tools

  run_installer '' --profile work > "$TEST_ROOT/output.txt" 2>&1

  assert_log_line_count 1
  grep -Fq "pi|work|$TEST_ROOT/home/.pi-work|update --extensions" "$TEST_ROOT/tool.log" || fail "missing work update call"
  if grep -Fq 'pi|personal|' "$TEST_ROOT/tool.log"; then
    fail "did not expect personal profile reconciliation"
  fi
}

run_test() {
  local name="$1"
  echo "Running $name"
  "$name"
}

run_test test_installs_approved_missing_tools_and_reconciles_profiles
run_test test_declining_missing_tools_makes_no_installation_or_reconciliation
run_test test_refuses_non_linux_before_prompting_or_tool_invocation
run_test test_profile_option_limits_reconciliation_when_tools_exist

echo "All agent tool installer tests passed"
