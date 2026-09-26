import { randomUUID } from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

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

const MAX_FILE_CHARS = 30_000;
const RECENT_MEMORY_LIMIT = 3;
const MEMORY_STATUS_KEY = "ai-eos";
const GENERATED_PROJECTION_MARKER = "<!-- AI-EOS generated daily projection; write new entries through ai_eos_memory_checkpoint. -->";
const MEMORY_EVENT_DIR = "events";
const PROJECTION_LOCK_TIMEOUT_MS = 10_000;
const PROJECTION_LOCK_STALE_MS = 60_000;

type FileState = {
  exists: boolean;
  size: number;
  mtimeMs: number;
};

type AgentRunMemoryState = {
  dailyPath: string;
  before: FileState;
  needsCheckpoint: boolean;
  usedCheckpointTool: boolean;
  prompt: string;
};

export type MemoryCheckpointInput = {
  title: string;
  tag: string;
  client?: string;
  repo?: string;
  branch?: string;
  task: string;
  context: string;
  filesChanged?: string[];
  checksRun?: string[];
  commitInfo?: string;
  followUps?: string[];
};

const runStateBySession = new Map<string, AgentRunMemoryState>();

function expandHome(input: string): string {
  if (input === "~") {
    return os.homedir();
  }
  if (input.startsWith("~/")) {
    return path.join(os.homedir(), input.slice(2));
  }
  return input;
}

export function aiEosHome(): string {
  return expandHome(process.env.AI_EOS_HOME || path.join(os.homedir(), ".ai-eos"));
}

function readText(filePath: string): string {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch {
    return "";
  }
}

function excerpt(text: string, maxChars = MAX_FILE_CHARS): string {
  const trimmed = text.trim();
  if (trimmed.length <= maxChars) {
    return trimmed;
  }
  return `${trimmed.slice(0, maxChars).trimEnd()}\n\n[Truncated in Pi startup context. Read the source file directly when full detail matters.]`;
}

function section(root: string, relativePath: string): { text: string; missing: boolean } {
  const filePath = path.join(root, relativePath);
  const text = readText(filePath);
  if (!text) {
    return {
      missing: true,
      text: `### ${relativePath}\n[Missing or unreadable at ${filePath}]`,
    };
  }

  return {
    missing: false,
    text: `### ${relativePath}\n${excerpt(text)}`,
  };
}

function recentMemoryFiles(root: string): string[] {
  const memoryDir = path.join(root, "memory");
  try {
    return fs
      .readdirSync(memoryDir)
      .filter((name) => /^Memory \d{4}-\d{2}-\d{2}\.md$/.test(name))
      .sort()
      .slice(-RECENT_MEMORY_LIMIT)
      .map((name) => path.join("memory", name));
  } catch {
    return [];
  }
}

function preferredTimezone(root: string): string {
  const userText = readText(path.join(root, "USER.md"));
  const match = /^\s*-?\s*\*\*Timezone:\*\*\s*([^\n]+)/m.exec(userText) || /^\s*Timezone:\s*([^\n]+)/m.exec(userText);
  return match?.[1]?.trim() || process.env.TZ || "America/Chicago";
}

function todayString(root: string, now = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: preferredTimezone(root),
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
}

export function dailyMemoryPath(root: string, now = new Date()): string {
  return path.join(root, "memory", `Memory ${todayString(root, now)}.md`);
}

function fileState(filePath: string): FileState {
  try {
    const stat = fs.statSync(filePath);
    return { exists: true, size: stat.size, mtimeMs: stat.mtimeMs };
  } catch {
    return { exists: false, size: 0, mtimeMs: 0 };
  }
}

function fileChanged(before: FileState, after: FileState): boolean {
  return before.exists !== after.exists || before.size !== after.size || before.mtimeMs !== after.mtimeMs;
}

function sessionKey(ctx: { sessionManager?: { getSessionFile?: () => string | undefined }; cwd?: string }): string {
  try {
    return String(ctx.sessionManager?.getSessionFile?.() || ctx.cwd || "session");
  } catch {
    return String(ctx.cwd || "session");
  }
}

