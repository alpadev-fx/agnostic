# Install

## 1. Pre-reqs (1× per machine)

```bash
brew install jq gh && gh auth login
```

## 2. Framework (1× per machine)

```bash
git clone https://github.com/alpadev-fx/agnostic.git ~/code/agnostic
mkdir -p ~/bin && ln -s ~/code/agnostic/agnostic ~/bin/agnostic
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
agnostic help
```

## 3. MCPs (1× per Claude account)

Connect at https://claude.ai/settings/connectors → Linear + Slack.

```bash
claude mcp list | grep -E "Linear|Slack"   # verify
```

## 4. Per project

```bash
cd /path/to/your/project
agnostic init
```

Done. Discovers from project files, wipes old config, installs framework, enables plugins.

## Flags

| Flag | Effect |
|---|---|
| (none) | Wipe + install + enable plugins |
| `--force` | Also overwrite agnostic.toml / settings.local.json / memory/ |
| `--no-overwrite` | Skip files that already exist |
| `--backup` | Move wiped config to `.claude.bak.<timestamp>/` |
| `--skip-plugins` | Don't touch `~/.claude/settings.json` plugins |
| `--dry-run` | Show what would happen |

## What `init` writes

```
project/
├── CLAUDE.md          ← agent directives (root, required by Claude Code)
└── .claude/
    ├── agnostic.toml
    ├── settings.json
    ├── settings.local.json
    ├── memory/
    ├── agents/        6 specialists
    ├── commands/      11 workflows
    ├── hooks/         6 scripts
    └── rules/         universal + per-stack
```

## What `init` wipes (destructive — use `--backup` to keep)

`.claude/` · `CLAUDE.md` · `agent-md.toml` · `AGENTS.md` · `AGENT.md` · `.codex/` · `.cursor/rules/agent-md.mdc` · `.windsurf/rules/agent-md.md` · `.agent-md/` · `.agents/` · old `.claude.bak.*/`

## Preserved (never touched)

`.claude/settings.local.json` (your permissions) · `.githooks/` · `.gemini/`

## After install — refine 3 files

1. **CLAUDE.md** — fill remaining TODOs (hard rules, etc.). Target ≤3KB. NEVER use `@`-refs.
2. **.claude/agnostic.toml** — verify `[verify]` commands work for your project.
3. **.claude/settings.local.json** — add project commands to allowlist (`Bash(make:*)`, etc.).

## Update framework

```bash
cd ~/code/agnostic && git pull
cd /path/to/project && agnostic update
```

`update` = `init --force`. Regenerates everything (incl. user files).

## Uninstall

```bash
rm -rf .claude CLAUDE.md
```

## Troubleshoot

| Symptom | Fix |
|---|---|
| `agnostic: command not found` | Re-run step 2 PATH setup |
| `jq: command not found` | `brew install jq` |
| Hooks don't run | `chmod +x .claude/hooks/*.sh` |
| Stop hook hangs | Blank `[verify] test` in `.claude/agnostic.toml` |
| Stack not detected | `agnostic detect` — install still works with universal rules |
| Too many tokens at boot | `/context` in Claude Code. Audit `@`-refs + unused MCPs |
