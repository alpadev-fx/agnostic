---
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
argument-hint: [issue ID or URL — e.g. GH-123, LINEAR-456, or full URL]
description: Implement a fix for a tracked issue end-to-end
model: claude-opus-4-7
---
Fix issue: $ARGUMENTS

1. **Fetch issue details:**
   - GitHub: `gh issue view $ARGUMENTS`
   - Linear: use Linear MCP `get_issue`
   - Otherwise: ask user for issue body

2. **Plan:**
   - Read relevant code (use Explore agent if scope unclear)
   - Identify root cause (NOT symptom — the symptom is what to test against)
   - Choose minimal change that fixes the root cause

3. **Branch:** `git checkout -b fix/<issue-id>-short-description`

4. **Implement:**
   - Write the failing test FIRST (TDD)
   - Make it pass with minimal code
   - Lint after each change

5. **Verify:**
   - Test passes
   - Other tests still pass
   - Lint clean

6. **Commit + Ship:**
   - Commit references issue (`fix: short summary (#123)`)
   - Invoke `/ship` to push + open PR

Refuse to fix if:
- Issue description is too vague — ask user for repro steps first
- Fix scope expands beyond the issue — propose splitting into multiple issues