export function isLikelyMemoryWorthy(text: string): boolean {
  const lower = text.toLowerCase();
  return /\b(implement|implemented|build|built|fix|fixed|diagnose|diagnosed|debug|troubleshoot|resolved|corrected|configured|deployed|migrated|backup|restore|postgres|postgresql|pg_dump|pg_restore|database|rls|bypassrls|nginx|proxy|server|service|cron|systemd|security|client|retire01|rpg|fincon|lesson|learned|root cause)\b/.test(
    lower,
  );
}

function isMemoryWorthyTool(toolName: string): boolean {
  return ["edit", "write", "bash", "obsidian_write", "obsidian_append"].includes(toolName);
}

function toolInputText(input: unknown): string {
  try {
    return JSON.stringify(input ?? {});
  } catch {
    return "";
  }
}

function referencesAiEosMemory(inputText: string, root: string): boolean {
  return inputText.includes(path.join(root, "memory")) || inputText.includes(".ai-eos/memory") || inputText.includes("Memory ");
}

export function buildMemoryCheckpointInstructions(root: string, now = new Date()): string {
  const dailyPath = dailyMemoryPath(root, now);
  return [
    "## Required AI-EOS memory checkpoint gate",
    "Before the final answer on any turn involving troubleshooting, implementation, operational advice, infrastructure/configuration diagnosis, databases, backups, security, or client-service work, decide whether a durable memory checkpoint is required.",
    "If the session learned, fixed, diagnosed, implemented, or decided anything significant, call ai_eos_memory_checkpoint before the final answer.",
    `Current daily projection: ${dailyPath}`,
    "The checkpoint tool is the only supported write path. Never use write, edit, or shell redirection to modify a dated memory note or anything under memory/events/.",
    "Each checkpoint is stored as an immutable event and the daily Markdown file is rebuilt as a projection. Do not manually edit the projection.",
    "Include service/client, repo/branch when relevant, root cause or decision, corrected pattern, checks run or recommended, files changed if any, and follow-ups.",
    "Never store credentials, API keys, passwords, private keys, auth cookies, or other secrets in AI-EOS.",
  ].join("\n");
}

export function renderMemoryCheckpoint(input: MemoryCheckpointInput): string {
  const lines = [
    `## ${input.title.trim()}`,
    "",
    `- Tag: ${input.tag.trim() || "Personal"}`,
  ];

  if (input.client?.trim()) {
    lines.push(`- Client: ${input.client.trim()}`);
  }
  if (input.repo?.trim()) {
    lines.push(`- Repo: ${input.repo.trim()}`);
  }
  if (input.branch?.trim()) {
    lines.push(`- Branch: ${input.branch.trim()}`);
  }

  lines.push(
    `- Task: ${input.task.trim()}`,
    `- Decisions/context: ${input.context.trim()}`,
    `- Files changed: ${input.filesChanged?.length ? input.filesChanged.join(", ") : "none"}`,
    `- Checks run: ${input.checksRun?.length ? input.checksRun.join("; ") : "none"}`,
    `- Commit/PR info: ${input.commitInfo?.trim() || "none"}`,
    `- Open follow-ups: ${input.followUps?.length ? input.followUps.join("; ") : "none"}`,
    "",
  );

  return lines.join("\n");
}

function realpathOrResolve(filePath: string): string {
  try {
    return fs.realpathSync(filePath);
  } catch {
    return path.resolve(filePath);
  }
}

function resolvedCandidatePath(candidate: string, cwd: string): string {
  const expanded = expandHome(candidate.trim());
  return path.isAbsolute(expanded) ? path.resolve(expanded) : path.resolve(cwd, expanded);
}

export function isProtectedDatedMemoryPath(candidate: unknown, root = aiEosHome(), cwd = process.cwd()): boolean {
  if (typeof candidate !== "string" || !candidate.trim()) {
    return false;
  }

  const absolute = resolvedCandidatePath(candidate, cwd);
  const memoryDir = realpathOrResolve(path.join(root, "memory"));
  const candidateParent = realpathOrResolve(path.dirname(absolute));
  return /^Memory \d{4}-\d{2}-\d{2}\.md$/.test(path.basename(absolute)) && candidateParent === memoryDir;
}

export function isProtectedMemoryPath(candidate: unknown, root = aiEosHome(), cwd = process.cwd()): boolean {
  if (typeof candidate !== "string" || !candidate.trim()) {
    return false;
  }

  if (isProtectedDatedMemoryPath(candidate, root, cwd)) {
    return true;
  }

  const absolute = resolvedCandidatePath(candidate, cwd);
  const eventRoot = realpathOrResolve(path.join(root, "memory", MEMORY_EVENT_DIR));
  const candidateParent = realpathOrResolve(path.dirname(absolute));
  return candidateParent === eventRoot || candidateParent.startsWith(`${eventRoot}${path.sep}`);
}

