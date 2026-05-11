# CI/CD Conventions

## Pipeline Structure
- **PR checks:** lint + typecheck + unit tests (fast — <10 min target)
- **Merge to main:** integration tests + deploy to staging
- **Tag/release:** deploy to production after manual approval

## Workflow Hygiene
- Cache dependencies (npm, go modules, pip, cargo)
- Matrix only when meaningful (multi-version testing)
- Secrets via CI provider secrets (never in code)
- Branch protection: required status checks before merge

## Naming
- Workflow files: `<service-or-action>.yml` (e.g., `backend-test.yml`, `deploy-prod.yml`)
- Job names: short, lowercase, hyphenated
- Step names: describe the action (e.g., "Run linter", not "Step 3")

## Speed Tactics
- Run independent jobs in parallel
- Skip stages on path filters (no Docker build on doc-only PRs)
- Use `needs:` to express dependencies, not arbitrary ordering
- Move slow checks to nightly or post-merge

## Anti-patterns
- Skipping hooks (`--no-verify`) in CI — fix the hook
- Force-pushing in deploy workflows
- Long-lived feature branches (rebase weekly)
- Tests that pass locally but fail in CI (audit env diffs)
