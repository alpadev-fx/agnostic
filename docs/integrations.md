# Integrations

## Required

**GitHub CLI** (`gh`) — used by `/ship`, `/catchup`, `/fix-issue`, `/new-feature`, `/standup`, `/triage-inbox`.

```bash
brew install gh && gh auth login
```

## Recommended (connect at https://claude.ai/settings/connectors)

- **Linear MCP** — `/fix-issue`, `/catchup`, `/standup`, `/triage-inbox`
- **Slack MCP** — `/standup`, `/notify-team`

Verify:
```bash
claude mcp list | grep -E "Linear|Slack"
```

## Optional

- **Atlassian MCP** — substitute for Linear (don't enable both)
- **Gmail / Calendar / Figma** — ad-hoc, no command wires them yet

## Auto-installed by `agnostic init`

| Plugin | Marketplace | What |
|---|---|---|
| `gopls-lsp` | claude-plugins-official | Go LSP |
| `claude-mem` | thedotmack | persistent memory across sessions |
| `playwright` | claude-plugins-official | browser MCP |
| `atomic-agents` | claude-plugins-official | small focused agent pattern |
| `frontend-design` | claude-plugins-official | UI design helpers |
| `caveman` | caveman | terse mode |

| MCP | URL | What |
|---|---|---|
| `stitch` | `https://stitch.googleapis.com/mcp` | Google design tool |

Skip with `agnostic init --skip-plugins`.

## External (not auto-installed)

- **gstack** — CLI, separate install: see https://github.com/gstack-cli/gstack

## Command × integration matrix

| Command | gh | Linear | Slack |
|---|:-:|:-:|:-:|
| `/ship` | ✓ | – | optional |
| `/catchup` | ✓ | ✓ | – |
| `/fix-issue <ID>` | ✓ (`#NNN`) | ✓ (`LIN-NNN`) | – |
| `/review` | – | – | – |
| `/bug-hunt` | – | optional | – |
| `/standup` | ✓ | ✓ | ✓ |
| `/triage-inbox` | ✓ | ✓ | – |
| `/notify-team <msg>` | – | – | ✓ |
| `/new-feature <name>` | ✓ | optional | – |
| `/add-endpoint` | – | – | – |
| `/debug-service` | – | – | – |

## Safety: Slack drafts only

Default allowlist: `send_message_draft` ✓ · `send_message` ✗

Agent always drafts + asks user before posting.

## At install

`agnostic init` reports detected integrations:

```
MCP integrations:
  ✓ gh CLI authenticated (you)
  ✓ Linear MCP connected
  ✓ Slack MCP connected
```

Missing ones don't block install. Commands needing them fail loudly when invoked.
