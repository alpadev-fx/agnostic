# agnostic

Agentic-CLI framework. One command, any stack, any brain (Claude Code · Codex · Antigravity).

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
    ├── memory/               state (agents/plan/progress/verify/gotchas/learning)
    ├── agents/               7 specialists
    ├── commands/             12 workflows
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
| `/learn [track] [topic]` | Mentor-led expertise session (python/c/cpp/asm/rpi/opi) |
| `/map [source]` | Build/refresh the Obsidian knowledge map via graphify |

## Agents (L2)

`architect` · `security-reviewer` · `performance-analyst` · `mentor` (opus)
`code-reviewer` · `db-specialist` · `tdd-guide` (sonnet)

## Rules packs (L1)

`universal` always (`general` · `security` · `ci-cd` · `knowledge-map`). By detected stack: `backend-go` · `backend-node` · `backend-python` · `frontend-react` · `infra-terraform` · `systems-c` · `systems-cpp` · `systems-asm` · `embedded-rpi` · `embedded-opi`

## Knowledge map & brains

`graphify` turns any pile of documents into an **Obsidian vault** of real, linked notes — the map. Build or refresh it with `/map`. Any agentic **brain** reads the map and executes: **Claude Code · Codex CLI · Antigravity CLI**. `CLAUDE.md` is the single source of truth; `agnostic init` mirrors it to `AGENTS.md` so every brain shares the same directives + map.

Every task runs as a **solve loop** — understand → act → verify → correct, until proven done. The `stop-verify` hook blocks "Done" while typecheck/lint/test fail.

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
