# Bootstrap Guide

## What `agnostic init` does

1. **Plugins** — enable plugins + MCPs + clone gstack into `~/.claude/` (skip: `--skip-plugins`)
2. **Discover** — read project files (README, Makefile, go.mod/package.json/pyproject.toml, git remote/branch, CLAUDE.md.bak)
3. **Wipe** — destructive remove of prior agent configs (opt-in `--backup` keeps under `.claude.bak.<ts>/`)
4. **Install** — copy framework files into `.claude/`
5. **Generate** — `CLAUDE.md` (root) + `.claude/agnostic.toml` + `.claude/memory/`
6. **Preserve** — `.claude/settings.local.json`, `.githooks/`, `.gemini/`

## Stack detection

| Marker | Stack |
|---|---|
| `go.mod` | go |
| `package.json` (+ `"react"`) | node (+ react) |
| `pyproject.toml` / `setup.py` / `requirements.txt` | python |
| `Cargo.toml` | rust |
| `Gemfile` | ruby |
| `*.tf` | terraform |

Probed in cwd + 1-level subdirs (monorepo). Primary priority: go > node > python > rust > ruby > react > terraform.

## Discovery sources

| Source | Fills |
|---|---|
| `README.md` | description |
| `Makefile` / `package.json` scripts | build commands |
| `go.mod` / etc. | stack with versions |
| `CLAUDE.md.bak.*` | hard rules (preserved across re-install) |
| `git remote get-url origin` | GitHub repo |
| `git branch` (LED-1234 pattern) | Linear team key |
| `~/.claude/settings.json` | expected plugins + marketplaces |

## Manual refinement after init

1. **CLAUDE.md** — fill TODOs. ≤3KB. No `@`-refs.
2. **`.claude/agnostic.toml`** — verify `[verify]` cmds.
3. **`.claude/settings.local.json`** — add project cmds.

## Monorepo

Default: `agnostic init` at repo root. Detection scans subdirs. One CLAUDE.md covers all services.

Per-service init only if services versioned/shipped independently.

## Update

```bash
cd ~/code/agnostic && git pull
cd /project && agnostic update
```

`update` = `init --force`. Regenerates user files too.

## Troubleshoot

| Symptom | Fix |
|---|---|
| Hooks don't run | `chmod +x .claude/hooks/*.sh` |
| Stop hook hangs | Blank `[verify] test` or raise timeout |
| Stack not detected | `agnostic detect`. Universal rules apply anyway |
| Too many tokens | `/context`. Audit `@`-refs + unused MCPs |
