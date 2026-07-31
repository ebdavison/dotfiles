#!/usr/bin/env bash
set -euo pipefail

SCRIPT_UNDER_TEST="${SCRIPT_UNDER_TEST:-$(pwd)/bin/deploy-dotfiles}"
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

assert_file_missing() {
  local file="$1"
  [[ ! -e "$file" ]] || fail "expected path to be missing: $file"
}

setup_repo() {
  TEST_ROOT="$(mktemp -d)"
  mkdir -p "$TEST_ROOT/repo/bin" "$TEST_ROOT/home"
  cp "$SCRIPT_UNDER_TEST" "$TEST_ROOT/repo/bin/deploy-dotfiles"
  chmod +x "$TEST_ROOT/repo/bin/deploy-dotfiles"
}

cleanup_repo() {
  if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
    rm -rf "$TEST_ROOT"
  fi
}

run_deploy() {
  (cd /tmp && HOME="$TEST_ROOT/home" "$TEST_ROOT/repo/bin/deploy-dotfiles" "$@")
}

test_copies_new_allowlisted_file() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo bashrc\n' > "$TEST_ROOT/repo/.bashrc"

  run_deploy > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/home/.bashrc" "repo bashrc"
}

test_skips_identical_file_without_backup() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'same\n' > "$TEST_ROOT/repo/.bashrc"
  printf 'same\n' > "$TEST_ROOT/home/.bashrc"

  run_deploy > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/home/.bashrc" "same"
  assert_file_missing "$TEST_ROOT/home/.dotfiles-deploy-backup"
}

test_refuses_empty_home() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo bashrc\n' > "$TEST_ROOT/repo/.bashrc"

  if (cd /tmp && HOME="" "$TEST_ROOT/repo/bin/deploy-dotfiles") > "$TEST_ROOT/output.txt" 2>&1; then
    fail "expected empty HOME run to fail"
  fi

  grep -q 'Refusing to run with unsafe HOME' "$TEST_ROOT/output.txt" || fail "missing unsafe HOME message"
}

test_refuses_root_home() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo bashrc\n' > "$TEST_ROOT/repo/.bashrc"

  if (cd /tmp && HOME="/" "$TEST_ROOT/repo/bin/deploy-dotfiles") > "$TEST_ROOT/output.txt" 2>&1; then
    fail "expected root HOME run to fail"
  fi

  grep -q 'Refusing to run with unsafe HOME' "$TEST_ROOT/output.txt" || fail "missing unsafe HOME message"
}

run_test() {
  local name="$1"
  echo "Running $name"
  "$name"
}

run_test test_copies_new_allowlisted_file
run_test test_skips_identical_file_without_backup
run_test test_refuses_empty_home
run_test test_refuses_root_home

echo "All deploy-dotfiles tests passed"
