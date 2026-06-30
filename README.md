# agnostic

Claude Code framework. One command, any stack.

```bash
agnostic init
```

Wipes prior agent config. Discovers project from files. Installs framework. Enables plugins.

## Install (1× per machine)

```bash
brew install jq gh && gh auth login
git clone https://github.com/alpadev-fx/agnostic.git ~/code/agnostic
mkdir -p ~/bin && ln -s ~/code/agnostic/agnostic ~/bin/agnostic
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Connect Linear + Slack: https://claude.ai/settings/connectors

## File map

```
project/
├── CLAUDE.md                 agent directives (root, auto-loaded)
└── .claude/
    ├── agnostic.toml         verify cmds + integrations
    ├── settings.json         hook wiring
    ├── settings.local.json   permission allowlist
    ├── memory/               state (agents/plan/progress/verify/gotchas)
    ├── agents/               6 specialists
    ├── commands/             11 workflows
    ├── hooks/                6 lifecycle scripts
    └── rules/                lazy knowledge packs
```

## Commands (L3)

| Cmd | What |
|---|---|
| `/review` | Multi-agent diff review |
| `/ship` | Test → lint → commit → push → PR |
| `/catchup` | Branch + PR + Linear briefing |
| `/fix-issue <ID>` | TDD fix from GH/Linear |
| `/new-feature <name>` | Scaffold with architect |
| `/bug-hunt` | 4-specialist sweep (report) |
| `/debug-service <name>` | Root-cause investigation |
| `/add-endpoint <METHOD path>` | Layered impl + tests |
| `/standup` | GH + Linear + Slack digest |
| `/triage-inbox` | Assigned issues + reviews |
| `/notify-team <msg>` | Slack draft |

## Agents (L2)

`architect` · `security-reviewer` · `performance-analyst` (opus)
`code-reviewer` · `db-specialist` · `tdd-guide` (sonnet)

## Hooks (L0)

| Hook | When | What |
|---|---|---|
| `block-destructive` | PreToolUse Bash | Block rm -rf, DROP, force push, .env reads |
| `post-edit-verify` | PostToolUse Write/Edit | Lint edited file, block on fail |
| `truncation-check` | PostToolUse Grep/Bash | Warn if output truncated |
| `stop-verify` | Stop | Run typecheck+lint+test, block on fail |
| `precompact-summary` | PreCompact | Inject summary across compactions |

## Auto-installed

**Plugins** (`~/.claude/settings.json`):
`gopls-lsp` · `claude-mem` · `playwright` · `atomic-agents` · `frontend-design` · `caveman` · `headroom`

**MCP:** `stitch`

**Skill:** `gstack` (cloned to `~/.claude/skills/gstack`)

Skip: `agnostic init --skip-plugins`.

## Docs

[INSTALL](INSTALL.md) · [architecture](docs/architecture.md) · [integrations](docs/integrations.md) · [token-budget](docs/token-budget.md) · [bootstrap-guide](docs/bootstrap-guide.md)

MIT.
