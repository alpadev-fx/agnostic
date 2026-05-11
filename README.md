# agnostic

Claude Code framework. One install, any stack.

## Install

```bash
brew install jq gh && gh auth login

git clone https://github.com/alpadev-fx/agnostic.git ~/code/agnostic
mkdir -p ~/bin && ln -s ~/code/agnostic/agnostic ~/bin/agnostic
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Connect Linear + Slack at https://claude.ai/settings/connectors.

## Use

```bash
cd /path/to/project
agnostic init
```

Auto-detects stack, wipes old config, installs framework, enables recommended plugins.

## File map

```
project/
├── CLAUDE.md                  ← agent directives (root, auto-loaded)
└── .claude/
    ├── agnostic.toml          verify cmds + integrations
    ├── settings.json          hook wiring
    ├── settings.local.json    your permission allowlist
    ├── memory/                state (agents/plan/progress/verify/gotchas)
    ├── agents/                6 specialists
    ├── commands/              11 workflows
    ├── hooks/                 6 lifecycle scripts
    └── rules/                 lazy knowledge packs
```

## Commands (L3)

| Command | What |
|---|---|
| `/review` | Multi-agent diff review |
| `/ship` | Test → lint → commit → push → PR |
| `/catchup` | Branch + PR + Linear briefing |
| `/fix-issue <ID>` | TDD fix from GH/Linear |
| `/new-feature <name>` | Scaffold with architect |
| `/bug-hunt` | 4-specialist sweep (report only) |
| `/debug-service <name>` | Root-cause investigation |
| `/add-endpoint <METHOD path>` | Layered impl + tests |
| `/standup` | GH+Linear+Slack digest |
| `/triage-inbox` | Assigned issues + reviews |
| `/notify-team <msg>` | Slack draft |

## Agents (L2)

| Agent | Model |
|---|---|
| architect | opus |
| security-reviewer | opus |
| performance-analyst | opus |
| code-reviewer | sonnet |
| db-specialist | sonnet |
| tdd-guide | sonnet |

## Hooks (L0)

| Hook | When | What |
|---|---|---|
| block-destructive | PreToolUse Bash | Block rm -rf, DROP TABLE, force push, .env reads |
| post-edit-verify | PostToolUse Write/Edit | Lint edited file, block on fail |
| truncation-check | PostToolUse Grep/Bash | Warn if output truncated |
| stop-verify | Stop | Run typecheck+lint+test, block "Done" on fail |
| precompact-summary | PreCompact | Inject summary across compactions |

## Plugins (auto-installed)

`gopls-lsp` · `claude-mem` · `playwright` · `atomic-agents` · `frontend-design` · `caveman`

MCPs added: `stitch`. External (separate install): `gstack`.

Skip with `agnostic init --skip-plugins`.

## Docs

- [INSTALL.md](INSTALL.md) — full install + troubleshoot
- [docs/architecture.md](docs/architecture.md) — L0-L3 + hook contract
- [docs/integrations.md](docs/integrations.md) — MCP matrix
- [docs/token-budget.md](docs/token-budget.md) — anti-patterns
- [docs/bootstrap-guide.md](docs/bootstrap-guide.md) — init internals

## Why

Three patterns mattered most after auditing real Claude Code setups:

1. **Lean always-loaded** — no `@`-refs in CLAUDE.md (auto-loads files, burns 15K tokens/session)
2. **Layered context** — L0 guardrails / L1 lean knowledge / L2 agents / L3 commands / lazy rules
3. **Structural verification** — hooks enforce "Done"; not advisory

MIT.
