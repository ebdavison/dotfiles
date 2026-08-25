#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"
SCRIPT_UNDER_TEST="$REPO_ROOT/bin/install-i3-deps"
I3_CONFIG_UNDER_TEST="$REPO_ROOT/.config/i3/config"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_exists() {
  local file="$1"
  [[ -f "$file" ]] || fail "expected file to exist: $file"
}

assert_executable() {
  local file="$1"
  [[ -x "$file" ]] || fail "expected file to be executable: $file"
}

assert_contains() {
  local file="$1"
  local needle="$2"
  grep -Fq -- "$needle" "$file" || fail "expected $file to contain: $needle"
}

assert_not_contains() {
  local file="$1"
  local needle="$2"
  if grep -Fq -- "$needle" "$file"; then
    fail "did not expect $file to contain: $needle"
  fi
}

test_installer_script_exists_and_covers_i3_dependencies() {
  assert_file_exists "$SCRIPT_UNDER_TEST"
  assert_executable "$SCRIPT_UNDER_TEST"

  bash -n "$SCRIPT_UNDER_TEST"

  assert_contains "$SCRIPT_UNDER_TEST" "rofi"
  assert_contains "$SCRIPT_UNDER_TEST" "picom"
  assert_contains "$SCRIPT_UNDER_TEST" "vorta"
  assert_contains "$SCRIPT_UNDER_TEST" "xsecurelock"
  assert_contains "$SCRIPT_UNDER_TEST" "flameshot"
  assert_contains "$SCRIPT_UNDER_TEST" "blueman"
  assert_contains "$SCRIPT_UNDER_TEST" "polkit-gnome"
  assert_contains "$SCRIPT_UNDER_TEST" "i3-instant-layout"
  assert_contains "$SCRIPT_UNDER_TEST" "rofi-rbw"
  assert_contains "$SCRIPT_UNDER_TEST" "rescuetime"
  assert_contains "$SCRIPT_UNDER_TEST" "companion-launcher"
  assert_contains "$SCRIPT_UNDER_TEST" "lock_and_blur.sh"
}

test_installer_has_dry_run_and_uses_fedora_package_manager() {
  assert_contains "$SCRIPT_UNDER_TEST" "--dry-run"
  assert_contains "$SCRIPT_UNDER_TEST" "dnf"
  assert_contains "$SCRIPT_UNDER_TEST" "sudo"
}

test_i3_instant_layout_typo_is_fixed() {
  assert_not_contains "$I3_CONFIG_UNDER_TEST" "i3-isntant-layout"
  assert_contains "$I3_CONFIG_UNDER_TEST" "i3-instant-layout -"
}

run_test() {
  local name="$1"
  echo "Running $name"
  "$name"
}

run_test test_installer_script_exists_and_covers_i3_dependencies
run_test test_installer_has_dry_run_and_uses_fedora_package_manager
run_test test_i3_instant_layout_typo_is_fixed

echo "All i3 dependency installer tests passed"
