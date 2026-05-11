# Bootstrap Guide

## What `agnostic init` does

1. **Discover** answers from project files (README, Makefile, go.mod/package.json/pyproject.toml, CLAUDE.md.bak, git remote/branch, `~/.claude/settings.json` plugins).
2. **Wipe** prior agent configs (`.claude/`, `CLAUDE.md`, `agent-md.toml`, `AGENTS.md`, `AGENT.md`, `.codex/`, `.cursor/rules/agent-md.mdc`, `.windsurf/rules/agent-md.md`).
3. **Install** framework files into `.claude/`.
4. **Generate** `CLAUDE.md` (root) + `.claude/agnostic.toml` + `.claude/memory/`.
5. **Preserve** `.claude/settings.local.json` (your permissions), `.githooks/`, `.gemini/`.

Use `--backup` to keep old config under `.claude.bak.<timestamp>/`.

## Stack detection

Marker files probed (cwd + subdirs):
- `go.mod` → Go
- `package.json` → Node (+ React if `"react"` in deps)
- `pyproject.toml` / `setup.py` / `requirements.txt` → Python
- `Cargo.toml` → Rust
- `Gemfile` → Ruby
- `*.tf` → Terraform

Primary stack priority: go > node > python > rust > ruby > react > terraform.

## After install — refine these 3 files

1. **CLAUDE.md** (root) — fill any remaining TODOs (description / build cmds / hard rules / arch pointers). Target ≤3KB. NEVER use `@`-references.
2. **.claude/agnostic.toml** — verify `[verify]` commands work for your project. Blank fields fall back to heuristics.
3. **.claude/settings.local.json** — add frequently-used commands to allowlist (e.g. `Bash(make:*)`).

## Monorepo

Default: run `agnostic init` at repo root. Detection scans subdirs. One CLAUDE.md covers all services.

Per-service init only if services are independently versioned/shipped.

## Update

```bash
cd ~/code/agnostic && git pull
cd /path/to/project && agnostic update
```

`update` = `init --force`. Overwrites framework files. Preserves `.claude/agnostic.toml`, `.claude/settings.local.json`, `.claude/memory/`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Hooks don't run | `chmod +x .claude/hooks/*.sh` |
| Stop hook hangs | Blank `[verify] test` in `.claude/agnostic.toml` or raise hook timeout in `.claude/settings.json` |
| Stack not detected | `agnostic detect` — install still works with universal rules |
| Too many tokens | Run `/context` in Claude Code. Audit `@`-refs in CLAUDE.md + unused MCPs |
