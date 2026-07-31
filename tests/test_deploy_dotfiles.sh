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

run_deploy_with_input() {
  local input="$1"
  printf '%b' "$input" | (cd /tmp && HOME="$TEST_ROOT/home" "$TEST_ROOT/repo/bin/deploy-dotfiles")
}

test_conflict_no_skips_without_backup() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo\n' > "$TEST_ROOT/repo/.bashrc"
  printf 'home\n' > "$TEST_ROOT/home/.bashrc"

  run_deploy_with_input 'n\n' > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/home/.bashrc" "home"
  assert_file_missing "$TEST_ROOT/home/.dotfiles-deploy-backup"
}

test_conflict_yes_replaces_and_backs_up() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo\n' > "$TEST_ROOT/repo/.bashrc"
  printf 'home\n' > "$TEST_ROOT/home/.bashrc"

  run_deploy_with_input 'y\n' > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/home/.bashrc" "repo"
  local backup_file
  backup_file="$(find "$TEST_ROOT/home/.dotfiles-deploy-backup" -type f -path '*/.bashrc' -print -quit)"
  [[ -n "$backup_file" ]] || fail "expected .bashrc backup file"
  assert_file_content "$backup_file" "home"
}

test_conflict_diff_then_no_shows_diff_and_skips() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo\n' > "$TEST_ROOT/repo/.bashrc"
  printf 'home\n' > "$TEST_ROOT/home/.bashrc"

  run_deploy_with_input 'd\nn\n' > "$TEST_ROOT/output.txt"

  grep -q '^-home' "$TEST_ROOT/output.txt" || fail "expected old line in diff"
  grep -q '^+repo' "$TEST_ROOT/output.txt" || fail "expected new line in diff"
  assert_file_content "$TEST_ROOT/home/.bashrc" "home"
}

test_directory_conflict_yes_replaces_and_backs_up() {
  setup_repo
  trap cleanup_repo RETURN
  mkdir -p "$TEST_ROOT/repo/.config/i3" "$TEST_ROOT/home/.config/i3"
  printf 'repo config\n' > "$TEST_ROOT/repo/.config/i3/config"
  printf 'home config\n' > "$TEST_ROOT/home/.config/i3/config"

  run_deploy_with_input 'y\n' > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/home/.config/i3/config" "repo config"
  local backup_file
  backup_file="$(find "$TEST_ROOT/home/.dotfiles-deploy-backup" -type f -path '*/.config/i3/config' -print -quit)"
  [[ -n "$backup_file" ]] || fail "expected .config/i3/config backup file"
  assert_file_content "$backup_file" "home config"
}

test_conflict_quit_aborts_before_later_files() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo bashrc\n' > "$TEST_ROOT/repo/.bashrc"
  printf 'home bashrc\n' > "$TEST_ROOT/home/.bashrc"
  printf 'repo vimrc\n' > "$TEST_ROOT/repo/.vimrc"

  if run_deploy_with_input 'q\n' > "$TEST_ROOT/output.txt" 2>&1; then
    fail "expected quit to return non-zero"
  fi

  assert_file_content "$TEST_ROOT/home/.bashrc" "home bashrc"
  assert_file_missing "$TEST_ROOT/home/.vimrc"
  grep -q 'Aborted by user' "$TEST_ROOT/output.txt" || fail "missing abort message"
}

test_directory_deploys_recursively_and_preserves_destination_only_files() {
  setup_repo
  trap cleanup_repo RETURN
  mkdir -p "$TEST_ROOT/repo/.config/i3" "$TEST_ROOT/repo/.config/polybar" "$TEST_ROOT/home/.config/i3" "$TEST_ROOT/home/.config/keep"
  printf 'repo i3\n' > "$TEST_ROOT/repo/.config/i3/config"
  printf 'repo polybar\n' > "$TEST_ROOT/repo/.config/polybar/config.ini"
  printf 'home only\n' > "$TEST_ROOT/home/.config/keep/local.conf"

  run_deploy > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/home/.config/i3/config" "repo i3"
  assert_file_content "$TEST_ROOT/home/.config/polybar/config.ini" "repo polybar"
  assert_file_content "$TEST_ROOT/home/.config/keep/local.conf" "home only"
}

