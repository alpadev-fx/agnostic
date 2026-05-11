# Bootstrap Guide

## What `agnostic init` does

1. **Plugins** — enable recommended plugins + MCPs in `~/.claude/settings.json` (skip with `--skip-plugins`)
2. **Discover** — read project files (README, Makefile, go.mod/package.json/pyproject.toml, git remote/branch, prior CLAUDE.md.bak)
3. **Wipe** — destructive remove of prior agent configs (`.claude/`, `CLAUDE.md`, `agent-md.toml`, `AGENTS.md`, `.codex/`, etc.). Opt-in `--backup` keeps under `.claude.bak.<ts>/`
4. **Install** — copy framework files into `.claude/`
5. **Generate** — `CLAUDE.md` (root) + `.claude/agnostic.toml` + `.claude/memory/` with discovered values
6. **Preserve** — `.claude/settings.local.json`, `.githooks/`, `.gemini/`

## Stack detection

Marker files probed in cwd + 1-level subdirs:

| File | Stack |
|---|---|
| `go.mod` | go |
| `package.json` (+ `"react"`) | node (+ react) |
| `pyproject.toml` / `setup.py` / `requirements.txt` | python |
| `Cargo.toml` | rust |
| `Gemfile` | ruby |
| `*.tf` | terraform |

Primary priority: go > node > python > rust > ruby > react > terraform.

## Auto-discovery sources

| Source | Fills |
|---|---|
| `README.md` | description |
| `Makefile` / `package.json` scripts | build commands |
| `go.mod` / etc. | stack summary with versions |
| `CLAUDE.md.bak.*` | hard rules (preserved across re-install) |
| `git remote get-url origin` | GitHub repo |
| `git branch` (LED-1234 pattern) | Linear team key |
| `~/.claude/settings.json` | expected plugins + marketplaces |

## Manual refinement after init

1. **CLAUDE.md** (root) — fill TODOs. ≤3KB. NEVER `@`-refs.
2. **.claude/agnostic.toml** — verify `[verify]` cmds work.
3. **.claude/settings.local.json** — add frequently-used cmds.

## Monorepo

Default: `agnostic init` at repo root. Detection scans subdirs. One CLAUDE.md covers all services.

Per-service init only if services versioned/shipped independently.

## Update

```bash
cd ~/code/agnostic && git pull
cd /path/to/project && agnostic update
```

`update` = `init --force`. Regenerates everything (incl. user files).

## Troubleshoot

| Symptom | Fix |
|---|---|
| Hooks don't run | `chmod +x .claude/hooks/*.sh` |
| Stop hook hangs | Blank `[verify] test` or raise timeout in `.claude/settings.json` |
| Stack not detected | `agnostic detect` — install still works with universal rules |
| Too many tokens | `/context`. Audit `@`-refs + unused MCPs |
