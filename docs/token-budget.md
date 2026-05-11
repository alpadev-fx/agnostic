# Token Budget

## Target: ~7K tokens always-loaded

| Item | Target |
|---|---|
| CLAUDE.md | ≤3KB / ~750 tokens |
| `.claude/agnostic.toml` | <500 bytes |
| `.claude/settings.json` | <2KB |
| Agent metadata (×6) | ~1.2K |
| Command metadata (×11) | ~1.2K |
| Rules indexes | lazy — paths frontmatter only |

Verify: `/context` in Claude Code.

## 5 anti-patterns

**1. `@`-refs in CLAUDE.md**
```
See @README.md   ← auto-loads entire file (15KB/session)
```
Fix: plain paths (`./README.md`).

**2. Deep architecture in CLAUDE.md**
Fix: stub in CLAUDE.md, details in `.claude/rules/` with `paths:` frontmatter.

**3. Multiple browser MCPs**
Playwright + Chrome + Brave = 50 redundant tool defs.
Fix: keep one (Playwright).

**4. Verbose hooks per prompt**
500-word ruleset × every turn = ~150 tokens/turn.
Fix: silent unless something specific to say.

**5. Unused MCPs**
Linear MCP = ~25 tool defs even unused.
Fix: `claude mcp list` → disable at claude.ai/settings/connectors.

## Model tiering

| Tier | Use |
|---|---|
| Opus | architect, security, perf — judgment |
| Sonnet | code review, db, tdd — execution |
| Haiku | search, grep — mechanical |

Set via `model:` frontmatter per agent. Don't make everything Opus.

## Compaction

`PreCompact` hook injects 1-2 sentence summary from `.claude/agnostic.toml [project] summary` so identity survives.
