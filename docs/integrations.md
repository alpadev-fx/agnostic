# Integrations

## Required

**gh CLI** — `/ship`, `/catchup`, `/fix-issue`, `/new-feature`, `/standup`, `/triage-inbox`.
```bash
brew install gh && gh auth login
```

## Recommended

Connect at https://claude.ai/settings/connectors:
- **Linear** — `/fix-issue`, `/catchup`, `/standup`, `/triage-inbox`
- **Slack** — `/standup`, `/notify-team`

Verify: `claude mcp list | grep -E "Linear|Slack"`

## Auto-installed by `agnostic init`

**Plugins → `~/.claude/settings.json`:**

| Plugin | What |
|---|---|
| `gopls-lsp@claude-plugins-official` | Go LSP |
| `claude-mem@thedotmack` | persistent memory |
| `playwright@claude-plugins-official` | browser MCP |
| `atomic-agents@claude-plugins-official` | focused agent pattern |
| `frontend-design@claude-plugins-official` | UI helpers |
| `caveman@caveman` | terse mode |
| `headroom@headroom-marketplace` | startup hooks / context savings |

**Marketplaces:** `thedotmack` · `caveman` · `headroom-marketplace`

**MCP via `claude mcp add`:** `stitch` (https://stitch.googleapis.com/mcp)

**Skill via `git clone`:** `gstack` → `~/.claude/skills/gstack` (from `github.com/garrytan/gstack`)

Skip: `agnostic init --skip-plugins`.

## Command × integration matrix

| Command | gh | Linear | Slack |
|---|:-:|:-:|:-:|
| `/ship` | ✓ | – | optional |
| `/catchup` | ✓ | ✓ | – |
| `/fix-issue <ID>` | ✓ | ✓ | – |
| `/standup` | ✓ | ✓ | ✓ |
| `/triage-inbox` | ✓ | ✓ | – |
| `/notify-team` | – | – | ✓ |
| `/new-feature` | ✓ | optional | – |
| `/review` | – | – | – |
| `/bug-hunt` | – | optional | – |
| `/add-endpoint` | – | – | – |
| `/debug-service` | – | – | – |

## Slack safety

Allowlist: `send_message_draft` ✓ · `send_message` ✗

Agent always drafts → user reviews → user sends.

## Knowledge map (Obsidian + graphify)

`graphify` (skill at `~/.claude/skills/graphify`) turns any pile of documents into an Obsidian vault of linked notes — the map. Build/refresh with `/map [source]`. Vault path: `.claude/agnostic.toml [map] vault` (default `vault`).

The map is durable, brain-agnostic memory: read relevant notes before acting on a documented domain, write findings back as linked notes, load selectively.

## Brains (multi-CLI)

`CLAUDE.md` is the single directives source. `agnostic init` mirrors it to `AGENTS.md` (symlink), so any agentic CLI shares the same brain:

| Brain | Reads |
|---|---|
| Claude Code | `CLAUDE.md` + `.claude/` |
| Codex CLI | `AGENTS.md` → `CLAUDE.md` |
| Antigravity CLI | `AGENTS.md` → `CLAUDE.md` |

All read the same Obsidian map. Switch brains without losing state.

## Optional

- **Atlassian MCP** — substitute Linear if Jira (don't enable both)
- **Gmail / Calendar / Figma** — ad-hoc, no command wired
