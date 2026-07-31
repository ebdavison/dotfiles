# Dotfiles Deploy Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a safe curated dotfiles deploy script that copies selected Bash, Vim, `.config`, and oh-my-posh theme paths into the logged-in user's `$HOME` with interactive conflict handling and backups.

**Architecture:** Implement one Bash script at `bin/deploy-dotfiles` with small functions for path resolution, allowlist enumeration, file deployment, directory walking, prompting, diff display, and backups. Add one shell test file that creates temporary fake repository/home trees and drives the script through real command invocations.

**Tech Stack:** Bash, POSIX-ish coreutils available on typical Linux systems (`cp`, `cmp`, `diff`, `find`, `mkdir`, `mktemp`, `chmod`), shell tests run by `bash`.

## Global Constraints

- Use a static allowlist rather than deploying the whole repository.
- Initial allowlist: `.bashrc`, `.bash_profile`, `.bash_aliases`, `.bash_logout`, `.bash-preexec.sh`, `.bashrc.d/`, `.vimrc`, `.vim/`, `.viminfo`, `.config/`, `.poshthemes/`.
- Copy all paths relative to `$HOME`.
- Never overwrite existing files without an explicit interactive prompt.
- Before replacement, back up the existing target under `$HOME/.dotfiles-deploy-backup/YYYYMMDD-HHMMSS/<relative-path>`.
- Directory deployment must be recursive per file and must not delete destination-only files.
- Skip missing allowlist paths with a warning instead of failing the full run.
- Refuse to run when `$HOME` is empty or `/`.
- Do not follow symlinked source files/directories in a way that copies unexpected external content.
- Use standard Linux tools only: `bash`, `cp`, `diff`, `find`, `mkdir`, `cmp`.
- Preserve unrelated existing work in this repository; stage and commit only files touched by this plan.

---

## File Structure

- Create `bin/deploy-dotfiles`: the deploy script. Responsibilities: resolve repo root, validate home directory, enumerate the allowlist, deploy files/directories, prompt on conflicts, show diffs, back up replaced targets, and print a concise summary.
- Create `tests/test_deploy_dotfiles.sh`: end-to-end shell tests. Responsibilities: create temporary source/home trees, install a temporary copy of `bin/deploy-dotfiles`, invoke it with controlled `HOME` and stdin, and assert filesystem effects.
- Modify `README.md`: add a short usage section for the deploy script once behavior is implemented and tested.

---

### Task 1: Basic Deploy Script and New/Identical File Behavior

**Files:**
- Create: `bin/deploy-dotfiles`
- Create: `tests/test_deploy_dotfiles.sh`

**Interfaces:**
- Produces executable script: `bin/deploy-dotfiles`
- Produces test helper command: `bash tests/test_deploy_dotfiles.sh`
- Produces script functions used by later tasks:
  - `repo_root() -> prints absolute repo path`
  - `validate_home() -> exits non-zero if HOME is empty or /`
  - `copy_new_file(source, destination) -> copies a file after creating parent directories`
  - `deploy_file(relative_path, root) -> deploys one file path relative to repo root and HOME`
  - `deploy_directory(relative_path, root) -> walks regular files in a directory and calls deploy_file for each`

- [ ] **Step 1: Write the failing tests for new files, identical files, and HOME validation**

Create `tests/test_deploy_dotfiles.sh` with this initial content:

```bash
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
```

- [ ] **Step 2: Run the tests and verify they fail because the script does not exist**

Run:

```bash
bash tests/test_deploy_dotfiles.sh
```

Expected: FAIL or shell error mentioning `bin/deploy-dotfiles` does not exist.

- [ ] **Step 3: Implement minimal script for allowlist iteration, new-file copy, identical skip, and HOME validation**

Create `bin/deploy-dotfiles`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ALLOWLIST=(
  ".bashrc"
  ".bash_profile"
  ".bash_aliases"
  ".bash_logout"
  ".bash-preexec.sh"
  ".bashrc.d"
  ".vimrc"
  ".vim"
  ".viminfo"
  ".config"
  ".poshthemes"
)

copied_count=0
skipped_count=0
warning_count=0

repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  cd "$script_dir/.." && pwd -P
}

validate_home() {
  if [[ -z "${HOME:-}" || "$HOME" == "/" ]]; then
    echo "Refusing to run with unsafe HOME: ${HOME:-<empty>}" >&2
    exit 2
  fi
}

warn() {
  warning_count=$((warning_count + 1))
  echo "WARN: $*" >&2
}

