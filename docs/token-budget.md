# Token Budget

## Target after install: ~7K tokens always-loaded

| Item | Target |
|---|---|
| CLAUDE.md | ≤3KB / ~750 tokens |
| `.claude/agnostic.toml` | <500 bytes |
| `.claude/settings.json` | <2KB |
| Agent metadata (×6) | ~1.2K |
| Command metadata (×11) | ~1.2K |
| Rules indexes | lazy — only paths frontmatter loaded |

Verify after install: open Claude Code, run `/context`.

## 5 anti-patterns that bloat sessions

### 1. `@`-references in CLAUDE.md
```markdown
See @README.md   ← auto-loads entire README (15KB / session)
```
**Fix:** plain paths (`./README.md`). Claude reads lazily.

### 2. Deep architecture in CLAUDE.md
**Fix:** stub identity in CLAUDE.md, details in `.claude/rules/` with `paths:` frontmatter.

### 3. Multiple browser MCPs
Playwright + Chrome Control + Brave = 50 redundant tool defs.
**Fix:** keep one (Playwright).

### 4. Verbose hooks on every prompt
500-word ruleset × every UserPromptSubmit = ~150 tokens/turn.
**Fix:** hooks silent unless they have something specific to say.

### 5. Unused MCPs
Linear MCP alone = ~25 tool defs even if never called.
**Fix:** `claude mcp list`. Disable unused at claude.ai/settings/connectors.

## Model tiering

- **Opus** — judgment (architect, security, perf)
- **Sonnet** — execution (code review, db, tests)
- **Haiku** — mechanical (search, grep)

Set per agent via `model:` frontmatter. Don't make everything Opus.

## Compaction

When context fills, Claude Code compacts old turns. `PreCompact` hook injects 1-2 sentence summary from `.claude/agnostic.toml [project] summary` so identity survives.
