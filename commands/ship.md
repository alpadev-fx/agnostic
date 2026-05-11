---
allowed-tools: Bash, Read, Edit
argument-hint: [optional: PR title — auto-generated if omitted]
description: Ship workflow — run tests, lint, commit, push, create PR
model: claude-sonnet-4-6
---
Ship the current branch: $ARGUMENTS

1. **Pre-flight checks (parallel):**
   ```bash
   git status
   git diff --stat
   git log --oneline -10
   ```

2. **Verify uncommitted state:**
   - If working tree dirty: stage relevant files (NOT `git add .` — name each file)
   - Skip files matching: `.env*`, `*.key`, `*.pem`, anything looking like a secret

3. **Run project verification** (agnostic.toml [verify] commands or heuristics):
   - typecheck
   - lint
   - test

4. **If any check fails:** STOP. Fix or ask user before continuing.

5. **Commit:** conventional commits format (`feat:`, `fix:`, `chore:`, etc.). Subject ≤50 chars, body explains WHY not WHAT.

6. **Push:** `git push -u origin <branch>` (set upstream if missing). NEVER force push.

7. **Open PR with `gh pr create`:**
   - Title: from $ARGUMENTS or generated from commits
   - Body: Summary (1-3 bullets) + Test plan (markdown checklist)
   - Use HEREDOC for body formatting

8. **Output:** PR URL.

Refuse to ship if:
- Tests failing
- Lint failing
- Branch is `main`/`master`/`dev`/`prod` (direct work on protected branches)
- User hasn't asked to push to production