function eventDirectory(root: string, now: Date): string {
  return path.join(root, "memory", MEMORY_EVENT_DIR, todayString(root, now));
}

function eventFilename(now: Date): string {
  return `${now.toISOString().replace(/[:]/g, "").replace(/\.000Z$/, ".000Z")}-${randomUUID()}.md`;
}

function sleepSynchronously(milliseconds: number): void {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds);
}

function withProjectionLock<T>(root: string, operation: () => T): T {
  const lockPath = path.join(root, "memory", ".daily-projection.lock");
  fs.mkdirSync(path.dirname(lockPath), { recursive: true });
  const deadline = Date.now() + PROJECTION_LOCK_TIMEOUT_MS;
  let lockFd: number | undefined;

  while (lockFd === undefined) {
    try {
      lockFd = fs.openSync(lockPath, "wx", 0o600);
      fs.writeSync(lockFd, `${process.pid}\n`, undefined, "utf8");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "EEXIST") {
        throw error;
      }

      try {
        if (Date.now() - fs.statSync(lockPath).mtimeMs > PROJECTION_LOCK_STALE_MS) {
          fs.unlinkSync(lockPath);
          continue;
        }
      } catch {
        continue;
      }

      if (Date.now() >= deadline) {
        throw new Error(`Timed out waiting for AI-EOS daily projection lock: ${lockPath}`);
      }
      sleepSynchronously(10);
    }
  }

  try {
    return operation();
  } finally {
    fs.closeSync(lockFd);
    try {
      fs.unlinkSync(lockPath);
    } catch {
      // Another process may have removed a stale lock after an interruption.
    }
  }
}

function preserveLegacyDailyNote(root: string, dailyPath: string, directory: string): void {
  if (!fs.existsSync(dailyPath) || readText(dailyPath).includes(GENERATED_PROJECTION_MARKER)) {
    return;
  }

  const legacyPath = path.join(directory, "00000000T000000.000Z-legacy.md");
  try {
    const fd = fs.openSync(legacyPath, "wx", 0o600);
    try {
      fs.writeSync(fd, readText(dailyPath), undefined, "utf8");
    } finally {
      fs.closeSync(fd);
    }
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "EEXIST") {
      throw error;
    }
  }
}

function projectionFromEvents(directory: string): string {
  const eventFiles = fs.readdirSync(directory)
    .filter((name) => name.endsWith(".md"))
    .sort();
  const sections = eventFiles.map((name) => readText(path.join(directory, name)).trim()).filter(Boolean);
  return `${GENERATED_PROJECTION_MARKER}\n\n${sections.join("\n\n")}\n`;
}

function preserveUnexpectedProjectionTail(dailyPath: string, directory: string): void {
  const current = readText(dailyPath);
  if (!current.startsWith(`${GENERATED_PROJECTION_MARKER}\n\n`)) {
    return;
  }

  const expected = projectionFromEvents(directory);
  if (!current.startsWith(expected)) {
    return;
  }

  const tail = current.slice(expected.length).trim();
  if (!tail) {
    return;
  }

  const recoveryPath = path.join(directory, `99999999T999999.999Z-recovered-${randomUUID()}.md`);
  const fd = fs.openSync(recoveryPath, "wx", 0o600);
  try {
    fs.writeSync(fd, `${tail}\n`, undefined, "utf8");
  } finally {
    fs.closeSync(fd);
  }
}

export function rebuildDailyProjection(root: string, now = new Date()): string {
  const dailyPath = dailyMemoryPath(root, now);
  const directory = eventDirectory(root, now);

  return withProjectionLock(root, () => {
    fs.mkdirSync(directory, { recursive: true });
    preserveLegacyDailyNote(root, dailyPath, directory);
    preserveUnexpectedProjectionTail(dailyPath, directory);
    const projection = projectionFromEvents(directory);
    const temporaryPath = `${dailyPath}.tmp-${randomUUID()}`;
    fs.writeFileSync(temporaryPath, projection, { encoding: "utf8", mode: 0o600 });
    fs.renameSync(temporaryPath, dailyPath);
    return dailyPath;
  });
}

