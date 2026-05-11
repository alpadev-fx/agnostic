# Bootstrap Guide

How `agnostic init` works under the hood, and what to do after.

## What `init` Does

1. **Detect stacks** — scans target directory for marker files:
   - `go.mod` → Go
   - `package.json` → Node (+ React if `"react"` in deps)
   - `pyproject.toml` / `setup.py` / `requirements.txt` → Python
   - `Cargo.toml` → Rust
   - `Gemfile` → Ruby
   - `*.tf` / `terraform/` / `infrastructure/terraform/` → Terraform
2. **Identify primary stack** — first match in priority order: go > node > python > rust > ruby > react > terraform
3. **Copy framework files** to `.claude/`:
   - Hooks (universal, every project gets them)
   - Agents (6 archetypes)
   - Commands (8 workflows)
   - Rules: universal + per-detected-stack
4. **Generate config files** from templates:
   - `CLAUDE.md` (scaffold — fill in TODOs)
   - `agnostic.toml` (filled with stack-appropriate defaults)
   - `.claude/settings.json` (hook wiring)
   - `.claude/settings.local.json` (basic permission allowlist)

Files that already exist are skipped (use `--force` to overwrite).

## Manual Steps After Init

### 1. Edit `CLAUDE.md`

The template has `TODO:` markers. Fill in:
- **Description** — one sentence
- **Stack summary** — pre-filled from primary detection; refine if monorepo
- **Build commands** — actual commands for your project
- **Hard rules** — 5-10 invariants specific to your project (e.g., "Money: integer cents", "Python 3.9-3.10 only", "React Router 5.3 — do NOT upgrade")
- **Architecture pointers** — key aggregation files (where handlers register, where DI wires)

Target ≤3KB. If you find yourself writing more, push detail into `.claude/rules/`.

### 2. Edit `agnostic.toml`

Auto-filled with heuristics. Verify:
- `[verify] lint_file` runs your linter on a single file
- `[verify] typecheck` runs your type checker project-wide
- `[verify] lint` runs your linter project-wide
- `[verify] test` runs your test suite

Empty values fall back to heuristics. Set explicitly when heuristics are wrong (custom Makefile targets, monorepo workspaces, etc.).

The `[project] summary` is injected into context before compaction. Keep it short.

### 3. Edit `.claude/settings.local.json`

The template has a minimal git/find/grep allowlist. Add commands you'll commonly need:
- Build commands (`make build`, `npm run build`)
- Migration commands
- Project-specific scripts

Don't add anything destructive (`rm`, `DROP`, force push). The hooks block those at runtime; the permission allowlist is for friction reduction on safe commands.

### 4. (Optional) Add stack-specific agents

If your project needs a specialist not in the default 6, add `.claude/agents/<name>.md` with the standard frontmatter. Examples:
- `frontend-specialist.md` (deep React/Vue knowledge)
- `ai-engineer.md` (ML pipelines, prompts, embeddings)
- `mobile-developer.md` (iOS/Android specific)

### 5. (Optional) Add project-specific commands

If you have a workflow that's specific to your team, add `.claude/commands/<name>.md`. The framework's 8 are starting points — customize freely.

## Updating

To refresh framework files (e.g., after a `agnostic` upgrade):

```bash
agnostic update [TARGET_DIR]
```

This overwrites the framework-managed files (`hooks/`, `agents/`, `commands/`, `rules/`). It does NOT touch `CLAUDE.md`, `agnostic.toml`, or `settings.local.json` — your customizations are safe.

If you've customized hooks or agents, back them up first:

```bash
cp -r .claude/hooks .claude/hooks.bak
agnostic update
diff -r .claude/hooks.bak .claude/hooks
```

## Monorepo Pattern

For monorepos with distinct services in subdirectories (e.g., `back/`, `front/`, `ai/`):

Option A — **single config at root** (recommended for tight coupling):
- Run `agnostic init` at root
- Detect script picks up all stacks
- `CLAUDE.md` covers all services
- Build commands route to subdirectories

Option B — **per-service init**:
- Run `agnostic init` in each subdirectory
- Each gets its own `CLAUDE.md` and `agnostic.toml`
- Run Claude Code in the relevant subdirectory
- Caveat: cross-service references need explicit paths

Pick Option A unless services are versioned/shipped independently.

## Troubleshooting

### Hooks aren't running
Verify shell access:
```bash
bash .claude/hooks/block-destructive.sh < /dev/null
echo $?  # should print 0
```
If 126 (permission denied): `chmod +x .claude/hooks/*.sh`

### Stop hook blocks forever
Check `.claude/hooks/stop-verify.sh` outputs. If your test suite is slow, increase the hook timeout in `settings.json` from 300 to 600+. Or set `agnostic.toml [verify] test = ""` to skip test enforcement.

### Stack not detected
Run `agnostic detect` to see what's found. If your stack isn't in the detection set, you can still install (universal rules apply) and manually copy from `rules/<closest-match>/` as a starting point.

### Too many tokens at session boot
Run `/context` in Claude Code to see baseline. If >10K:
- Audit `CLAUDE.md` for `@`-references (delete them)
- Audit `MCP` integrations (`claude mcp list`) for unused ones
- Check Claude Desktop extensions (Settings → Extensions)
