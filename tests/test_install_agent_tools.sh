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
  printf 'ID=fedora\nID_LIKE="rhel fedora"\n' > "$TEST_ROOT/os-release"
  : > "$TEST_ROOT/tool.log"
  write_fake_npm
  write_fake_curl
  write_fake_sudo
  write_fake_package_manager dnf
  write_fake_package_manager apt-get
  write_fake_node v20.19.0
  for command in bash mktemp rm uname; do
    ln -s "/usr/bin/$command" "$TEST_ROOT/fake-bin/$command"
  done
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

write_fake_node() {
  local version="$1"
  cat > "$TEST_ROOT/fake-bin/node" <<NODE
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
  echo "$version"
fi
NODE
  chmod +x "$TEST_ROOT/fake-bin/node"
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
if [[ "${1:-}" == "--version" ]]; then
  echo "10.9.8"
  exit 0
fi
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

write_failing_fake_npm() {
  cat > "$TEST_ROOT/fake-bin/npm" <<'NPM'
#!/usr/bin/env bash
printf 'npm|%s\n' "$*" >> "$TOOL_LOG"
exit 1
NPM
  chmod +x "$TEST_ROOT/fake-bin/npm"
}

write_fake_curl() {
  cat > "$TEST_ROOT/fake-bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
printf 'curl|%s\n' "$*" >> "$TOOL_LOG"
if [[ "$*" == *nodesource.com/setup_22.x* ]]; then
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-o" ]]; then
      printf ':\n' > "$2"
      exit 0
    fi
    shift
  done
  exit 1
fi
cat <<'INSTALLER'
printf '#!/usr/bin/env bash\necho "herdr fake"\n' > "$FAKE_BIN/herdr"
chmod +x "$FAKE_BIN/herdr"
INSTALLER
CURL
  chmod +x "$TEST_ROOT/fake-bin/curl"
}

write_fake_sudo() {
  cat > "$TEST_ROOT/fake-bin/sudo" <<'SUDO'
#!/usr/bin/env bash
set -euo pipefail
printf 'sudo|%s\n' "$*" >> "$TOOL_LOG"
if [[ "${1:-}" == "-E" ]]; then
  shift
fi
exec "$@"
SUDO
  chmod +x "$TEST_ROOT/fake-bin/sudo"
}

write_fake_package_manager() {
  local manager="$1"
  cat > "$TEST_ROOT/fake-bin/$manager" <<MANAGER
#!/usr/bin/env bash
set -euo pipefail
printf '$manager|%s\\n' "\$*" >> "\$TOOL_LOG"
if [[ "\${1:-}" == "install" && "\${2:-}" == "-y" && "\${3:-}" == "nodejs" ]]; then
  cat > "\$FAKE_BIN/node" <<'NODE'
#!/usr/bin/env bash
if [[ "\${1:-}" == "--version" ]]; then
  echo "v22.23.2"
fi
NODE
  chmod +x "\$FAKE_BIN/node"
fi
MANAGER
  chmod +x "$TEST_ROOT/fake-bin/$manager"
}

install_all_fake_tools() {
  write_fake_node v22.23.2
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
      PATH="${TEST_PATH:-$TEST_ROOT/fake-bin:/usr/bin:/bin}" \
      TOOL_LOG="$TEST_ROOT/tool.log" \
      FAKE_BIN="$TEST_ROOT/fake-bin" \
      INSTALL_AGENT_TOOLS_OS_RELEASE="$TEST_ROOT/os-release" \
      /usr/bin/bash "$TEST_ROOT/repo/bin/install-agent-tools" "$@"
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

test_replaces_out_of_policy_nodejs_then_installs_approved_agent_tools_and_reconciles_profiles() {
  setup_repo
  trap cleanup_repo RETURN

  run_installer $'y\ny\ny\ny\ny\ny\n' > "$TEST_ROOT/output.txt" 2>&1

  grep -Eq '^curl\|-fsSL https://rpm\.nodesource\.com/setup_22\.x -o /tmp/' "$TEST_ROOT/tool.log" || fail "missing RPM NodeSource bootstrap"
  grep -Fxq 'dnf|install -y nodejs' "$TEST_ROOT/tool.log" || fail "missing Node.js installation"
  grep -Fxq 'npm|install -g @earendil-works/pi-coding-agent' "$TEST_ROOT/tool.log" || fail "missing Pi installation"
  grep -Fxq 'curl|-fsSL https://herdr.dev/install.sh' "$TEST_ROOT/tool.log" || fail "missing Herdr installation"
  grep -Fxq 'npm|install -g obsidian-headless' "$TEST_ROOT/tool.log" || fail "missing Obsidian Headless installation"
  grep -Fxq 'npm|install -g @openai/codex' "$TEST_ROOT/tool.log" || fail "missing Codex installation"
  grep -Fxq 'npm|install -g @anthropic-ai/claude-code' "$TEST_ROOT/tool.log" || fail "missing Claude Code installation"
  assert_file_exists "$TEST_ROOT/fake-bin/node"
  assert_file_exists "$TEST_ROOT/fake-bin/pi"
  assert_file_exists "$TEST_ROOT/fake-bin/herdr"
  assert_file_exists "$TEST_ROOT/fake-bin/ob"
  assert_file_exists "$TEST_ROOT/fake-bin/codex"
  assert_file_exists "$TEST_ROOT/fake-bin/claude"
  grep -Fq "pi|personal|$TEST_ROOT/home/.pi-personal|update --extensions" "$TEST_ROOT/tool.log" || fail "missing personal Pi reconciliation"
  grep -Fq "pi|work|$TEST_ROOT/home/.pi-work|update --extensions" "$TEST_ROOT/tool.log" || fail "missing work Pi reconciliation"
}

test_installs_nodejs_22_from_deb_nodesource_on_ubuntu() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'ID=ubuntu\nID_LIKE=debian\n' > "$TEST_ROOT/os-release"

  run_installer $'y\nn\nn\nn\nn\nn\n' > "$TEST_ROOT/output.txt" 2>&1

  grep -Eq '^curl\|-fsSL https://deb\.nodesource\.com/setup_22\.x -o /tmp/' "$TEST_ROOT/tool.log" || fail "missing DEB NodeSource bootstrap"
  grep -Fxq 'apt-get|install -y nodejs' "$TEST_ROOT/tool.log" || fail "missing apt Node.js installation"
}

test_replaces_outdated_node_before_agent_tool_checks() {
  setup_repo
  trap cleanup_repo RETURN
  write_fake_node v20.19.0

  run_installer $'y\nn\nn\nn\nn\nn\n' > "$TEST_ROOT/output.txt" 2>&1

  grep -Fxq 'dnf|install -y nodejs' "$TEST_ROOT/tool.log" || fail "missing Node.js 22 upgrade"
  grep -Fq 'Node.js 22.x and npm are missing or out of policy.' "$TEST_ROOT/output.txt" || fail "missing Node.js policy prompt"
}

test_failed_npm_validation_skips_npm_tools_but_offers_herdr() {
  setup_repo
  trap cleanup_repo RETURN
  write_fake_node v22.23.2
  write_failing_fake_npm

  run_installer $'y\ny\n' > "$TEST_ROOT/output.txt" 2>&1

  grep -Fxq 'npm|--version' "$TEST_ROOT/tool.log" || fail "missing npm validation"
  grep -Fxq 'dnf|install -y nodejs' "$TEST_ROOT/tool.log" || fail "missing attempted Node.js repair"
  assert_file_exists "$TEST_ROOT/fake-bin/herdr"
  if grep -Fq 'npm|install -g' "$TEST_ROOT/tool.log"; then
    fail "did not expect npm-backed agent installation"
  fi
}

test_missing_node_package_manager_never_runs_nodesource_setup() {
  setup_repo
  trap cleanup_repo RETURN
  rm "$TEST_ROOT/fake-bin/dnf"

  TEST_PATH="$TEST_ROOT/fake-bin" run_installer $'y\nn\n' > "$TEST_ROOT/output.txt" 2>&1

  assert_log_line_count 0
  grep -Fq "Cannot install Node.js 22.x: required command 'dnf' is unavailable." "$TEST_ROOT/output.txt" || fail "missing package-manager prerequisite error"
}

test_default_no_skips_nodejs_and_all_tool_installers() {
  setup_repo
  trap cleanup_repo RETURN

  run_installer '' > "$TEST_ROOT/output.txt" 2>&1

  assert_log_line_count 0
  grep -Fq 'Skipped Node.js 22.x and npm (no answer received).' "$TEST_ROOT/output.txt" || fail "missing default-no Node.js skip message"
}

test_declining_out_of_policy_nodejs_skips_all_npm_agent_installs() {
  setup_repo
  trap cleanup_repo RETURN

  run_installer $'n\nn\nn\nn\nn\nn\n' > "$TEST_ROOT/output.txt" 2>&1

  assert_log_line_count 0
  grep -Fq 'Pi package reconciliation skipped: pi is unavailable.' "$TEST_ROOT/output.txt" || fail "missing safe Pi skip message"
}

test_refuses_unsupported_linux_before_prompting_or_tool_invocation() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'ID=arch\nID_LIKE=arch\n' > "$TEST_ROOT/os-release"

  if run_installer '' > "$TEST_ROOT/output.txt" 2>&1; then
    fail "expected unsupported Linux distribution to be rejected"
  fi

  assert_log_line_count 0
  grep -Fq 'Unsupported Linux distribution for Node.js 22 installation.' "$TEST_ROOT/output.txt" || fail "missing unsupported distribution failure message"
}

test_refuses_non_linux_before_prompting_or_tool_invocation() {
  setup_repo
  trap cleanup_repo RETURN
  rm "$TEST_ROOT/fake-bin/uname"
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

run_test test_replaces_out_of_policy_nodejs_then_installs_approved_agent_tools_and_reconciles_profiles
run_test test_installs_nodejs_22_from_deb_nodesource_on_ubuntu
run_test test_replaces_outdated_node_before_agent_tool_checks
run_test test_failed_npm_validation_skips_npm_tools_but_offers_herdr
run_test test_missing_node_package_manager_never_runs_nodesource_setup
run_test test_default_no_skips_nodejs_and_all_tool_installers
run_test test_declining_out_of_policy_nodejs_skips_all_npm_agent_installs
run_test test_refuses_unsupported_linux_before_prompting_or_tool_invocation
run_test test_refuses_non_linux_before_prompting_or_tool_invocation
run_test test_profile_option_limits_reconciliation_when_tools_exist

echo "All agent tool installer tests passed"
