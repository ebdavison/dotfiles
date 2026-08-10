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
kimai stop --id 1234
```

In list view, the duration column is shown as `hh:mm:ss`.
List view sorts newest-first by `begin` by default. Use `--sort begin|end|id` to choose the field and `--reverse` to flip the selected order.
Use `--from`, `--to`, `--project`, `--activity`, and `--company` to narrow the compact list before sorting. The project/activity/company filters accept either an ID or a name.
The CLI pages through Kimai's collection endpoint in 500-row batches before applying local filters, so date and project filters can see beyond the first batch of results.
Use `--debug` to print the page fetches and pre/post-filter counts to stderr.
In detail view, `project` and `activity` are shown as `name [id]` when the ID is available.

Use `--json` if you want raw JSON output instead of the compact terminal view.
