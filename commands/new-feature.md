---
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
argument-hint: [feature name + 1-line description]
description: Scaffold a new feature with tests, following project patterns
model: claude-opus-4-7
---
Add new feature: $ARGUMENTS

1. **Understand placement:**
   - Read CLAUDE.md and `.claude/rules/` for stack architecture
   - Identify where new feature lives (vertical slice / module / package)
   - Find a similar existing feature as reference

2. **Branch:** `git checkout -b feature/<short-name>`

3. **Design (don't code yet):**
   - Spawn `architect` agent for layering recommendation
   - Confirm with user before coding if non-trivial (>3 files affected)

4. **Implement (TDD):**
   - Tests first
   - Minimum impl
   - Repeat per layer (data → business logic → transport)

5. **Verify:**
   - All tests pass
   - Lint clean
   - Type check clean

6. **Document:**
   - Update README/docs if user-facing
   - Inline comments only for non-obvious WHY

7. **Review + Ship:**
   - Run `/review` against this branch
   - Address Critical/Important findings
   - Invoke `/ship` to push + open PR

Anti-patterns to refuse:
- Designing for hypothetical future requirements
- Premature abstraction
- Adding features beyond user's request
