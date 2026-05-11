---
allowed-tools: Bash, Read
argument-hint: [optional: team filter]
description: Triage Linear + GitHub inbox — open issues, PR reviews requested
model: claude-sonnet-4-6
---
Triage my inbox for: $ARGUMENTS (default: all assigned).

## Gather (PARALLEL)

```bash
# GitHub: PRs requesting my review
gh pr list --search "is:open review-requested:@me"

# GitHub: issues assigned to me
gh issue list --assignee "@me" --state open

# GitHub: PRs I authored awaiting review
gh pr list --author "@me" --state open --search "review:none"
```

Plus Linear MCP:
- `mcp__claude_ai_Linear__list_issues` — assigned to me, sorted by priority desc + updated desc
- `mcp__claude_ai_Linear__list_issues` — mentioned in comments (notification queue)

## Categorize

Group items by action required:

```
## Inbox Triage

### NEEDS YOUR REVIEW (N)
- PR #123 — title — author — opened 2d ago — URL

### NEEDS YOUR DECISION (N)
- LIN-456 — title — priority — comment from X waiting

### WAITING ON OTHERS (N)
- PR #789 — title — review requested 3d ago — reviewer: @user

### STALE / RE-ENGAGE (N)
- LIN-321 — title — InProgress, no activity 5d
- PR #654 — title — opened 8d ago, no review

### LOW PRIORITY (N)
- <items with priority=Low or no recent activity>
```

For each item: short hint at next action ("respond to X's question", "rebase needed", "ping reviewer", "decide scope expansion").

## Modes
- Default: print summary only
- `--quick`: skip stale + low priority, show top 3 per category
- `--with-actions`: propose specific next action per item (no execution)

## Output
End with: `Recommended priority: address [N] decisions first, then review [M] PRs.`

Do NOT close, comment, or transition issues. Read only.
