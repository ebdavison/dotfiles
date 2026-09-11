# Dotfiles

This repository is the working set of my personal shell, terminal, and utility config.

It is mostly a collection of:

- shell helpers and small scripts under `bin/`
- editor and terminal preferences
- app-specific config files and sync-conflict cleanup helpers
- a few focused Python utilities when shell is too awkward

The repo is intentionally practical rather than polished. Files are organized by tool or purpose, and the goal is to keep everyday commands and configs easy to find.

## Dotfiles deploy

Use [`bin/deploy-dotfiles`](bin/deploy-dotfiles) to copy the curated shell, Vim, `.config`, `bin/`, and oh-my-posh theme files from this repository into the logged-in user's home directory.

```bash
./bin/deploy-dotfiles
```

The script deploys only an explicit allowlist, not the whole repository. Current deploy targets include Bash startup files, `.bashrc.d/`, Vim config, `.config/`, `.poshthemes/`, and `bin/` into `~/bin/`.

Existing files are handled safely:

- identical files are skipped
- differing files prompt for `[d]iff`, `[y]es replace`, `[n]o skip`, or `[q]uit`
- replaced files are backed up under `~/.dotfiles-deploy-backup/YYYYMMDD-HHMMSS/`
- destination-only files under deployed directories are left untouched
- deployed files have permissions normalized so scripts stay executable and config/text files do not

## Pi files sync

Pi agent files are managed separately from the general dotfiles deploy because they include a curated subset of `~/.pi/agent` plus profile setup for `~/.pi-personal` and `~/.pi-work`.

Use [`bin/pull-pi-files`](bin/pull-pi-files) to copy the managed Pi files from the current user's home directory into this repository:

```bash
./bin/pull-pi-files
```

Set `PI_SOURCE_HOME` to pull from another home-like directory during migration or testing:

```bash
PI_SOURCE_HOME=/path/to/source-home ./bin/pull-pi-files
```

Use [`bin/deploy-pi-files`](bin/deploy-pi-files) to copy the managed Pi files from this repository back into the logged-in user's home directory and create/update the Pi profile symlinks:

```bash
cd ~/repos/dotfiles
./bin/deploy-pi-files
```

If running an installed copy such as `~/bin/deploy-pi-files`, run it from inside the dotfiles checkout or set `DOTFILES_REPO` explicitly:

```bash
cd ~/repos/dotfiles
~/bin/deploy-pi-files
# or
DOTFILES_REPO=~/repos/dotfiles ~/bin/deploy-pi-files
```

Managed files include global Pi instructions, settings, the AI-EOS context extension, Pi wrapper scripts, selected support/test files, and `~/.pi/agent/skills/`. Runtime state such as auth files, sessions, npm cache, and git cache is intentionally not pulled into the repo.

`deploy-pi-files` requires AI-EOS to exist at `~/.ai-eos/AGENT_ORIENTATION_PROMPT.md` by default. To deploy Pi files before AI-EOS is present, set:

```bash
PI_DEPLOY_ALLOW_MISSING_AI_EOS=1 ./bin/deploy-pi-files
```

Profile symlinks are created under `~/.pi-personal` and `~/.pi-work` for shared Pi agent config, extensions, npm/git state, skills, and AI-EOS context files. Existing conflicting profile paths are handled interactively with `[d]iff`, `[y]es replace`, `[n]o skip`, or `[q]uit`; replaced paths are backed up under `~/.dotfiles-deploy-backup/YYYYMMDD-HHMMSS/`.

After deploying, restart Pi or run `/reload` in existing sessions.

### Agent tool installation

On Linux, use [`bin/install-agent-tools`](bin/install-agent-tools) to check for and optionally install Pi, Herdr, Obsidian Headless, Codex, and Claude Code. Each missing tool displays its install command and requires an explicit confirmation; existing tools are left unchanged.

```bash
./bin/install-agent-tools
```

Pi extensions are reconciled from the selected profile settings after Pi is available. Use `--profile personal`, `--profile work`, or `--profile all` (default) to select profiles. The command does not authenticate Codex, Claude Code, or Obsidian Headless, and it does not configure or sync a vault. For Obsidian Headless, run `ob login` and `ob sync-setup` manually; do not run it alongside Obsidian Desktop Sync on the same device.

## Kimai CLI

This repo includes a small Kimai time-tracking CLI at [`bin/kimai`](bin/kimai).

It can:

- start a time entry
- stop a time entry
- list recent entries
- show a detailed entry view by ID

### Configuration

The script reads defaults from `~/.config/kimai/config.toml`.

Create the file with:

```toml
url = "https://kimai.example.com"
token = "your-kimai-api-token"
```

The supported keys are:

- `url`
- `token`

You can still override either value with command-line flags or environment variables:

- `--url` / `KIMAI_URL`
- `--token` / `KIMAI_TOKEN`

### Examples

```bash
kimai view
kimai view --limit 20
kimai view --sort end
kimai view --sort id --reverse
kimai view --from 2026-07-01 --to 2026-07-31
kimai view --project "IT Support" --activity Consult --company Fincon
kimai --debug view --from 2026-06-01
kimai view 1642
kimai start --project 7 --activity 3 --description "Standup"
kimai start --project 7 --activity 3 --description "Onsite support" --tag RETIRE01 --tags billable,onsite
kimai stop --id 1234
```

In list view, the duration column is shown as `hh:mm:ss`.
List view sorts newest-first by `begin` by default. Use `--sort begin|end|id` to choose the field and `--reverse` to flip the selected order.
Use `--from`, `--to`, `--project`, `--activity`, and `--company` to narrow the compact list before sorting. The project/activity/company filters accept either an ID or a name.
The CLI pages through Kimai's collection endpoint in 500-row batches before applying local filters, so date and project filters can see beyond the first batch of results.
Use `--debug` to print the page fetches and pre/post-filter counts to stderr.
Use `--tag NAME` for one tag, repeat it for multiple tags, or use `--tags name1,name2` for comma-separated tags when starting an entry.
In text views, tags are shown as `name [id]` when the ID can be resolved through Kimai's tag API, or `name [?]` when the tag name is present but the ID cannot be resolved. In detail view, `project` and `activity` are shown as `name [id]` when the ID is available.

Use `--json` if you want raw JSON output instead of the compact terminal view.
