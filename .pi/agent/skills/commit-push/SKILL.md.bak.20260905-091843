# commit-push

Create a clear commit from the current git changes and push it.

## When to use

Use this skill when the user asks to commit and push changes, or explicitly invokes `commit-push`.

## What to do

1. Inspect the active branch:

```bash
git branch --show-current
```

2. Extract the issue number from the branch name.
   - Example: `HUN1245/eddaviso` → issue number `1245`.
   - Look for the first number sequence in the branch name.
   - The commit message must include the issue as `#1234` using that number.
   - If no issue number can be found, stop and ask the user for the issue number. Do not commit without it.

3. Review the changes before committing:

```bash
git status --short
git diff --stat
git diff
```

Also check staged changes if present:

```bash
git diff --cached --stat
git diff --cached
```

4. Create a clear, concise, meaningful commit message based on the reviewed diff.
   - Use imperative mood where natural.
   - Include the issue number in the message as `#1234`.
   - Prefer a single-line message unless the change genuinely needs detail.
   - Example: `#1245 Prevent duplicate stat form submissions`

5. Check the git remote and SSH config before pushing:

```bash
git remote -v
```

If the push remote uses SSH, identify its host. Examples:
- `git@github.com:owner/repo.git` → `github.com`
- `ssh://git@example.com/owner/repo.git` → `example.com`

Then check whether `$HOME/.ssh/config` has a matching `Host` entry for that host:

```bash
ssh -G HOSTNAME >/dev/null
```

Guidelines:
- If there is a matching SSH config entry for the remote host and `ssh -G HOSTNAME` succeeds, use normal `git push`.
- If there is no matching SSH config entry for the remote host, prefer bypassing unrelated/broken SSH config by using:

```bash
GIT_SSH_COMMAND="ssh -F /dev/null" git push
```

- If the branch has no upstream, use the same rule with `--set-upstream`, for example:

```bash
git push --set-upstream origin CURRENT_BRANCH
# or, when bypassing unrelated SSH config:
GIT_SSH_COMMAND="ssh -F /dev/null" git push --set-upstream origin CURRENT_BRANCH
```

This prevents unrelated broken SSH config entries for other hosts from blocking a push to a remote such as GitHub.

6. Stage changes, commit, and push:

```bash
git add -A
git commit -m "#1234 Clear concise message"
git push
```

7. Report the result briefly:
   - Commit hash/message if successful.
   - Push destination/branch if shown.
   - If commit or push fails, show the error and suggest the next step.

## Rules

- Always run and review `git diff` before committing.
- Always include the issue number as `#1234` in the commit message.
- Always derive the issue number from the active branch name when possible.
- Never commit if the working tree is clean.
- Never invent an issue number; ask the user if it is not present in the branch name.
- Before pushing, inspect `git remote -v` and avoid letting unrelated broken SSH config entries affect remotes that do not need them; use `GIT_SSH_COMMAND="ssh -F /dev/null"` when there is no matching SSH config entry for the remote host.
