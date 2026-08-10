// Global AI-EOS context injector/checkpointer for Pi.
// Loads the canonical Obsidian-backed engineering context into every agent turn
// and exposes checkpoint tooling so significant work is recorded durably.

// @ts-nocheck

import { Type } from "typebox";
import { existsSync, readFileSync, readdirSync, statSync, mkdirSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

const AI_EOS_ROOT = resolve(process.env.AI_EOS_HOME || join(homedir(), ".ai-eos"));
const MAX_FILE_BYTES = 90_000;
const MAX_MEMORY_FILE_BYTES = 70_000;
const CHECKPOINT_CUSTOM_TYPE = "ai-eos-checkpoint";
const CHECKPOINT_WARNING_CUSTOM_TYPE = "ai-eos-checkpoint-warning";

const CORE_FILES = [
  "USER.md",
  "SOUL.md",
  "MEMORY.md",
  "AI/INDEX.md",
  "AI/NOW.md",
  "AI/ENGINEERING.md",
  "AI/TECH_STACK.md",
  "AI/MEMORY_SYSTEM.md",
  "AI/WORKFLOW.md",
  "AI/DECISIONS.md",
  "AI/LESSONS_LEARNED.md",
];

const MUTATION_TOOLS = new Set(["edit", "write", "impeccable_live_reply", "impeccable_live_complete"]);
const SECRET_HINT = /(?:api[_-]?key|token|password|passwd|secret|private[_-]?key|credential|cookie|authorization)/i;

function todayInChicago(): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Chicago",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

function readUtf8Limited(path: string, maxBytes: number): string {
  const buffer = readFileSync(path);
  if (buffer.length <= maxBytes) {
    return buffer.toString("utf8");
  }

  const headBytes = Math.floor(maxBytes * 0.65);
  const tailBytes = maxBytes - headBytes;
  const head = buffer.subarray(0, headBytes).toString("utf8");
  const tail = buffer.subarray(buffer.length - tailBytes).toString("utf8");
  return `${head}\n\n[AI-EOS injector: file truncated after ${maxBytes} bytes; preserving tail below.]\n\n${tail}`;
}

function latestMemoryFiles(limit = 3): string[] {
  const memoryDir = join(AI_EOS_ROOT, "memory");
  if (!existsSync(memoryDir)) {
    return [];
  }

  return readdirSync(memoryDir)
    .filter((name) => /^Memory \d{4}-\d{2}-\d{2}\.md$/.test(name))
    .map((name) => join(memoryDir, name))
    .filter((path) => {
      try {
        return statSync(path).isFile();
      } catch {
        return false;
      }
    })
    .sort()
    .slice(-limit);
}

function buildAiEosContext(checkpointStatus?: string): string {
  if (!existsSync(AI_EOS_ROOT)) {
    return [
      "# AI-EOS Startup Error",
      `AI-EOS was not found at \`${AI_EOS_ROOT}\`.`,
      "Tell Ed immediately before doing substantial work.",
    ].join("\n");
  }

  const sections: string[] = [
    "# AI-EOS Loaded Context",
    "AI-EOS is the canonical engineering knowledge system. Treat the Obsidian vault as the long-term source of truth.",
    "Use `AI/MEMORY_SYSTEM.md` routing rules for documentation and memory updates. Do not invent another memory system or duplicate documentation.",
    "Before architectural recommendations, inspect the actual repository. For substantial work, also read task-relevant project notes, decisions, lessons, and dated memory entries beyond the injected context when needed.",
    "When a turn accomplishes or learns something significant, call `ai_eos_memory_checkpoint` before finalizing. Use it instead of ad hoc memory edits for normal dated-memory checkpoints.",
  ];

  if (checkpointStatus) {
    sections.push(`\n## AI-EOS checkpoint status\n\n${checkpointStatus}`);
  }

  for (const relativePath of CORE_FILES) {
    const path = join(AI_EOS_ROOT, relativePath);
    if (!existsSync(path)) {
      sections.push(`\n## Missing: ${relativePath}\nAI-EOS expected file is missing. Tell Ed if this matters for the task.`);
      continue;
    }
    sections.push(`\n## ${relativePath}\n\n${readUtf8Limited(path, MAX_FILE_BYTES)}`);
  }

  const memoryFiles = latestMemoryFiles(3);
  if (memoryFiles.length === 0) {
    sections.push("\n## Recent dated memory entries\n\nNo `memory/Memory YYYY-MM-DD.md` files found.");
  } else {
    sections.push("\n## Recent dated memory entries");
    for (const path of memoryFiles) {
      const label = path.slice(AI_EOS_ROOT.length + 1);
      sections.push(`\n### ${label}\n\n${readUtf8Limited(path, MAX_MEMORY_FILE_BYTES)}`);
    }
  }

  return sections.join("\n");
}

function oneLine(value: unknown, fallback = "none"): string {
  if (value === undefined || value === null || value === "") return fallback;
  return String(value).replace(/\r?\n/g, " ").trim() || fallback;
}

function bulletList(values: unknown, fallback = "none"): string {
  const items = Array.isArray(values) ? values : values ? [values] : [];
  const cleaned = items.map((item) => String(item).replace(/\r?\n/g, " ").trim()).filter(Boolean);
  if (cleaned.length === 0) return `- ${fallback}`;
  return cleaned.map((item) => `- ${item}`).join("\n");
}

function rejectLikelySecret(params: Record<string, unknown>): string | undefined {
  const payload = JSON.stringify(params);
  if (SECRET_HINT.test(payload)) {
    return "Checkpoint appears to contain secret-like text. Remove credentials/tokens/passwords before writing AI-EOS memory.";
  }
  return undefined;
}

function memoryFileForToday(): string {
  return join(AI_EOS_ROOT, "memory", `Memory ${todayInChicago()}.md`);
}

function appendDatedMemoryEntry(params: Record<string, unknown>): { path: string; markdown: string } {
  const secretReason = rejectLikelySecret(params);
  if (secretReason) throw new Error(secretReason);

  const tag = params.tag === "Work" ? "Work" : "Personal";
  const heading = oneLine(params.heading || params.task || "AI-EOS checkpoint", "AI-EOS checkpoint");
  const clientLine = tag === "Work" ? `\n- Client: ${oneLine(params.client, "Unknown")}` : "";
  const markdown = [
    "",
    `## ${heading}`,
    "",
    `- Tag: ${tag}${clientLine}`,
    `- Repo: ${oneLine(params.repo, "n/a")}`,
    `- Branch: ${oneLine(params.branch, "n/a")}`,
    `- Task: ${oneLine(params.task || heading)}`,
    `- Decisions/context: ${oneLine(params.decisionsContext || params.summary)}`,
    "- Files changed:",
    bulletList(params.filesChanged),
    "- Checks run:",
    bulletList(params.checksRun),
    `- Commit/PR info: ${oneLine(params.commitPrInfo)}`,
    `- Open follow-ups: ${oneLine(params.openFollowups)}`,
  ].join("\n");

  const path = memoryFileForToday();
  mkdirSync(dirname(path), { recursive: true });
  appendFileSync(path, `${markdown}\n`, "utf8");
  return { path, markdown };
}

function isAiEosMemoryPath(pathValue: unknown): boolean {
  if (typeof pathValue !== "string") return false;
  const path = resolve(pathValue.startsWith("@") ? pathValue.slice(1) : pathValue);
  const memoryRoot = resolve(AI_EOS_ROOT, "memory");
  return path.startsWith(memoryRoot) || path === resolve(AI_EOS_ROOT, "MEMORY.md");
}

function bashLooksMutating(command: unknown): boolean {
  if (typeof command !== "string") return false;
  return /(^|[;&|]\s*)(git\s+(commit|merge|rebase|cherry-pick|tag)|make\s+(install|deploy)|npm\s+publish|python\S*\s+.*(--write|--fix)|rm\s|mv\s|cp\s|mkdir\s|touch\s|chmod\s|chown\s)|(^|\s)(>|>>|tee\s)/.test(command);
}

function toolIndicatesMutation(event: any): boolean {
  if (MUTATION_TOOLS.has(event.toolName)) return true;
  if (event.toolName === "bash") return bashLooksMutating(event.input?.command);
  return false;
}

export default function (pi) {
  let currentRun = {
    started: false,
    prompt: "",
    mutated: false,
    checkpointed: false,
    tools: new Set<string>(),
  };
  let missedCheckpointCount = 0;

  const checkpointStatus = () => {
    if (!currentRun.started) return "No active checkpoint obligation for this agent run.";
    if (currentRun.checkpointed) return "This agent run has already recorded an AI-EOS checkpoint.";
    if (currentRun.mutated) return "This agent run used mutation-capable tools. If the result is significant, call `ai_eos_memory_checkpoint` before finalizing.";
    return "No mutation-capable tool has completed in this agent run yet. Still checkpoint if a significant fact was learned.";
  };

  pi.registerTool({
    name: "ai_eos_memory_checkpoint",
    label: "AI-EOS Memory Checkpoint",
    description: "Append a structured checkpoint to today's AI-EOS dated memory note after significant work or learning.",
    promptSnippet: "Record significant accomplishments or learnings in AI-EOS dated memory",
    promptGuidelines: [
      "Use ai_eos_memory_checkpoint before finalizing any significant task, durable learning, operational fix, architecture decision, or meaningful project change.",
      "Do not put secrets, tokens, passwords, private keys, cookies, or credentials in ai_eos_memory_checkpoint input.",
    ],
    parameters: Type.Object({
      heading: Type.String({ description: "Short heading for the dated memory entry" }),
      tag: Type.String({ description: "Personal or Work" }),
      client: Type.Optional(Type.String({ description: "Required for Work entries when known, e.g. Cisco, RETIRE01" })),
      repo: Type.Optional(Type.String({ description: "Repository or n/a" })),
      branch: Type.Optional(Type.String({ description: "Git branch or n/a" })),
      task: Type.String({ description: "What was done or verified" }),
      decisionsContext: Type.String({ description: "Important context, decisions, root cause, or rationale" }),
      filesChanged: Type.Optional(Type.Array(Type.String())),
      checksRun: Type.Optional(Type.Array(Type.String())),
      commitPrInfo: Type.Optional(Type.String()),
      openFollowups: Type.Optional(Type.String()),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const result = appendDatedMemoryEntry(params);
      currentRun.checkpointed = true;
      currentRun.tools.add("ai_eos_memory_checkpoint");
      pi.appendEntry(CHECKPOINT_CUSTOM_TYPE, {
        path: result.path,
        heading: params.heading,
        tag: params.tag,
        timestamp: Date.now(),
      });
      return {
        content: [{ type: "text", text: `AI-EOS memory checkpoint appended to ${result.path}` }],
        details: { path: result.path, heading: params.heading, tag: params.tag },
      };
    },
  });

  pi.registerCommand("ai-eos-checkpoint-status", {
    description: "Show AI-EOS checkpoint state for the current agent run",
    handler: async (_args, ctx) => {
      const text = checkpointStatus();
      if (ctx.hasUI) ctx.ui.notify(text, currentRun.mutated && !currentRun.checkpointed ? "warning" : "info");
      else console.log(text);
    },
  });

  pi.on("before_agent_start", async (event) => {
    currentRun = {
      started: true,
      prompt: event.prompt || "",
      mutated: false,
      checkpointed: false,
      tools: new Set<string>(),
    };
    return {
      systemPrompt: `${event.systemPrompt}\n\n${buildAiEosContext(checkpointStatus())}`,
    };
  });

  pi.on("tool_result", async (event) => {
    if (event.isError) return;
    currentRun.tools.add(event.toolName);
    if (event.toolName === "ai_eos_memory_checkpoint") {
      currentRun.checkpointed = true;
      return;
    }
    if ((event.toolName === "edit" || event.toolName === "write") && isAiEosMemoryPath(event.input?.path)) {
      currentRun.checkpointed = true;
      return;
    }
    if (toolIndicatesMutation(event)) {
      currentRun.mutated = true;
    }
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (!currentRun.started || !currentRun.mutated || currentRun.checkpointed) return;
    missedCheckpointCount += 1;
    const message = "AI-EOS checkpoint missing: mutation-capable work completed without `ai_eos_memory_checkpoint`. If this work was significant, record it before moving on.";
    pi.appendEntry(CHECKPOINT_WARNING_CUSTOM_TYPE, {
      message,
      prompt: currentRun.prompt,
      tools: [...currentRun.tools].sort(),
      missedCheckpointCount,
      timestamp: Date.now(),
    });
    if (ctx.hasUI) ctx.ui.notify(message, "warning");
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    if (!currentRun.started || !currentRun.mutated || currentRun.checkpointed) return;
    const message = "AI-EOS session ended with mutation-capable work and no recorded checkpoint.";
    pi.appendEntry(CHECKPOINT_WARNING_CUSTOM_TYPE, {
      message,
      prompt: currentRun.prompt,
      tools: [...currentRun.tools].sort(),
      timestamp: Date.now(),
    });
    if (ctx.hasUI) ctx.ui.notify(message, "warning");
  });
}
