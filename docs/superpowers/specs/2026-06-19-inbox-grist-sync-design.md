# Inbox Rules Grist Sync Design

## Goal

Make inbox filter rules maintainable after the initial analysis phase by moving the live source of truth into Grist while keeping a local seed and backup file for restore and inspection.

The design must support:

- local rule analysis that produces a draft rules file
- importing that draft into Grist
- direct human edits in Grist without touching the n8n workflow
- n8n reading the current rules from Grist on every run
- restoring rules from a local backup if Grist content is damaged or needs rollback

## Non-Goals

- Replacing Grist with Supabase or a custom app UI
- Making the local rules file canonical after Grist is live
- Requiring manual workflow edits in n8n for ordinary rule changes
- Re-running mailbox analysis just to recover from a bad edit

## Current Shape

The current inbox-rules flow already produces local JSON exports and keeps a TOML profile file under `~/.config/personal/`.
That is a good fit for analysis and backup, but not for live maintenance once rule edits need to happen over time.

The useful constraint from the earlier workflow work is that the exported rules remain a single structured object with:

- `active_rules`
- `flagged_rules`
- `inbox_summary`

That shape should stay stable so it can be consumed by n8n and also mirrored into Grist.

## Proposed Architecture

### 1. Local analysis output

The analysis command continues to run locally and writes a draft rules file.
That file is a seed, not the source of truth.
It should be easy to archive and restore.

### 2. Grist as the canonical rules store

Grist stores the live rules data.
Every user edit lands there first.
That keeps the system usable by non-technical users and lets you manage permissions per person or per rule set.

### 3. n8n runtime fetch

The inbox workflow fetches the current rules from Grist at the start of every run.
The workflow does not contain a pasted static rules blob.
That means edits in Grist take effect automatically on the next execution.

### 4. Local backup and restore

A local export command can pull the current Grist rules back down into a JSON backup.
If something goes wrong, the local backup can be re-imported into Grist without re-analyzing mailboxes.

## Data Model

Use stable IDs so records can be updated rather than recreated.

### Rule fields

Each rule row should include:

- `rule_id`
- `enabled`
- `priority`
- `kind`
- `value`
- `folder`
- `confidence`
- `coverage`
- `flagged`
- `flag_reason`
- `notes`
- `last_hit_at`
- `hit_count`
- `false_positive_count`
- `source_profile`
- `source_hash`
- `updated_at`

### Folder fields

Each folder row should include:

- `folder_id`
- `name`
- `mailbox`
- `enabled`
- `notes`

### Snapshot metadata

Keep one metadata record or sheet with:

- `generated_at`
- `synced_at`
- `source_hash`
- `profile_name`
- `rules_version`
- `analysis_run_id`

## Sync Flow

### Local draft creation

The analysis script produces a draft JSON file from the mailbox scan.
That draft should preserve enough metadata to seed Grist cleanly.

### Import to Grist

A sync command reads the local draft JSON and upserts the Grist tables.
It should not infer new rules from mail at this stage.
It only translates and writes the already-generated rule set.

### Runtime fetch by n8n

At workflow start, n8n fetches the current Grist rules payload.
The workflow then resolves folder routing from that payload and moves mail accordingly.

### Backup and restore

A backup command exports the current Grist payload into the same local JSON shape used by analysis output.
That file can be used to restore Grist later.

## Error Handling

- If Grist is unreachable, n8n should fail fast rather than run with stale rules.
- If the local backup is older than the current Grist source hash, the restore command should warn before overwriting anything.
- If a rule references a folder not present in the folder table, the sync should reject the row or mark it flagged.
- If there is a mismatch between Grist and the local backup, prefer Grist unless the user explicitly chooses restore.
- If the runtime fetch returns malformed data, the workflow should stop before moving any messages.

## Operational Safety

- Keep the local draft file and local backup file versioned by timestamp.
- Include a source hash so identical inputs do not create noisy updates.
- Make sync idempotent so rerunning it with the same source does not multiply rows.
- Separate `generated` rows from `enabled` rows so experimental analysis output cannot silently go live.
- Preserve the ability to review and edit rules without opening n8n.

## Reporting

Grist should be used for simple reporting over time.
Useful fields for review and reporting:

- hit counts by rule
- last hit timestamps
- folder distribution
- false positive counts
- flag reasons
- coverage and confidence trends

That lets you answer questions like:

- which rules are still useful
- which folders are receiving the most traffic
- which rules are misfiring
- which rules should be collapsed or deleted

## Testing

The implementation should include checks for:

- draft JSON parse and validation
- Grist payload generation from a local JSON file
- round-trip import/export between local JSON and Grist-compatible rows
- source hash stability
- runtime fetch handling for empty, missing, or malformed Grist payloads
- restore path from local backup to Grist

## Recommendation

Use this as the steady-state model:

- local analysis generates a draft JSON file
- Grist stores and serves the live rules
- n8n reads Grist on every run
- local exports exist for backup and restore
- edits happen in Grist, not in n8n

That gives you a maintainable workflow without requiring a custom UI or manual workflow surgery.
