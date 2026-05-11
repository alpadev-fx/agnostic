# agnostic

Opinionated Claude Code framework. One install, any stack.

## Install

```bash
git clone https://github.com/alpadev-fx/agnostic.git ~/code/agnostic
mkdir -p ~/bin && ln -s ~/code/agnostic/agnostic ~/bin/agnostic
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

cd /path/to/your/project
agnostic init
```

See [INSTALL.md](INSTALL.md) for full guide.

## What you get

```
your-project/
├── CLAUDE.md          ← always-loaded agent directives
└── .claude/
    ├── agnostic.toml         verify commands + integrations config
    ├── settings.json         hook wiring
    ├── settings.local.json   your permission allowlist
    ├── memory/               agents/plan/progress/verify/gotchas
    ├── agents/               6 specialists
    ├── commands/             11 slash workflows
    ├── hooks/                6 lifecycle scripts
    └── rules/                lazy-loaded knowledge packs
```

## Commands (L3)

| Command | Purpose |
|---|---|
| `/review` | Multi-agent diff review (security + perf + code quality) |
| `/ship` | Tests → lint → commit → push → open PR |
| `/catchup` | Branch + PR + Linear activity briefing |
| `/fix-issue <ID>` | TDD fix flow from GH or Linear issue |
| `/new-feature <name>` | Scaffold feature with architect input |
| `/bug-hunt` | 4-specialist parallel sweep, report only |
| `/debug-service <name>` | Root-cause investigation |
| `/add-endpoint <METHOD path>` | Layered impl with tests |
| `/standup` | GH + Linear + Slack digest |
| `/triage-inbox` | Assigned issues + PR reviews |
| `/notify-team <msg>` | Slack draft, user confirms send |

## Agents (L2)

| Agent | Model | Use |
|---|---|---|
| `architect` | opus | Design, layering, blast radius |
| `security-reviewer` | opus | Auth, validation, secrets, OWASP |
| `performance-analyst` | opus | Big-O, N+1, hot paths |
| `code-reviewer` | sonnet | Quality, patterns, testing |
| `db-specialist` | sonnet | Schema, migrations, queries |
| `tdd-guide` | sonnet | Tests, mocking, coverage |

## Hooks (L0)

| Hook | When | What |
|---|---|---|
| `block-destructive` | PreToolUse(Bash) | Blocks rm -rf, DROP TABLE, force push, .env reads |
| `post-edit-verify` | PostToolUse(Write/Edit) | Lints edited file; blocks Claude on errors |
| `truncation-check` | PostToolUse(Grep/Bash) | Warns when output truncated |
| `stop-verify` | Stop | Runs typecheck+lint+test; blocks "Done" on fail |
| `precompact-summary` | PreCompact | Injects project summary across compactions |

## How it works

1. **Wipe** prior agent configs (`.claude/`, `CLAUDE.md`, `agent-md.toml`, etc.)
2. **Discover** project answers from README, Makefile, `go.mod`/`package.json`/`pyproject.toml`, `CLAUDE.md.bak`, `git remote`/branch
3. **Generate** CLAUDE.md (agent-md Directives, 15 sections) + `.claude/agnostic.toml` + `.claude/memory/` with discovered values
4. **Install** framework files (hooks, agents, commands, rules)
5. **Preserve** `.claude/settings.local.json` (your permissions), `.githooks/`, `.gemini/`

## Why

After auditing one sophisticated Claude Code setup, three patterns mattered:

1. **Lean always-loaded knowledge** — no `@`-references (they auto-load entire files; one project was burning ~15K tokens/session on this).
2. **Layered context** — L0 hooks / L1 lean CLAUDE.md / L2 agents / L3 commands / lazy rules. Each layer earns its place.
3. **Runtime verification gates** — PreToolUse blocks destructive ops; Stop verifies project compiles before agent claims done.

## Docs

- [INSTALL.md](INSTALL.md) — install + troubleshooting
- [docs/architecture.md](docs/architecture.md) — L0-L3 design + hook contract
- [docs/token-budget.md](docs/token-budget.md) — anti-patterns + savings rules
- [docs/integrations.md](docs/integrations.md) — MCP matrix (gh / Linear / Slack)

## License

MIT.
