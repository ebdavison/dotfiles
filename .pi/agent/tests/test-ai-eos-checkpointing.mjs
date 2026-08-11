#!/usr/bin/env node
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const testDir = dirname(fileURLToPath(import.meta.url));
const extensionPath = resolve(testDir, '../extensions/ai-eos-context.ts');
const source = readFileSync(extensionPath, 'utf8');

assert.match(source, /registerTool\s*\(\s*{[\s\S]*name:\s*["']ai_eos_memory_checkpoint["']/,
  'AI-EOS extension should register ai_eos_memory_checkpoint tool');
assert.match(source, /pi\.on\(["']agent_settled["']/,
  'AI-EOS extension should hook agent_settled to check for missing checkpoints');
assert.match(source, /pi\.on\(["']tool_call["']/,
  'AI-EOS extension should observe tool calls to detect mutations and checkpoint calls');
assert.match(source, /appendMemoryCheckpoint/,
  'AI-EOS extension should append structured entries to dated memory files');
assert.match(source, /ai-eos-checkpoint-status/,
  'AI-EOS extension should expose a status command for checkpoint state');

console.log('AI-EOS checkpointing extension structure verified');