test_missing_allowlist_paths_warn_but_do_not_fail() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'repo bashrc\n' > "$TEST_ROOT/repo/.bashrc"

  run_deploy > "$TEST_ROOT/output.txt" 2> "$TEST_ROOT/error.txt"

  assert_file_content "$TEST_ROOT/home/.bashrc" "repo bashrc"
  grep -q 'WARN: allowlist path missing: .vimrc' "$TEST_ROOT/error.txt" || fail "expected missing .vimrc warning"
}

test_symlink_sources_are_skipped() {
  setup_repo
  trap cleanup_repo RETURN
  printf 'external\n' > "$TEST_ROOT/external-file"
  ln -s "$TEST_ROOT/external-file" "$TEST_ROOT/repo/.bashrc"
  mkdir -p "$TEST_ROOT/repo/.config"
  printf 'real\n' > "$TEST_ROOT/repo/.config/real.conf"
  ln -s "$TEST_ROOT/external-file" "$TEST_ROOT/repo/.config/linked.conf"

  run_deploy > "$TEST_ROOT/output.txt" 2> "$TEST_ROOT/error.txt"

  assert_file_missing "$TEST_ROOT/home/.bashrc"
  assert_file_content "$TEST_ROOT/home/.config/real.conf" "real"
  assert_file_missing "$TEST_ROOT/home/.config/linked.conf"
  grep -q 'WARN: skipping symlink source .bashrc' "$TEST_ROOT/error.txt" || fail "expected top-level symlink warning"
  grep -q 'WARN: skipping symlink source .config/linked.conf' "$TEST_ROOT/error.txt" || fail "expected nested symlink warning"
}

test_destination_symlink_file_is_skipped_without_modifying_target() {
  setup_repo
  trap cleanup_repo RETURN
  mkdir -p "$TEST_ROOT/outside"
  printf 'repo\n' > "$TEST_ROOT/repo/.bashrc"
  printf 'outside target\n' > "$TEST_ROOT/outside/target"
  ln -s "$TEST_ROOT/outside/target" "$TEST_ROOT/home/.bashrc"

  run_deploy_with_input 'y\n' > "$TEST_ROOT/output.txt" 2> "$TEST_ROOT/error.txt"

  [[ -L "$TEST_ROOT/home/.bashrc" ]] || fail "expected destination symlink to remain in place"
  assert_file_content "$TEST_ROOT/outside/target" "outside target"
  assert_file_missing "$TEST_ROOT/home/.dotfiles-deploy-backup"
  grep -q 'WARN: skipping symlink destination .bashrc' "$TEST_ROOT/error.txt" || fail "expected destination symlink warning"
}

test_destination_symlink_inside_directory_is_skipped_without_modifying_target() {
  setup_repo
  trap cleanup_repo RETURN
  mkdir -p "$TEST_ROOT/repo/.config/i3" "$TEST_ROOT/home/.config/i3" "$TEST_ROOT/outside"
  printf 'repo config\n' > "$TEST_ROOT/repo/.config/i3/config"
  printf 'outside config\n' > "$TEST_ROOT/outside/config-target"
  ln -s "$TEST_ROOT/outside/config-target" "$TEST_ROOT/home/.config/i3/config"

  run_deploy_with_input 'y\n' > "$TEST_ROOT/output.txt" 2> "$TEST_ROOT/error.txt"

  [[ -L "$TEST_ROOT/home/.config/i3/config" ]] || fail "expected nested destination symlink to remain in place"
  assert_file_content "$TEST_ROOT/outside/config-target" "outside config"
  assert_file_missing "$TEST_ROOT/home/.dotfiles-deploy-backup"
  grep -q 'WARN: skipping symlink destination .config/i3/config' "$TEST_ROOT/error.txt" || fail "expected nested destination symlink warning"
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
run_test test_conflict_no_skips_without_backup
run_test test_conflict_yes_replaces_and_backs_up
run_test test_conflict_diff_then_no_shows_diff_and_skips
run_test test_directory_conflict_yes_replaces_and_backs_up
run_test test_conflict_quit_aborts_before_later_files
run_test test_directory_deploys_recursively_and_preserves_destination_only_files
run_test test_missing_allowlist_paths_warn_but_do_not_fail
run_test test_symlink_sources_are_skipped
run_test test_destination_symlink_file_is_skipped_without_modifying_target
run_test test_destination_symlink_inside_directory_is_skipped_without_modifying_target

echo "All deploy-dotfiles tests passed"