copy_new_file() {
  local source="$1"
  local destination="$2"
  mkdir -p "$(dirname "$destination")"
  cp -p "$source" "$destination"
  copied_count=$((copied_count + 1))
  echo "copied $destination"
}

deploy_file() {
  local relative_path="$1"
  local root="$2"
  local source="$root/$relative_path"
  local destination="$HOME/$relative_path"

  if [[ -L "$source" ]]; then
    warn "skipping symlink source $relative_path"
    return 0
  fi

  if [[ ! -e "$destination" ]]; then
    copy_new_file "$source" "$destination"
    return 0
  fi

  if [[ -f "$destination" && cmp -s "$source" "$destination" ]]; then
    skipped_count=$((skipped_count + 1))
    echo "identical $destination"
    return 0
  fi

  echo "conflict $destination"
  skipped_count=$((skipped_count + 1))
}

deploy_directory() {
  local relative_path="$1"
  local root="$2"
  local source_dir="$root/$relative_path"
  local file

  while IFS= read -r -d '' file; do
    file="${file#"$root/"}"
    deploy_file "$file" "$root"
  done < <(find "$source_dir" -type f -print0)
}

deploy_path() {
  local relative_path="$1"
  local root="$2"
  local source="$root/$relative_path"

  if [[ ! -e "$source" ]]; then
    warn "allowlist path missing: $relative_path"
    return 0
  fi

  if [[ -L "$source" ]]; then
    warn "skipping symlink source $relative_path"
    return 0
  fi

  if [[ -d "$source" ]]; then
    deploy_directory "$relative_path" "$root"
  elif [[ -f "$source" ]]; then
    deploy_file "$relative_path" "$root"
  else
    warn "skipping unsupported source type: $relative_path"
  fi
}

main() {
  validate_home
  local root
  root="$(repo_root)"

  local path
  for path in "${ALLOWLIST[@]}"; do
    deploy_path "$path" "$root"
  done

  echo "Summary: copied=$copied_count skipped=$skipped_count warnings=$warning_count"
}

main "$@"
```

- [ ] **Step 4: Make the script executable**

Run:

```bash
chmod +x bin/deploy-dotfiles
```

- [ ] **Step 5: Run the tests and verify Task 1 passes**

Run:

```bash
bash tests/test_deploy_dotfiles.sh
bash -n bin/deploy-dotfiles
```

Expected: both commands exit 0.

- [ ] **Step 6: Commit Task 1**

Run:

```bash
git add bin/deploy-dotfiles tests/test_deploy_dotfiles.sh
git commit -m "feat: add basic dotfiles deploy script"
```

---

### Task 2: Interactive Conflict Prompt, Diff, Replace, Skip, Quit, and Backups

**Files:**
- Modify: `bin/deploy-dotfiles`
- Modify: `tests/test_deploy_dotfiles.sh`

**Interfaces:**
- Consumes from Task 1: `deploy_file(relative_path, root)`, `copy_new_file(source, destination)`, `validate_home()`.
- Produces functions used by the final behavior:
  - `backup_existing(destination, relative_path) -> copies existing destination into the run backup directory`
  - `replace_file(source, destination, relative_path) -> backs up then copies source over destination`
  - `show_diff(source, destination) -> prints unified diff and tolerates differences without exiting`
  - `prompt_conflict(source, destination, relative_path) -> loops until y/n/d/q decision`

- [ ] **Step 1: Add failing tests for skip, replace with backup, diff, and quit**

Append these test functions above `run_test` in `tests/test_deploy_dotfiles.sh`:

```bash
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
```

Add these invocations near the bottom with the existing `run_test` calls:

```bash
run_test test_conflict_no_skips_without_backup
run_test test_conflict_yes_replaces_and_backs_up
run_test test_conflict_diff_then_no_shows_diff_and_skips
run_test test_conflict_quit_aborts_before_later_files
```

- [ ] **Step 2: Run tests and verify the new conflict tests fail**

Run:

```bash
bash tests/test_deploy_dotfiles.sh
```

Expected: at least one new conflict test fails because Task 1 only logs conflict and skips.

- [ ] **Step 3: Add backup, diff, and prompt functions**

Modify `bin/deploy-dotfiles` after `copy_new_file()`:

```bash
backup_stamp="${DOTFILES_DEPLOY_BACKUP_STAMP:-$(date +%Y%m%d-%H%M%S)}"
backup_root=""
replaced_count=0

