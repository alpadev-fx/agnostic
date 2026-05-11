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

**Marketplaces:** `thedotmack` · `caveman`

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

## Optional

- **Atlassian MCP** — substitute Linear if Jira (don't enable both)
- **Gmail / Calendar / Figma** — ad-hoc, no command wired
