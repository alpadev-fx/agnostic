# MCP Integrations

## Required

**GitHub CLI** (`gh`) — used by `/ship`, `/catchup`, `/fix-issue`, `/new-feature`, `/standup`, `/triage-inbox`.

```bash
brew install gh && gh auth login
```

## Recommended

**Linear MCP** — `/fix-issue`, `/catchup`, `/standup`, `/triage-inbox`
**Slack MCP** — `/standup`, `/notify-team`

Connect at https://claude.ai/settings/connectors. Verify:
```bash
claude mcp list | grep -E "Linear|Slack"
```

## Optional

- **Atlassian MCP** — substitute for Linear if you use Jira (don't enable both)
- **Gmail / Calendar / Figma MCPs** — ad-hoc, not wired into any command

## Command × Integration matrix

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

Default permission allowlist includes `send_message_draft` but NOT `send_message`. Agent must draft + ask user before posting.

## Detection at install

`agnostic init` reports detected integrations:

```
MCP integrations:
  ✓ gh CLI authenticated (alpadev-fx)
  ✓ Linear MCP connected
  ✓ Slack MCP connected
```

Missing ones don't block install. Commands needing them fail loudly when invoked.
