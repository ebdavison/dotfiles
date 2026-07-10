# Dotfiles

This repository is the working set of my personal shell, terminal, and utility config.

It is mostly a collection of:

- shell helpers and small scripts under `bin/`
- editor and terminal preferences
- app-specific config files and sync-conflict cleanup helpers
- a few focused Python utilities when shell is too awkward

The repo is intentionally practical rather than polished. Files are organized by tool or purpose, and the goal is to keep everyday commands and configs easy to find.

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
kimai view 1642
kimai start --project 7 --activity 3 --description "Standup"
kimai stop --id 1234
```

In list view, the duration column is shown as `hh:mm:ss`.

Use `--json` if you want raw JSON output instead of the compact terminal view.
