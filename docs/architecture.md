# Architecture

## Principles

1. **Token economy is a feature** — every byte in CLAUDE.md costs every session. Default lazy.
2. **Verification is structural** — agents say "Done" too easily. Hooks enforce.
3. **Layered context** — L0/L1 always-loaded, L2/L3/Rules on demand.
4. **Stack-agnostic core** — universal patterns + opt-in stack packs.
5. **Model tiering** — opus for judgment, sonnet for execution.

## Layers

```
L0 Guardrails    always-loaded   hooks + permissions
L1 Knowledge     always-loaded   CLAUDE.md (≤3KB, no @-refs) + .claude/agnostic.toml
L2 Agents        on demand       6 specialists (architect, security, perf, ...)
L3 Commands      on demand       11 workflows (/review, /ship, /catchup, ...)
Rules            on demand       universal + per-stack (paths: frontmatter)
```

## Runtime loop

```
UserPromptSubmit
 → Claude Reasoning
 → PreToolUse hook         (block destructive)
 → Permission check
 → Tool execution
 → PostToolUse hook        (block on lint fail / warn on truncation)
[repeat]
 → Stop hook               (block "Done" if typecheck/lint/test fail)
 → PreCompact hook         (inject summary at context limit)
 → Message delivered
```

## Hook contract

Hooks emit JSON to stdout.

**Block destructive Bash:**
```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}
```

**Block agent on lint fail:**
```json
{"decision":"block","reason":"Lint failed: ..."}
```

**Non-blocking warning:**
```json
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"WARNING: ..."}}
```

## Layout

```
agnostic/
├── agnostic                 CLI
├── bootstrap/
│   ├── detect-stack.sh      stack probe (monorepo aware)
│   ├── discover.sh          auto-discovery (README, Makefile, git, ...)
│   ├── install-plugins.sh   plugin + MCP install (~/.claude/settings.json)
│   └── install.sh           wipe + write
├── templates/               CLAUDE.md, agnostic.toml, settings.*, memory/
├── hooks/                   6 lifecycle scripts
├── agents/                  6 specialists
├── commands/                11 workflows
└── rules/                   universal + 5 stack packs
```

## Extension

### Add agent
```markdown
---
name: my-agent
description: When to use
tools: Read, Grep
model: sonnet
---
Body.
```
Drop in `agents/`.

### Add command
```markdown
---
allowed-tools: Bash, Read
argument-hint: [args]
description: One-line
model: claude-sonnet-4-6
---
Workflow.
```
Drop in `commands/`.

### Add stack rule pack
1. `mkdir rules/<stack>/`
2. Add `.md` files with `paths: ["**/*.<ext>"]` frontmatter
3. Update `bootstrap/install.sh` stack→dir mapping

## Non-goals

Plugin marketplace · 3-way merge updates · telemetry · GUI · sandbox config.
