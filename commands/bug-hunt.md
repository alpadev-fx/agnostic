---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [optional: scope — directory or component name]
description: Multi-agent bug hunt across the codebase. No fixes — report only.
model: claude-opus-4-7
---
Bug hunt in $ARGUMENTS (default: full repo).

## Philosophy
> "One reviewer finds surface bugs. A coordinated team with distinct roles finds the bugs that kill in production."

## Execute

**Launch all 4 specialist agents in PARALLEL** (single message, multiple tool calls):

1. **security-reviewer** — auth bypass, IDOR, injection, secrets exposure, missing validation
2. **performance-analyst** — N+1 queries, hot path Big-O, memory leaks, missing caches
3. **code-reviewer** — logic errors, error handling, edge cases, dead code
4. **db-specialist** — schema integrity, missing indexes, migration safety, query patterns

Each agent reports findings in their own format.

## Consolidate

After all agents return, deduplicate findings (same file:line, same root cause).

Group output:
```
## Bug Hunt — Findings

### Critical (N)
1. path:line — class — short description

### High (N)
...

### Medium (N)
...

### Notes / Low (N)
...
```

For each finding include:
- Severity
- Class (Security/Perf/Logic/Schema)
- File path with line number
- Reproduction or attack scenario
- Recommended fix (pointer, not implementation)

## Output ends with

`Total findings: N. Suggested priority: fix [N] Criticals first.`

Do NOT modify code. Report only.
