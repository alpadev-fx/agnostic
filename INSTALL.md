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
```

Verify: `agnostic help`

## 3. MCPs (1× per Claude account)

Connect at https://claude.ai/settings/connectors → enable **Linear** + **Slack**.

Verify: `claude mcp list | grep -E "Linear|Slack"`

## 4. Per project

```bash
cd /path/to/your/project
agnostic init
```

That's it. Discovers project files (README, Makefile, go.mod, etc.), writes everything.

## What ends up in the project

```
your-project/
├── CLAUDE.md          ← always-loaded agent directives (at root — required by Claude Code)
└── .claude/
    ├── agnostic.toml         project config (verify cmds, integrations)
    ├── settings.json         hook wiring (framework-managed)
    ├── settings.local.json   your permission allowlist (gitignored)
    ├── memory/               project state (agents/plan/progress/verify/gotchas)
    ├── agents/               6 specialists (architect, security, perf, ...)
    ├── commands/             11 slash workflows (/review, /ship, /catchup, ...)
    ├── hooks/                6 lifecycle scripts
    └── rules/                lazy-loaded knowledge packs
```

## Flags

| Flag | Effect |
|---|---|
| (none) | Wipe previous config, install fresh, preserve user files |
| `--force` | Also overwrite agnostic.toml, settings.local.json, memory/ |
| `--no-overwrite` | Skip files that already exist (idempotent) |
| `--backup` | Move wiped config to `.claude.bak.<timestamp>/` instead of deleting |
| `--dry-run` | Show what would happen, write nothing |

## Update framework

```bash
cd ~/code/agnostic && git pull
cd /path/to/project && agnostic update
```

## Uninstall

```bash
rm -rf .claude CLAUDE.md
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `agnostic: command not found` | Re-run step 2 (PATH setup) |
| `jq: command not found` | `brew install jq` (macOS) / `apt install jq` (Debian) |
| Hooks don't run | `chmod +x .claude/hooks/*.sh` |
| Stop hook hangs | Blank `[verify] test` in `.claude/agnostic.toml` |
| Stack not detected | `agnostic detect` to verify; framework still works with universal rules |
