# agnostic

Opinionated Claude Code framework — bootstrap, layered context, on-demand orchestration, runtime verification.

A reusable kit to make Claude Code work consistently across any project. Drop it into a Go service, a React app, a Python monolith, or a Terraform repo — same workflow, same guarantees, same token budget.

## Why

After auditing a sophisticated Claude Code setup, three patterns mattered most:

1. **Lean always-loaded knowledge** — no `@`-references in CLAUDE.md (they auto-load entire files; one project was burning ~15K tokens/session on this alone).
2. **Layered context** — L0 (hooks/permissions), L1 (lean CLAUDE.md), L2 (agents), L3 (commands), Rules (loaded on demand). Each layer earns its place.
3. **Runtime verification gates** — PreToolUse blocks destructive ops; PostToolUse lints edits; Stop verifies the project compiles before the agent claims done.

This framework packages those patterns + sensible defaults + per-stack rule packs.

## Architecture

```
LedgerFi-style L0–L3:

├── L0 Guardrails (always loaded)
│   ├── hooks: PreToolUse / PostToolUse / Stop / PreCompact
│   ├── permissions: allowlist in settings.local.json
│   └── settings: per-agent model tiering
├── L1 Knowledge (always loaded — SLIM, no @-refs)
│   ├── CLAUDE.md: stack identity, build commands, hard rules (~3KB target)
│   └── agnostic.toml: project verify commands + compaction summary
├── On Demand
│   ├── L2 Agents (6): architect, code-reviewer, security-reviewer,
│   │                  performance-analyst, db-specialist, tdd-guide
│   ├── L3 Commands (8): /review /ship /catchup /fix-issue /new-feature
│   │                    /bug-hunt /debug-service /add-endpoint
│   └── Rules: universal/ + per-stack packs (backend-go, backend-node,
│              backend-python, frontend-react, infra-terraform)
└── Runtime Loop
    UserPromptSubmit → Reasoning → PreToolUse → Permission/Sandbox
    → Tool → PostToolUse → Stop Verification (gate, not injection)
```

## Quick Start

```bash
git clone <repo> ~/code/agnostic
ln -s ~/code/agnostic/agnostic /usr/local/bin/agnostic
cd /path/to/your/project
agnostic init
```

**Full install guide:** see [INSTALL.md](INSTALL.md) — backup behavior, override modes (`--force`, `--no-overwrite`, `--dry-run`), troubleshooting.

> **Important:** `agnostic init` **overwrites any existing `.claude/` framework files** (hooks, agents, commands, rules, settings.json). Your existing `.claude/` is backed up to `.claude.bak.<timestamp>` first. User-managed files (`CLAUDE.md`, `agnostic.toml`, `.claude/settings.local.json`) are preserved unless `--force`.

What gets installed:

```
your-project/
├── .claude/
│   ├── hooks/                    # 6 lifecycle scripts (overwritten on install)
│   ├── agents/                   # 6 specialist agents (overwritten)
│   ├── commands/                 # 8 slash commands (overwritten)
│   ├── rules/                    # universal + per-stack rule packs (overwritten)
│   ├── settings.json             # hook wiring (overwritten)
│   └── settings.local.json       # permission allowlist (preserved, gitignored)
├── CLAUDE.md                     # slim, no @-refs (preserved if exists)
└── agnostic.toml                 # project verify commands (preserved if exists)
```

## After Install

1. **Edit `CLAUDE.md`** — fill TODOs: description, build cmds, 5-10 hard rules, arch pointers. NEVER use `@` references.
2. **Edit `agnostic.toml`** — adjust `[verify]` commands if heuristics aren't right.
3. **Edit `.claude/settings.local.json`** — add project-specific permission allowlist.
4. **Open Claude Code** in the project. Try `/catchup`, `/review`, `/bug-hunt`.

## Commands (L3)

