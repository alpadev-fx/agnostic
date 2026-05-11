# MCP Integrations

agnostic assumes 3 integrations are available. Commands leverage them when present; degrade gracefully when absent.

## Required

### GitHub CLI (`gh`)
Used by: `/ship`, `/catchup`, `/fix-issue`, `/bug-hunt`

Install:
```bash
brew install gh
gh auth login
```

Verify:
```bash
gh auth status
gh pr list --limit 1
```

## Recommended

### Linear MCP
Used by: `/fix-issue`, `/catchup`, `/triage-inbox`, `/standup`

Tools exposed (via `mcp__claude_ai_Linear__*`):
- `get_issue` — fetch issue by ID
- `list_issues` — query by team/status/assignee
- `save_issue` — create or update issue
- `save_comment` — comment on issue
- `list_comments`, `list_documents`, `list_projects`, `list_teams`, `list_users`, `list_cycles`

Setup:
1. Open Claude (claude.ai or Claude Code)
2. Visit https://claude.ai/settings/connectors
3. Connect Linear → authorize
4. Verify in Claude Code: `claude mcp list | grep Linear`

### Slack MCP
Used by: `/standup`, `/notify-team`, `/triage-inbox`

Tools (via `mcp__claude_ai_Slack__*` or `slack_*`):
- `send_message` — post to channel
- `send_message_draft` — open draft for review
- `read_channel`, `read_thread`, `read_user_profile`
- `search_channels`, `search_public`, `search_public_and_private`
- `schedule_message`, `create_canvas`, `update_canvas`

Setup:
1. https://claude.ai/settings/connectors
2. Connect Slack → authorize workspace
3. Verify: `claude mcp list | grep Slack`

## Optional

### Atlassian (Jira/Confluence) MCP
Replaces Linear if your team uses Atlassian. Don't enable both — pick one canonical tracker.

### Gmail MCP
Used by ad-hoc tasks. Not wired into any command by default.

### Calendar MCP
Used by ad-hoc tasks. Not wired into any command by default.

### Figma MCP
For frontend work — fetches designs. Use in conjunction with `frontend-design` skill if installed.

## Command Behavior by Integration

| Command | gh required | Linear used | Slack used |
|---|---|---|---|
| `/ship` | ✓ | ✗ | optional (announce PR) |
| `/catchup` | ✓ | ✓ (if assigned issues) | ✗ |
| `/fix-issue <ID>` | ✓ (for `#NNN`) | ✓ (for `LIN-NNN`) | ✗ |
| `/review` | ✗ | ✗ | ✗ |
| `/bug-hunt` | ✗ | optional (link findings) | ✗ |
| `/standup` | ✓ | ✓ | ✓ (post summary) |
| `/triage-inbox` | ✓ | ✓ | optional |
| `/notify-team <msg>` | ✗ | ✗ | ✓ |
| `/add-endpoint` | ✗ | ✗ | ✗ |
| `/debug-service` | ✗ | ✗ | ✗ |
| `/new-feature` | ✓ (for branch) | optional | ✗ |

## Permissions

Default `.claude/settings.local.json` has minimal MCP allowlist. Add commonly-used tools to skip prompts:

```json
{
  "permissions": {
    "allow": [
      "Bash(gh issue:*)",
      "Bash(gh pr:*)",
      "Bash(gh run:*)",
      "Bash(gh api:*)",
      "mcp__claude_ai_Linear__get_issue",
      "mcp__claude_ai_Linear__list_issues",
      "mcp__claude_ai_Linear__list_teams",
      "mcp__claude_ai_Slack__send_message_draft",
      "mcp__claude_ai_Slack__read_channel",
      "mcp__claude_ai_Slack__search_public"
    ]
  }
}
```

Note: `send_message` (direct send) intentionally NOT allowlisted — agent should always draft + ask user before posting to Slack. `send_message_draft` is safe to allowlist.

## Detection at Install

`agnostic init` reports which integrations are available:

```
$ agnostic init
agnostic install
  ...
MCP integrations detected:
  ✓ gh CLI authenticated (org: acme)
  ✓ Linear MCP connected
  ✓ Slack MCP connected
  ✗ Atlassian MCP not connected — skipping Jira commands
  ...
```

Missing integrations don't block install — commands that need them will fail loudly when invoked, not silently.