export function appendMemoryCheckpoint(root: string, input: MemoryCheckpointInput, now = new Date()): { eventPath: string; dailyPath: string } {
  const directory = eventDirectory(root, now);
  const eventPath = path.join(directory, eventFilename(now));
  fs.mkdirSync(directory, { recursive: true });
  const checkpoint = renderMemoryCheckpoint(input);
  const eventFd = fs.openSync(eventPath, "wx", 0o600);
  try {
    fs.writeSync(eventFd, checkpoint, undefined, "utf8");
  } finally {
    fs.closeSync(eventFd);
  }

  const dailyPath = rebuildDailyProjection(root, now);
  return { eventPath, dailyPath };
}

function buildAiEosContext(): { text: string; missing: string[]; root: string } {
  const root = aiEosHome();
  if (!fs.existsSync(root)) {
    return {
      root,
      missing: [root],
      text: [
        "## AI-EOS unavailable",
        `AI-EOS was expected at ${root}, but that path does not exist. Tell Ed immediately.`,
      ].join("\n"),
    };
  }

  const missing: string[] = [];
  const sections: string[] = [];

  for (const relativePath of CORE_FILES) {
    const rendered = section(root, relativePath);
    sections.push(rendered.text);
    if (rendered.missing) {
      missing.push(relativePath);
    }
  }

  const memoryFiles = recentMemoryFiles(root);
  if (memoryFiles.length === 0) {
    missing.push("memory/Memory YYYY-MM-DD.md");
    sections.push("### Recent dated memory\n[No dated memory files found.]");
  } else {
    for (const relativePath of memoryFiles) {
      const rendered = section(root, relativePath);
      sections.push(rendered.text);
      if (rendered.missing) {
        missing.push(relativePath);
      }
    }
  }

  return {
    root,
    missing,
    text: [
      "## AI-EOS canonical context",
      `Location: ${root}`,
      "",
      "AI-EOS is Ed's primary engineering context. Treat harness-local memory, chat history, and repository compatibility files as secondary caches.",
      "Use AI/MEMORY_SYSTEM.md for memory routing. Do not create competing memory files. If documentation conflicts with verified repository or runtime evidence, identify the stale source and recommend updating AI-EOS.",
      "",
      ...sections,
    ].join("\n\n"),
  };
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "ai_eos_memory_checkpoint",
    label: "AI-EOS Memory Checkpoint",
    description: "Store a structured checkpoint as an immutable AI-EOS memory event and rebuild today's projection.",
    promptSnippet: "Store a structured checkpoint as an immutable AI-EOS memory event",
    promptGuidelines: [
      "Use ai_eos_memory_checkpoint before the final answer when a turn learns, fixes, diagnoses, implements, or decides anything significant for AI-EOS continuity; never write the dated projection directly.",
      "Use ai_eos_memory_checkpoint for operational, infrastructure, database, backup, security, deployment, or client-service lessons instead of waiting for session shutdown.",
      "Never put credentials, API keys, passwords, private keys, auth cookies, or other secrets in ai_eos_memory_checkpoint fields.",
    ],
    parameters: {
      type: "object",
      additionalProperties: false,
      required: ["title", "tag", "task", "context"],
      properties: {
        title: { type: "string", description: "Markdown heading for the memory entry, without leading ##." },
        tag: { type: "string", description: "Usually Personal or Work." },
        client: { type: "string", description: "Client identifier such as RETIRE01 when relevant." },
        repo: { type: "string", description: "Repository or system path when relevant." },
        branch: { type: "string", description: "Git branch when relevant." },
        task: { type: "string", description: "Brief task summary." },
        context: { type: "string", description: "Root cause, decision, corrected pattern, or durable lesson." },
        filesChanged: { type: "array", items: { type: "string" } },
        checksRun: { type: "array", items: { type: "string" } },
        commitInfo: { type: "string" },
        followUps: { type: "array", items: { type: "string" } },
      },
    },
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const root = aiEosHome();
      const result = appendMemoryCheckpoint(root, params as MemoryCheckpointInput);
      const state = runStateBySession.get(sessionKey(ctx));
      if (state) {
        state.usedCheckpointTool = true;
      }
      ctx.ui.setStatus(MEMORY_STATUS_KEY, "AI-EOS: checkpoint written");
      return {
        content: [{ type: "text", text: `AI-EOS memory checkpoint stored at ${result.eventPath}; daily projection rebuilt at ${result.dailyPath}` }],
        details: result,
      };
    },
  });

  pi.registerCommand("ai-eos-rebuild-daily", {
    description: "Rebuild today's AI-EOS daily memory projection from immutable events",
    handler: async (_args, ctx) => {
      const dailyPath = rebuildDailyProjection(aiEosHome());
      ctx.ui.notify(`AI-EOS daily projection rebuilt at ${dailyPath}`, "info");
    },
  });

  pi.registerCommand("ai-eos-checkpoint-status", {
    description: "Show the current AI-EOS checkpoint status",
    handler: async (_args, ctx) => {
      const state = runStateBySession.get(sessionKey(ctx));
      const status = state?.needsCheckpoint ? "checkpoint needed" : "no checkpoint currently pending";
      ctx.ui.notify(`AI-EOS: ${status}`, state?.needsCheckpoint ? "warning" : "info");
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    const context = buildAiEosContext();
    if (context.missing.length > 0) {
      ctx.ui.notify(
        `AI-EOS context incomplete: ${context.missing.slice(0, 3).join(", ")}${context.missing.length > 3 ? "..." : ""}`,
        "warning",
      );
    }
    ctx.ui.setStatus(MEMORY_STATUS_KEY, context.missing.length > 0 ? "AI-EOS: incomplete" : "AI-EOS: loaded");
  });

  pi.on("before_agent_start", async (event, ctx) => {
    const context = buildAiEosContext();
    const dailyPath = dailyMemoryPath(context.root);
    runStateBySession.set(sessionKey(ctx), {
      dailyPath,
      before: fileState(dailyPath),
      needsCheckpoint: isLikelyMemoryWorthy(event.prompt || ""),
      usedCheckpointTool: false,
      prompt: event.prompt || "",
    });

    return {
      systemPrompt: `${event.systemPrompt}\n\n${context.text}\n\n${buildMemoryCheckpointInstructions(context.root)}`,
    };
  });

  pi.on("tool_call", async (event, ctx) => {
    const root = aiEosHome();
    if (event.toolName === "write" || event.toolName === "edit") {
      const candidate = (event.input as { path?: unknown }).path;
      if (isProtectedMemoryPath(candidate, root, ctx.cwd || process.cwd())) {
        if (ctx.hasUI) {
          ctx.ui.notify(`Blocked direct write to generated AI-EOS memory projection: ${candidate}`, "warning");
        }
        return { block: true, reason: "Dated AI-EOS memory files are generated projections; use ai_eos_memory_checkpoint." };
      }
    }

    const state = runStateBySession.get(sessionKey(ctx));
    if (!state) {
      return undefined;
    }

    if (event.toolName === "ai_eos_memory_checkpoint") {
      state.usedCheckpointTool = true;
      state.needsCheckpoint = false;
      return undefined;
    }

    const inputText = toolInputText(event.input);
    if (referencesAiEosMemory(inputText, root)) {
      state.usedCheckpointTool = true;
      return undefined;
    }

    if (isMemoryWorthyTool(event.toolName) && (event.toolName !== "bash" || isLikelyMemoryWorthy(inputText))) {
      state.needsCheckpoint = true;
    }

    return undefined;
  });

  pi.on("agent_settled", async (_event, ctx) => {
    const key = sessionKey(ctx);
    const state = runStateBySession.get(key);
    if (!state) {
      return;
    }

    const after = fileState(state.dailyPath);
    const checkpointWritten = state.usedCheckpointTool || fileChanged(state.before, after);
    if (state.needsCheckpoint && !checkpointWritten) {
      ctx.ui.setStatus(MEMORY_STATUS_KEY, "AI-EOS: checkpoint needed");
      ctx.ui.notify(
        `AI-EOS memory checkpoint likely needed. Append to ${state.dailyPath} before considering this work complete.`,
        "warning",
      );
    } else if (checkpointWritten) {
      ctx.ui.setStatus(MEMORY_STATUS_KEY, "AI-EOS: checkpoint written");
    } else {
      ctx.ui.setStatus(MEMORY_STATUS_KEY, "AI-EOS: loaded");
    }

    runStateBySession.delete(key);
  });
}
