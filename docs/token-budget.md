# Token Budget — Rules of Thumb

## The Big Picture

Claude Code session boot loads:
1. System prompt (fixed)
2. Project CLAUDE.md(s) (configurable)
3. Hooks/settings metadata (small)
4. Available skill/command/agent index (small)
5. MCP tool definitions (can be large)

You control items 2–5. Items 4–5 leak tokens when neglected.

## Targets (MVP-installed agnostic)

| Item | Target | Notes |
|---|---|---|
| CLAUDE.md (project) | ≤3KB / ~750 tokens | Stack identity, build cmds, hard rules |
| CLAUDE.md (global, optional) | ≤2KB / ~500 tokens | Credentials, user prefs |
| agnostic.toml | <500 bytes | Verify cmd config + summary |
| Settings.json | <2KB | Hook wiring, plugins |
| Agent metadata | ~200 tokens × 6 = 1.2K | Frontmatter only loads at start |
| Command metadata | ~150 tokens × 8 = 1.2K | Frontmatter only |
| Rules indexes | ~100 tokens × N | Path filters only — bodies lazy |

**Total baseline:** ~7K tokens always-loaded with agnostic installed.

## The 5 Anti-Patterns That Bloat Sessions

### 1. `@`-references in CLAUDE.md
```markdown
See @README.md          # ← auto-loads entire README
Config: @.golangci.yml  # ← auto-loads entire file
```
Each `@`-ref loads the referenced file's full content on every session start. A "See @README.md" in a 50-line CLAUDE.md can balloon to 15KB of always-loaded content.

**Fix:** use plain paths (`./README.md`) — Claude reads them lazily.

### 2. Deep architecture details in CLAUDE.md
Putting full architecture documentation in `CLAUDE.md` makes every session pay for context that's only relevant when actively designing.

**Fix:** stub identity in `CLAUDE.md`, deep details in `.claude/rules/` with `paths:` frontmatter so they load only when relevant.

### 3. Multiple browser MCP servers
Browser automation MCP servers each load 10-30 tool definitions. Having 3 (Playwright + Chrome Control + Brave) loads ~50 redundant tool defs.

**Fix:** pick one. Playwright is the strongest default.

### 4. Caveman / verbose hooks on every prompt
A hook that prints a 500-word ruleset on every `UserPromptSubmit` costs ~150 tokens per turn. Multiply by turns per session.

**Fix:** hooks should be silent unless they have something specific to say.

### 5. Unused MCP integrations
Each MCP server adds tool definitions to context even if you never call those tools. Linear MCP alone = ~25 tool defs.

**Fix:** disable MCP integrations you don't use. `claude mcp list` to audit; visit claude.ai/settings/connectors for cloud-hosted ones.

## Compaction Strategy

When context approaches its limit, Claude Code compacts older turns. The `PreCompact` hook is your chance to inject a short summary that survives compaction.

agnostic's `precompact-summary.sh` reads `agnostic.toml [project] summary` and injects it. Keep this 1-2 sentences — its job is to preserve identity, not detail.

## Model Tiering Saves Tokens AND Cost

- **Opus** → judgment-heavy work (architecture, security audit, plan review)
- **Sonnet** → execution (code review, db work, implementation)
- **Haiku** → mechanical (search, file listing, simple grep)

Each agent file in `agnostic/agents/` specifies its tier via `model:` frontmatter. Don't make everything Opus; the framework defaults are tuned.

## Verification

After installing agnostic into a project, start a fresh Claude Code session and run:

```bash
# In Claude Code, type:
/context
```

This shows your token baseline. Target: <8K. If higher, audit the bloat patterns above.
