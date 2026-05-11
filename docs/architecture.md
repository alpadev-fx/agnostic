# Architecture — agnostic

## Design Principles

### 1. Token economy is a feature
Every byte in `CLAUDE.md` is paid for on every session start. Lazy-loaded files are free until needed. Default to lazy.

**Concrete rules:**
- `CLAUDE.md` ≤ 3KB target
- No `@`-references in `CLAUDE.md` (they auto-load the referenced file's full content)
- Stack-specific knowledge lives in `.claude/rules/<stack>/*.md` with `paths:` frontmatter
- Agent/command bodies load only when invoked

### 2. Verification is structural, not advisory
Agents say "Done" too easily. Hooks enforce it.

- `Stop` hook runs typecheck + lint + tests; blocks completion if any fail
- `PostToolUse` runs per-file lint on every Write/Edit; blocks Claude when lint fails
- `PreToolUse` blocks destructive commands (rm -rf, DROP TABLE, force-push)

### 3. Layered context (L0–L3)

```
L0 Guardrails       always loaded     hooks + permissions
L1 Knowledge        always loaded     CLAUDE.md + agnostic.toml (slim)
L2 Agents           on demand         6 specialists
L3 Commands         on demand         8 workflows
Rules               on demand         universal + per-stack
```

Each layer has a job:
- L0: prevent footguns
- L1: identity (what stack? what hard rules?)
- L2: when you need a specialist (deep architecture, security review)
- L3: when you need a workflow (ship, review, fix-issue)
- Rules: when you need stack-specific patterns

### 4. Stack-agnostic core, stack-specific extension
The framework core is universal. Stack-specific knowledge is in opt-in rule packs detected at install time. Adding a new stack means adding a `rules/<stack>/` directory — no core changes.

### 5. Model tiering by cognitive load
Not every agent needs Opus. The default tiering:
- Opus: architect, security-reviewer, performance-analyst (judgment-heavy)
- Sonnet: code-reviewer, db-specialist, tdd-guide (pattern-matching-heavy)

## Runtime Loop

```
UserPromptSubmit
  ↓
Claude Reasoning
  ↓
PreToolUse hook ─────→ (block if destructive)
  ↓
Permission check
  ↓
Tool Execution
  ↓
PostToolUse hook ────→ (block if lint fails / warn if output truncated)
  ↓
[repeat until done]
  ↓
Stop hook ────────────→ (block if typecheck/lint/test fail)
  ↓
PreCompact hook ─────→ (only when context near limit; inject summary)
  ↓
Message Delivered
```

## File Layout

```
agnostic/
├── README.md
├── agnostic                  CLI wrapper
├── bootstrap/
│   ├── detect-stack.sh        Probes target dir for stack markers
│   └── install.sh             Copies templates, fills variables
├── templates/
│   ├── CLAUDE.md.tmpl
│   ├── settings.json.tmpl
│   ├── settings.local.json.tmpl
│   └── agnostic.toml.tmpl
├── hooks/                     Universalized from production setup
├── agents/                    6 archetypes (stack-agnostic)
├── commands/                  8 workflows (stack-agnostic)
├── rules/
│   ├── universal/             general, security, ci-cd
│   ├── backend-go/
│   ├── backend-node/
│   ├── backend-python/
│   ├── frontend-react/
│   └── infra-terraform/
└── docs/
    └── architecture.md
```

## Hook Output Contract

Hooks communicate with Claude Code via stdout JSON.

### PreToolUse — block
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked rm -rf /"
  }
}
```

### PostToolUse — surface error to agent
```json
{
  "decision": "block",
  "reason": "Lint failed. Fix before continuing: <errors>"
}
```

### PostToolUse — additional context (warning, doesn't block)
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "WARNING: output truncated"
  }
}
```

### PreCompact — inject context-preserving summary
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Project: X. Hard rules: Y. See CLAUDE.md."
  }
}
```

## Extension Points

### Add a new agent
Drop a markdown file with frontmatter into `agents/`:
```markdown
---
name: my-agent
description: When to use
tools: Read, Grep
model: sonnet
---
Body content
```

### Add a new command
Drop a markdown file into `commands/`:
```markdown
---
allowed-tools: Bash, Read
argument-hint: [args]
description: One-line
model: claude-sonnet-4-6
---
Workflow body
```

### Add a new stack rule pack
Create `rules/<stack-name>/<rule>.md` with `paths:` frontmatter pointing at the file globs that should trigger this rule:
```yaml
---
paths:
  - "**/*.rs"
  - "Cargo.toml"
---
```

Then update `bootstrap/install.sh` to map detected stack to your new directory.

## Non-Goals (for MVP)

- Plugin marketplace
- Update diffing / 3-way merge (use `agnostic update --force` + git for now)
- Telemetry / usage analytics
- GUI / TUI
- Sandbox configuration (Claude Code handles this — framework doesn't add to it)
