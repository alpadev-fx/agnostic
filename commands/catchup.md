---
allowed-tools: Bash, Read
argument-hint: [optional: branch — defaults to current]
description: Bring me up to speed on recent activity in this branch
model: claude-sonnet-4-6
---
Catch me up on $ARGUMENTS (default: current branch).

Run these in PARALLEL:

```bash
git status
git log --oneline -20
git diff main...HEAD --stat 2>/dev/null || git diff master...HEAD --stat
gh pr list --author "@me" --state open 2>/dev/null | head -5
gh pr view 2>/dev/null
```

Then synthesize:

1. **Branch state:** clean / dirty (list uncommitted files)
2. **Commits since base:** count + last 5 with one-line summary
3. **PR state (if exists):** open/draft/merged, CI status, reviewer status
4. **Last activity:** what file was edited last, when
5. **Outstanding:** TODO comments added in this branch (`git diff main...HEAD | grep -E '^\+.*TODO'`)

Output as a short briefing — 8 lines max. Designed for "I just sat down, what was I doing?"
