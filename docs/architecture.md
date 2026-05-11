# Architecture

## Principles

1. **Token economy as a feature** — every byte in CLAUDE.md costs every session. Default to lazy loading.
2. **Verification is structural** — agents say "Done" too easily. Hooks enforce it.
3. **Layered context** — L0 guardrails / L1 lean knowledge / L2 agents / L3 commands / lazy rules.
4. **Stack-agnostic core** — universal patterns + opt-in per-stack rule packs.
5. **Model tiering** — Opus for judgment (architect, security, perf), Sonnet for execution.

## Layers

```
L0 Guardrails    always-loaded    hooks + permissions
L1 Knowledge     always-loaded    CLAUDE.md (≤3KB, no @-refs) + agnostic.toml
L2 Agents        on demand        6 specialists
L3 Commands      on demand        11 slash workflows
Rules            on demand        universal + per-stack (paths: frontmatter)
```

## Runtime loop

```
UserPromptSubmit
 → Reasoning
 → PreToolUse hook (block destructive)
 → Permission check
 → Tool execution
 → PostToolUse hook (block on lint fail / warn on truncation)
 [repeat]
 → Stop hook (block "Done" if typecheck/lint/test fail)
 → PreCompact hook (inject project summary)
 → Message delivered
```

## Hook contract

Hooks emit JSON to stdout. Examples:

**Block destructive Bash:**
```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked rm -rf /"}}
```

**Block agent on lint fail:**
```json
{"decision":"block","reason":"Lint failed: <errors>"}
```

**Add warning (non-blocking):**
```json
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"WARNING: output truncated"}}
```

## Layout

```
agnostic/
├── agnostic                   CLI
├── bootstrap/
│   ├── detect-stack.sh        Stack probe (monorepo aware)
│   ├── discover.sh            Auto-discovery (README, Makefile, git, ...)
│   └── install.sh             Wipe + write
├── templates/
│   ├── CLAUDE.md.tmpl         Agent-md Directives (15 sections)
│   ├── agnostic.toml.tmpl     [project][verify][integrations]
│   ├── settings.json.tmpl     Hook wiring
│   ├── settings.local.json.tmpl
│   └── memory/                Stub: agents/plan/progress/verify/gotchas
├── hooks/                     6 lifecycle scripts
├── agents/                    6 specialists
├── commands/                  11 workflows
└── rules/                     universal + 5 stack packs
```

## Extension

### New agent
```markdown
---
name: my-agent
description: When to use
tools: Read, Grep
model: sonnet
---
Body
```
Drop in `agents/`.

### New command
```markdown
---
allowed-tools: Bash, Read
argument-hint: [args]
description: One-line
model: claude-sonnet-4-6
---
Workflow body
```
Drop in `commands/`.

### New stack rule pack
1. `mkdir rules/<stack>/`
2. Add `.md` files with `paths:` frontmatter:
   ```yaml
   ---
   paths: ["**/*.rs", "Cargo.toml"]
   ---
   ```
3. Update `bootstrap/install.sh` stack→dir mapping.

## Non-goals

Plugin marketplace, 3-way merge updates, telemetry, GUI, sandbox config.