| Command | Purpose | Default model | Integrations |
|---|---|---|---|
| `/review` | Multi-axis diff review (security + perf + code quality) | Opus | — |
| `/ship` | Tests → lint → commit → push → open PR | Sonnet | gh |
| `/catchup` | Branch + PR + activity briefing | Sonnet | gh, Linear |
| `/fix-issue <ID>` | TDD fix flow from GH/Linear issue | Opus | gh, Linear |
| `/new-feature <name>` | Scaffold feature with architect input | Opus | gh |
| `/bug-hunt` | 4-specialist parallel sweep, report only | Opus | — |
| `/debug-service <name>` | Root-cause investigation, no fixes without RC | Opus | — |
| `/add-endpoint <METHOD path>` | Layered impl with tests | Sonnet | — |
| `/standup [yesterday\|week]` | Daily digest from GH + Linear + Slack | Sonnet | gh, Linear, Slack |
| `/triage-inbox` | Triage assigned issues + review requests | Sonnet | gh, Linear |
| `/notify-team <msg>` | Draft Slack announcement, user confirms send | Sonnet | Slack |

Required: `gh` CLI. Recommended MCPs: Linear, Slack. See [docs/integrations.md](docs/integrations.md).

## Agents (L2)

| Agent | Model | Use |
|---|---|---|
| `architect` | Opus | Design decisions, layering, blast radius |
| `code-reviewer` | Sonnet | Quality, patterns, testing coverage |
| `security-reviewer` | Opus | Auth, input validation, secrets, OWASP |
| `performance-analyst` | Opus | Big-O, N+1, hot paths, memory |
| `db-specialist` | Sonnet | Schema, migrations, indexing, queries |
| `tdd-guide` | Sonnet | Test structure, mocking, coverage strategy |

## Hooks (L0)

| Hook | When | What |
|---|---|---|
| `block-destructive.sh` | PreToolUse(Bash) | Blocks rm -rf /, DROP TABLE, force push, .env reads |
| `post-edit-verify.sh` | PostToolUse(Write/Edit) | Lints the edited file; blocks Claude if lint fails |
| `truncation-check.sh` | PostToolUse(Grep/Bash) | Warns when tool output was truncated |
| `stop-verify.sh` | Stop | Runs typecheck + lint + tests; blocks "Done" if any fails |
| `precompact-summary.sh` | PreCompact | Injects project identity into compacted context |

Hooks read `agnostic.toml` for project-specific override commands; fall back to heuristics (eslint/ruff/golangci-lint/tsc/pytest detection).

## Rules

Rules are markdown files with optional `paths:` frontmatter. When an agent or skill reads a file matching `paths`, the corresponding rule loads into context. Result: stack-specific knowledge present only when relevant.

```yaml
---
paths:
  - "**/*.go"
---
# Go-specific rules content
```

Universal rules always loadable; stack rules conditional on file match.

## Customization

This is a **kit**, not a sealed framework. After `agnostic init`:
- Edit anything in `.claude/` to fit your project
- Add new agents, commands, rules — your additions in NEW files won't be overwritten
- Run `agnostic update` (alias for `init --force`) to refresh framework files. Your additions to EXISTING framework files WILL be overwritten — back up first.

See [INSTALL.md](INSTALL.md) for the full override matrix.

## Token Budget

Approximate baseline always-loaded after init (per session):
- CLAUDE.md: ~750 tokens (target <3KB)
- Settings + hooks metadata: ~500 tokens
- Agent/command/rule indexes: ~1500 tokens

Vs. a typical unoptimized project: 25K+ tokens always-loaded.

Savings come from:
- No `@`-references in CLAUDE.md
- Rules loaded lazily by `paths:` frontmatter
- Agents/commands metadata only; bodies load when invoked
- Verify commands in `agnostic.toml` keep hooks generic

## License

MIT. Copy, fork, modify.

## Status

MVP — built from one production setup (financial SaaS) and generalized. Battle-tested for Go/React/Python monorepos. Other stacks (Rust, Ruby) have rules scaffolds; refine as you use them.