backup_existing() {
  local destination="$1"
  local relative_path="$2"
  backup_root="$HOME/.dotfiles-deploy-backup/$backup_stamp"
  local backup_path="$backup_root/$relative_path"
  mkdir -p "$(dirname "$backup_path")"
  cp -p "$destination" "$backup_path"
  echo "backed up $destination to $backup_path"
}

replace_file() {
  local source="$1"
  local destination="$2"
  local relative_path="$3"
  backup_existing "$destination" "$relative_path"
  cp -p "$source" "$destination"
  replaced_count=$((replaced_count + 1))
  echo "replaced $destination"
}

show_diff() {
  local source="$1"
  local destination="$2"
  diff -u --label "$destination" --label "$source" "$destination" "$source" || true
}

prompt_conflict() {
  local source="$1"
  local destination="$2"
  local relative_path="$3"
  local answer

  while true; do
    printf 'Conflict: %s differs. [d]iff, [y]es replace, [n]o skip, [q]uit: ' "$destination" >&2
    if ! IFS= read -r answer; then
      echo "No answer received; skipping $destination" >&2
      skipped_count=$((skipped_count + 1))
      return 0
    fi

    case "$answer" in
      d|D|diff|DIFF)
        show_diff "$source" "$destination"
        ;;
      y|Y|yes|YES)
        replace_file "$source" "$destination" "$relative_path"
        return 0
        ;;
      n|N|no|NO|"")
        skipped_count=$((skipped_count + 1))
        echo "skipped $destination"
        return 0
        ;;
      q|Q|quit|QUIT)
        echo "Aborted by user" >&2
        exit 130
        ;;
      *)
        echo "Please answer d, y, n, or q." >&2
        ;;
    esac
  done
}
```

- [ ] **Step 4: Wire conflict prompt into `deploy_file`**

Replace the final conflict block in `deploy_file()`:

```bash
  echo "conflict $destination"
  skipped_count=$((skipped_count + 1))
```

with:

```bash
  if [[ ! -f "$destination" ]]; then
    warn "destination exists but is not a regular file: $relative_path"
    skipped_count=$((skipped_count + 1))
    return 0
  fi

  prompt_conflict "$source" "$destination" "$relative_path"
```

Update the summary line in `main()` from:

```bash
  echo "Summary: copied=$copied_count skipped=$skipped_count warnings=$warning_count"
```

to:

```bash
  echo "Summary: copied=$copied_count replaced=$replaced_count skipped=$skipped_count warnings=$warning_count"
```

- [ ] **Step 5: Run tests and verify Task 2 passes**

Run:

```bash
bash tests/test_deploy_dotfiles.sh
bash -n bin/deploy-dotfiles
```

Expected: both commands exit 0.

- [ ] **Step 6: Commit Task 2**

Run:

```bash
git add bin/deploy-dotfiles tests/test_deploy_dotfiles.sh
git commit -m "feat: add interactive dotfiles conflict handling"
```

---

### Task 3: Recursive Directory Deployment, Missing Paths, Symlink Skips, and Destination Preservation

**Files:**
- Modify: `bin/deploy-dotfiles`
- Modify: `tests/test_deploy_dotfiles.sh`

**Interfaces:**
- Consumes from Task 2: `deploy_directory(relative_path, root)`, `deploy_file(relative_path, root)`, `prompt_conflict(source, destination, relative_path)`.
- Produces final directory behavior: recursive regular-file deployment, destination-only file preservation, symlink-source warnings, missing-allowlist warnings.

- [ ] **Step 1: Add failing tests for directories, destination-only preservation, missing path warnings, and symlink skips**

Append these test functions above `run_test` in `tests/test_deploy_dotfiles.sh`:

```bash
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

