---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [optional: base branch, defaults to main]
description: Multi-axis code review on the current branch diff
model: claude-opus-4-7
---
Review the diff between current branch and `$ARGUMENTS` (default: `main`).

Steps:

1. **Get diff scope:**
   ```bash
   BASE="${1:-main}"
   git fetch origin "$BASE" 2>/dev/null
   git diff "$BASE"...HEAD --stat
   git diff "$BASE"...HEAD
   ```

2. **Launch 3 review agents in PARALLEL** (single message, multiple tool calls):
   - `code-reviewer` — quality, architecture, testing
   - `security-reviewer` — auth, input validation, secrets, OWASP
   - `performance-analyst` — N+1, hot paths, Big-O regressions

3. **Consolidate findings:** group by severity (Critical / Important / Suggestion). Dedupe overlap between agents (same line, same issue → single entry).

4. **Output:**
   ```
   ## Review Summary
   - Files changed: N
   - Critical: N
   - Important: N
   - Suggestions: N

   ## Critical
   1. path/to/file.ext:LINE — short — fix

   ## Important
   ...

   ## Suggestions
   ...
   ```

5. **Verdict:** `READY` / `BLOCKED` (one or more Critical) / `READY WITH NOTES` (only Important).

Do NOT make code changes — review only.
