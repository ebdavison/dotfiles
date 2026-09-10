#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(pwd)}"
SCRIPT_UNDER_TEST="$REPO_ROOT/bin/install-i3-deps"
I3_CONFIG_UNDER_TEST="$REPO_ROOT/.config/i3/config"
I3_SESSION_TARGET_UNDER_TEST="$REPO_ROOT/.config/systemd/user/i3-session.target"

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

test_rofi_rbw_is_installed_with_pipx_not_cargo() {
  assert_contains "$SCRIPT_UNDER_TEST" "pipx"
  assert_contains "$SCRIPT_UNDER_TEST" "PIPX_APPS=("
  assert_contains "$SCRIPT_UNDER_TEST" "rofi-rbw"

  if awk '/CARGO_CRATES=\(/,/\)/ { print }' "$SCRIPT_UNDER_TEST" | grep -Fq "rofi-rbw"; then
    fail "rofi-rbw is a Python/pipx app and must not be listed as a cargo crate"
  fi
}

test_rofi_rbw_installs_newer_rbw_and_i3_prefers_user_cargo_bin() {
  if ! awk '/CARGO_CRATES=\(/,/\)/ { print }' "$SCRIPT_UNDER_TEST" | grep -Fq "rbw"; then
    fail "rofi-rbw 1.7 requires rbw with --raw support; install newer rbw as a cargo crate"
  fi

  assert_contains "$I3_CONFIG_UNDER_TEST" 'PATH=$HOME/.cargo/bin:$HOME/.local/bin:$PATH rofi-rbw'
}

test_i3_instant_layout_typo_is_fixed() {
  assert_not_contains "$I3_CONFIG_UNDER_TEST" "i3-isntant-layout"
  assert_contains "$I3_CONFIG_UNDER_TEST" "i3-instant-layout -"
}

test_i3_starts_a_graphical_session_target_and_leaves_portal_activation_to_dbus() {
  assert_file_exists "$I3_SESSION_TARGET_UNDER_TEST"
  assert_contains "$I3_SESSION_TARGET_UNDER_TEST" "BindsTo=graphical-session.target"
  assert_contains "$I3_SESSION_TARGET_UNDER_TEST" "Before=graphical-session.target"
  assert_contains "$I3_CONFIG_UNDER_TEST" "dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
  assert_contains "$I3_CONFIG_UNDER_TEST" "systemctl --user start i3-session.target"
  assert_not_contains "$I3_CONFIG_UNDER_TEST" "systemctl --user start id-session.target"
  assert_not_contains "$I3_CONFIG_UNDER_TEST" "systemctl --user start xdg-desktop-portal"
}

run_test() {
  local name="$1"
  echo "Running $name"
  "$name"
}

run_test test_installer_script_exists_and_covers_i3_dependencies
run_test test_installer_has_dry_run_and_uses_fedora_package_manager
run_test test_rofi_rbw_is_installed_with_pipx_not_cargo
run_test test_rofi_rbw_installs_newer_rbw_and_i3_prefers_user_cargo_bin
run_test test_i3_instant_layout_typo_is_fixed
run_test test_i3_starts_a_graphical_session_target_and_leaves_portal_activation_to_dbus

echo "All i3 dependency installer tests passed"