test_directory_conflict_uses_per_file_prompt() {
  setup_repo
  trap cleanup_repo RETURN
  mkdir -p "$TEST_ROOT/repo/.config/i3" "$TEST_ROOT/home/.config/i3"
  printf 'repo i3\n' > "$TEST_ROOT/repo/.config/i3/config"
  printf 'home i3\n' > "$TEST_ROOT/home/.config/i3/config"

  run_deploy_with_input 'y\n' > "$TEST_ROOT/output.txt"

  assert_file_content "$TEST_ROOT/home/.config/i3/config" "repo i3"
  local backup_file
  backup_file="$(find "$TEST_ROOT/home/.dotfiles-deploy-backup" -type f -path '*/.config/i3/config' -print -quit)"
  [[ -n "$backup_file" ]] || fail "expected .config/i3/config backup file"
  assert_file_content "$backup_file" "home i3"
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
```

Add these invocations near the bottom:

```bash
run_test test_directory_deploys_recursively_and_preserves_destination_only_files
run_test test_directory_conflict_uses_per_file_prompt
run_test test_missing_allowlist_paths_warn_but_do_not_fail
run_test test_symlink_sources_are_skipped
```

- [ ] **Step 2: Run tests and verify the nested symlink test fails**

Run:

```bash
bash tests/test_deploy_dotfiles.sh
```

Expected: nested symlink test fails because Task 1's `find "$source_dir" -type f` does not report symlink files, so it cannot warn about them.

- [ ] **Step 3: Update directory walking to inspect regular files and symlinks without following symlinked content**

Replace `deploy_directory()` in `bin/deploy-dotfiles` with:

```bash
deploy_directory() {
  local relative_path="$1"
  local root="$2"
  local source_dir="$root/$relative_path"
  local entry
  local rel_entry

  while IFS= read -r -d '' entry; do
    rel_entry="${entry#"$root/"}"

    if [[ -L "$entry" ]]; then
      warn "skipping symlink source $rel_entry"
      continue
    fi

    if [[ -f "$entry" ]]; then
      deploy_file "$rel_entry" "$root"
    fi
  done < <(find "$source_dir" \( -type f -o -type l \) -print0)
}
```

- [ ] **Step 4: Run tests and verify Task 3 passes**

Run:

```bash
bash tests/test_deploy_dotfiles.sh
bash -n bin/deploy-dotfiles
```

Expected: both commands exit 0.

- [ ] **Step 5: Commit Task 3**

Run:

```bash
git add bin/deploy-dotfiles tests/test_deploy_dotfiles.sh
git commit -m "test: cover recursive dotfiles deploy safety"
```

---

### Task 4: README Usage Documentation and Final Verification

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes final command from prior tasks: `bin/deploy-dotfiles`
- Produces user-facing documentation for safe deployment.

- [ ] **Step 1: Add README documentation for deploy usage**

Append this section to `README.md` after the introductory repository description and before `## Kimai CLI`:

````markdown
## Dotfiles deploy

Use [`bin/deploy-dotfiles`](bin/deploy-dotfiles) to copy the curated shell, Vim, `.config`, and oh-my-posh theme files from this repository into the logged-in user's home directory.

```bash
./bin/deploy-dotfiles
```

The script deploys only an explicit allowlist, not the whole repository. Current deploy targets include Bash startup files, `.bashrc.d/`, Vim config, `.config/`, and `.poshthemes/`.

Existing files are handled safely:

- identical files are skipped
- differing files prompt for `[d]iff`, `[y]es replace`, `[n]o skip`, or `[q]uit`
- replaced files are backed up under `~/.dotfiles-deploy-backup/YYYYMMDD-HHMMSS/`
- destination-only files under deployed directories are left untouched
````

- [ ] **Step 2: Run final verification**

Run:

```bash
bash tests/test_deploy_dotfiles.sh
bash -n bin/deploy-dotfiles
./bin/deploy-dotfiles </dev/null >/tmp/deploy-dotfiles-smoke.out 2>/tmp/deploy-dotfiles-smoke.err || true
grep -E 'Summary:|Conflict:|WARN:' /tmp/deploy-dotfiles-smoke.out /tmp/deploy-dotfiles-smoke.err >/dev/null
```

Expected:

- test script exits 0
- `bash -n` exits 0
- smoke command does not modify conflicting files because stdin is empty and conflict prompts default to skip
- grep finds either summary, conflict, or warning output from the smoke command

- [ ] **Step 3: Inspect git diff for unrelated changes**

Run:

```bash
git status --short
git diff -- bin/deploy-dotfiles tests/test_deploy_dotfiles.sh README.md
```

Expected: diff contains only the deploy script, deploy tests, and README changes from this plan. Existing unrelated modified files such as `.bashrc`, `bin/kimai`, and `tests/test_kimai.py` remain unstaged.

- [ ] **Step 4: Commit Task 4**

Run:

```bash
git add README.md
git commit -m "docs: document dotfiles deploy script"
```

- [ ] **Step 5: Report completion**

Final response must include:

```text
Implemented: bin/deploy-dotfiles
Tests: bash tests/test_deploy_dotfiles.sh; bash -n bin/deploy-dotfiles
Docs: README.md
Backups: ~/.dotfiles-deploy-backup/YYYYMMDD-HHMMSS/
Note: unrelated pre-existing working tree changes were left untouched
```
