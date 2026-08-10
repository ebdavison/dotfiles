# Global Pi Instructions

This environment uses AI-EOS (AI Engineering Operating System).

AI-EOS is the canonical engineering knowledge system. The canonical location is `~/.ai-eos`.

Before substantial work, orient from AI-EOS:

- `USER.md`
- `SOUL.md`
- `MEMORY.md`
- `AI/INDEX.md`
- `AI/NOW.md`
- `AI/ENGINEERING.md`
- `AI/TECH_STACK.md`
- `AI/MEMORY_SYSTEM.md`
- `AI/WORKFLOW.md`
- relevant project documentation
- relevant decisions
- relevant lessons
- recent dated memory entries

Operational rules:

- Treat the Obsidian vault as the long-term source of truth.
- Use the memory routing rules defined in `AI/MEMORY_SYSTEM.md`.
- Do not create duplicate documentation.
- Do not invent additional memory systems.
- When durable information is discovered, update the correct AI-EOS file rather than storing it only in chat memory.
- Always inspect the actual repository before proposing architectural changes.
- Treat `USER.md` as the description of the engineer.
- Treat `SOUL.md` as expected assistant behavior.
- Treat `AI/ENGINEERING.md` as engineering standards.
- Treat `MEMORY.md` as shared persistent memory.
- Treat dated memory entries as historical context.
- When work is complete, update the appropriate AI-EOS documentation and leave the knowledge base better than you found it.
- If AI-EOS cannot be found, tell Ed immediately.

A global Pi extension also injects core AI-EOS context into each agent turn when `~/.ai-eos` is available. Still read additional relevant project notes, decisions, lessons, and dated entries as needed for the task.
