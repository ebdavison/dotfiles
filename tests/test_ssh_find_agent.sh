#!/usr/bin/env bash
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/bin/ssh-find-agent.sh"

tmpdir=$(mktemp -d)
cleanup() {
  if [[ -n "${agent_pid:-}" ]]; then
    kill "$agent_pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

agent_dir="$tmpdir/.ssh/agent"
mkdir -p "$agent_dir"

eval "$(ssh-agent -a "$agent_dir/s.test.agent.token" -s)" >/dev/null
agent_pid=$SSH_AGENT_PID

assert_discovers_current_socket() {
  sfa_init
  sfa_find_all_agent_sockets

  if ! grep -Fxq "$SSH_AUTH_SOCK" <<<"$_ssh_agent_sockets"; then
    echo "expected sfa_find_all_agent_sockets to find $SSH_AUTH_SOCK" >&2
    echo "found: $_ssh_agent_sockets" >&2
    exit 1
  fi
}

_DEBUG=0

SSH_FIND_AGENT_PATH="$agent_dir"
assert_discovers_current_socket

SSH_FIND_AGENT_PATH=""
HOME="$tmpdir"
assert_discovers_current_socket
