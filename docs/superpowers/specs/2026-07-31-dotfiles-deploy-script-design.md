# Dotfiles Deploy Script Design

## Context

This repository contains personal shell, Vim, terminal, and utility configuration. Most environments should receive only the practical dotfiles/configuration subset, not the whole repository.

## Goal

Add a deploy script that copies a curated set of Bash, Vim, `.config`, and oh-my-posh theme files/directories from the repository into the logged-in user's home directory.

## Non-goals

- Do not deploy every repository file.
- Do not overwrite existing home-directory files without an explicit prompt.
- Do not delete destination files that are not represented in the repo.
- Do not install packages or modify system-level configuration.

## Deployment Source Set

The script will use a static allowlist so deployments are predictable and auditable.

Initial allowlist:

- `.bashrc`
- `.bash_profile`
- `.bash_aliases`
- `.bash_logout`
- `.bash-preexec.sh`
- `.bashrc.d/`
- `.vimrc`
- `.vim/`
- `.viminfo`
- `.config/`
- `.poshthemes/`

The allowlist intentionally excludes sync-conflict files, repo metadata, tests, docs, README files, and unrelated scripts unless explicitly added later.

## Destination

All paths are copied relative to `$HOME`. For example:

- repo `.bashrc` -> `$HOME/.bashrc`
- repo `.config/i3/config` -> `$HOME/.config/i3/config`
- repo `.poshthemes/foo.omp.json` -> `$HOME/.poshthemes/foo.omp.json`

## Conflict Handling

For each source file:

1. If the destination does not exist, copy the file.
2. If the destination exists and is identical, skip it.
3. If the destination exists and differs, prompt interactively:
   - `d` / `diff`: show a unified diff
   - `y` / `yes`: replace destination
   - `n` / `no`: skip destination
   - `q` / `quit`: abort deployment

For directories, the script walks files recursively and applies the same per-file behavior. Existing destination files that do not exist in the source are left untouched.

## Backups

Before replacing any existing destination file, the script copies the current destination to:

```text
$HOME/.dotfiles-deploy-backup/YYYYMMDD-HHMMSS/<relative-path>
```

This preserves the previous version and keeps all replacements from one run grouped together.

## Safety

- The script must resolve its repository root from its own path so it can be run from any working directory.
- It must refuse to run if `$HOME` is empty or `/`.
- It must skip missing allowlist paths with a warning instead of failing the entire run.
- It must not follow symlinked source files/directories in a way that copies unexpected external content.
- It must use standard Linux tools available on typical systems: `bash`, `cp`, `diff`, `find`, `mkdir`, `cmp`.

## Testing

Add shell/unit-style tests around the deploy script using temporary source and destination directories where possible. Verify:

- new files are copied
- identical files are skipped
- conflicting files can be skipped
- conflicting files can be replaced
- replacement creates a backup
- diff prompt path works without replacing
- directory deployment is recursive but does not delete destination-only files
