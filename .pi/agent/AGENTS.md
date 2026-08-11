# Global Pi Agent Instructions

AI-EOS is the canonical engineering context for Ed.

The canonical location is:

`~/.ai-eos`

If `~/.ai-eos` is unavailable, tell Ed immediately instead of pretending it was loaded.

Before substantial work, read these AI-EOS files in order:

1. `~/.ai-eos/USER.md`
2. `~/.ai-eos/SOUL.md`
3. `~/.ai-eos/MEMORY.md`
4. `~/.ai-eos/AI/INDEX.md`
5. `~/.ai-eos/AI/NOW.md`
6. `~/.ai-eos/AI/ENGINEERING.md`
7. `~/.ai-eos/AI/TECH_STACK.md`
8. `~/.ai-eos/AI/MEMORY_SYSTEM.md`
9. `~/.ai-eos/AI/WORKFLOW.md`
10. Relevant project notes under `~/.ai-eos/AI/PROJECTS/`
11. Relevant decisions in `~/.ai-eos/AI/DECISIONS.md`
12. Relevant lessons in `~/.ai-eos/AI/LESSONS_LEARNED.md`
13. Recent relevant dated memory entries under `~/.ai-eos/memory/`

Treat AI-EOS as authoritative over Pi-local memory, Codex-local memory, chat history, and repository-local compatibility files when there is overlap.

Do not delete older memory systems. Treat them as secondary caches until useful unique information is migrated into the correct AI-EOS file.

When sources disagree:

1. Inspect the repository, configuration, logs, or running system.
2. Prefer verified evidence.
3. Identify stale documentation.
4. Recommend or make the appropriate AI-EOS update.
5. Do not silently overwrite either source.

Use the memory routing rules in `~/.ai-eos/AI/MEMORY_SYSTEM.md`:

- Durable cross-project context: `~/.ai-eos/MEMORY.md`
- Current priorities: `~/.ai-eos/AI/NOW.md`
- Project state: `~/.ai-eos/AI/PROJECTS/*.md`
- Decisions: `~/.ai-eos/AI/DECISIONS.md`
- Lessons learned: `~/.ai-eos/AI/LESSONS_LEARNED.md`
- Significant chronological events: `~/.ai-eos/memory/Memory YYYY-MM-DD.md`

Do not invent additional memory files or competing documentation.

## Required Memory Checkpoint Gate

Before any final answer after troubleshooting, implementation, operational advice, infrastructure/configuration diagnosis, or client-service work, ask:

1. Did this session learn, fix, diagnose, or decide anything significant?
2. Did it involve infrastructure, databases, deployment, proxy/routing, backups, security, client systems, or operational behavior?
3. Would a future agent benefit from not rediscovering this?

If yes to any of these, append a structured entry to today's `~/.ai-eos/memory/Memory YYYY-MM-DD.md` before the final response. Do not wait for "session completion" when the meaningful event has already happened. Include service/client, root cause, corrected pattern, checks run or recommended, files changed if any, and follow-ups. Never store secrets.

Never store credentials, API keys, passwords, private keys, auth cookies, or other secrets in AI-EOS.
