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

https://claude.ai/settings/connectors → Linear + Slack.

## 4. Per project

```bash
cd /path/to/project
agnostic init
```

Done.

## Flags

| Flag | Effect |
|---|---|
| (none) | Wipe + install + enable plugins |
| `--force` | Also overwrite agnostic.toml / settings.local.json / memory/ |
| `--no-overwrite` | Skip existing files |
| `--backup` | Move wiped config to `.claude.bak.<timestamp>/` |
| `--skip-plugins` | Don't touch `~/.claude/settings.json` |
| `--dry-run` | Show what would happen |

## Wiped

`.claude/` · `CLAUDE.md` · `agent-md.toml` · `AGENTS.md` · `AGENT.md` · `.codex/` · `.cursor/rules/agent-md.mdc` · `.windsurf/rules/agent-md.md` · `.agent-md/` · `.agents/` · old `.claude.bak.*/`

## Preserved

`.claude/settings.local.json` · `.githooks/` · `.gemini/`

## After install

1. **CLAUDE.md** — fill TODOs. ≤3KB. No `@`-refs.
2. **`.claude/agnostic.toml`** — verify `[verify]` cmds.
3. **`.claude/settings.local.json`** — add project cmds to allowlist.

## Update

```bash
cd ~/code/agnostic && git pull
cd /project && agnostic update
```

`update` = `init --force`. Regenerates everything.

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
| Stack not detected | `agnostic detect`. Works with universal rules anyway |
| Too many tokens | `/context`. Audit `@`-refs + unused MCPs |
