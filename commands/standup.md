---
allowed-tools: Bash, Read
argument-hint: [optional: yesterday|week — defaults to yesterday]
description: Daily standup digest — Linear + GitHub + Slack activity
model: claude-sonnet-4-6
---
Generate daily standup digest for: $ARGUMENTS (default: yesterday).

## Gather (PARALLEL)

Run these in parallel:

```bash
# GitHub activity
gh pr list --author "@me" --state open
gh pr list --author "@me" --state merged --search "merged:>=$(date -v-1d +%Y-%m-%d)" 2>/dev/null || gh pr list --author "@me" --state merged --search "merged:>=$(date -d 'yesterday' +%Y-%m-%d)"
gh issue list --assignee "@me" --state open
```

Plus Linear MCP (parallel):
- `mcp__claude_ai_Linear__list_issues` — assigned to me, state in {InProgress, InReview}
- `mcp__claude_ai_Linear__list_comments` — recent comments on my issues

Plus (optional) Slack MCP:
- `mcp__claude_ai_Slack__search_public` — keyword query matching open PR titles to find related threads

## Synthesize

Format as 3 sections (Yesterday / Today / Blockers):

```
## Standup — <DATE>

### Yesterday
- Shipped: <PR titles + URLs>
- Closed: <issues>
- Notable progress: <key commits or comments>

### Today
- Continuing: <open PRs>
- Picking up: <Linear issues moving to InProgress>

### Blockers
- <PRs waiting on review for >24h>
- <Linear issues in "Blocked" state>
- <Open questions from Slack threads>
```

## Output Modes

If `$ARGUMENTS` ends with `--post`: open a Slack draft with the digest via `mcp__claude_ai_Slack__send_message_draft`. Default channel: `#standup` (configurable in `agnostic.toml [integrations] standup_channel`). NEVER send directly without user confirming the draft.

Otherwise: print to terminal only.

## Edge Cases
- No GitHub activity → say so, don't pad
- No Linear access → skip Linear section, note "Linear MCP not connected"
- Multiple repos → group by repo
