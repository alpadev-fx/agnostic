# Installing Agnostic

## One-Time Setup

Clone the framework somewhere stable:

```bash
git clone https://github.com/<your-org>/agnostic ~/code/agnostic
```

(Replace the URL with your repo once published. For now, the framework lives at `/Users/alpadev/Desktop/agnostic/`.)

Put the CLI on your PATH:

```bash
ln -s ~/code/agnostic/agnostic /usr/local/bin/agnostic
# or, if /usr/local/bin needs sudo:
sudo ln -s ~/code/agnostic/agnostic /usr/local/bin/agnostic
```

Verify:

```bash
agnostic help
```

## Install Into a Project

```bash
cd /path/to/any/project
agnostic init                  # interactive wizard (default)
agnostic init --non-interactive  # CI/scripting: heuristics + TODOs
```

### Interactive wizard

`agnostic init` runs a wizard that asks:

1. **Identity** — project name, description, stack summary
2. **Verification commands** — per-file lint, typecheck, lint, test (defaults suggested per stack)
3. **Integrations** — GitHub repo (auto-detected from `git remote`), Linear team, Slack channels (standup/eng/incidents/releases)
4. **Content** — build commands, hard rules, architecture pointers (one per line, blank to finish)
5. **Post-install** — commit changes to git?

Press Enter at any prompt to accept the default. The wizard runs only when stdin is a TTY; piped/redirected input auto-skips the wizard.

### What happens after wizard:

1. **Detects your stacks** (Go / Node / Python / React / Rust / Ruby / Terraform — monorepo aware)
2. **Backs up any existing `.claude/` directory** to `.claude.bak.<timestamp>`
3. **Backs up existing `CLAUDE.md`** to `CLAUDE.md.bak.<timestamp>` (because it gets replaced with the agent-md style directives)
4. **Overwrites framework-managed files**: hooks, agents, commands, rules, `.claude/settings.json`, **and `CLAUDE.md`** (full agent-md Directives template, adapted to your stack)
5. **Scaffolds `memory/`** with `agents.md`, `plan.md`, `progress.md`, `verify.md`, `gotchas.md` (preserved on re-run unless `--force`)
6. **Preserves your user-managed files**: `agnostic.toml`, `.claude/settings.local.json` (preserved on re-run)

> **Important:** `agnostic init` is destructive to framework files AND `CLAUDE.md`. Backups at `.claude.bak.<timestamp>` and `CLAUDE.md.bak.<timestamp>` are your safety net. If you want to keep an existing `CLAUDE.md` untouched, pass `--no-overwrite`.

## Install Modes

| Command | Behavior |
|---|---|
| `agnostic init` | **Default.** Overwrites framework files + CLAUDE.md (backed up). Preserves agnostic.toml, settings.local.json, memory/*.md. |
| `agnostic init --force` | Overwrites EVERYTHING — including agnostic.toml, settings.local.json, and memory/*.md. Full reset. |
| `agnostic init --no-overwrite` | Idempotent — skips any file that already exists (CLAUDE.md included). Use to add framework alongside existing setup. |
| `agnostic init --no-backup` | Skips `.claude.bak.<timestamp>` and `CLAUDE.md.bak.<timestamp>` backups. |
| `agnostic init --dry-run` | Show what would happen, write nothing. |
| `agnostic update` | Alias for `agnostic init --force`. Wipes everything and regenerates. |
| `agnostic detect` | Print detected stacks, no install. |

## What Gets Installed Where

```
your-project/
├── .claude/
│   ├── hooks/                    ← FRAMEWORK (overwritten by default)
│   │   ├── _lib.sh
│   │   ├── block-destructive.sh
│   │   ├── post-edit-verify.sh
│   │   ├── precompact-summary.sh
│   │   ├── stop-verify.sh
│   │   └── truncation-check.sh
│   ├── agents/                   ← FRAMEWORK (overwritten)
│   │   ├── architect.md          (opus)
│   │   ├── code-reviewer.md      (sonnet)
│   │   ├── db-specialist.md      (sonnet)
│   │   ├── performance-analyst.md (opus)
│   │   ├── security-reviewer.md  (opus)
│   │   └── tdd-guide.md          (sonnet)
│   ├── commands/                 ← FRAMEWORK (overwritten)
│   │   ├── add-endpoint.md
│   │   ├── bug-hunt.md
│   │   ├── catchup.md
│   │   ├── debug-service.md
│   │   ├── fix-issue.md
│   │   ├── new-feature.md
│   │   ├── notify-team.md
│   │   ├── review.md
│   │   ├── ship.md
│   │   ├── standup.md
│   │   └── triage-inbox.md
│   ├── rules/                    ← FRAMEWORK (overwritten)
│   │   ├── universal/
│   │   │   ├── general.md
│   │   │   ├── security.md
│   │   │   └── ci-cd.md
│   │   └── <stack>/              ← stack-specific, auto-selected
│   ├── settings.json             ← FRAMEWORK (overwritten — hook wiring)
│   └── settings.local.json       ← USER (preserved, gitignored)
├── memory/                       ← USER (preserved on re-run)
│   ├── agents.md                 stack + MCPs + specialist agents
│   ├── plan.md                   macro design + vertical slices
│   ├── progress.md               atomic task checklist
│   ├── verify.md                 definition of done + commands
│   └── gotchas.md                corrected mistakes (read before work)
├── CLAUDE.md                     ← FRAMEWORK (overwritten with agent-md Directives — old backed up to CLAUDE.md.bak.<ts>)
└── agnostic.toml                 ← USER (preserved)
```

## After Install — Required Customization

You **must** edit two files before the framework works well:

### 1. `CLAUDE.md` (your project's lean knowledge)

The template has `TODO:` markers. Fill in:

- **One-line description**
- **Stack summary** (pre-filled from detection)
- **Build commands** — actual `make`, `npm`, `go`, `pytest` commands for your project
- **5–10 hard rules** specific to your project. Examples:
  - "Money: integer cents only — never float"
  - "React Router 5.3 — do NOT upgrade"
  - "Python 3.9–3.10 only"
  - "All migrations must include `down.sql`"
- **Architecture pointers** — paths to key aggregation files

Target ≤3KB. **NEVER use `@` references** — they auto-load referenced files and burn tokens on every session.

### 2. `agnostic.toml` (per-project verify commands)

Auto-filled with heuristics for the detected primary stack. Verify and correct:

```toml
[project]
name = "your-project"
summary = "1-line summary injected into context at compaction time"

[verify]
lint_file = "ruff check {file}"     # per-file lint (runs after every Write/Edit)
typecheck = "mypy ."                # project-wide (runs at Stop)
lint      = "ruff check ."          # project-wide
test      = "pytest"                # project-wide
```

Leave fields blank to skip that check.

### 3. `.claude/settings.local.json` (your personal allowlist)

Add commands you commonly need so Claude doesn't prompt every time:

```json
{
  "permissions": {
    "allow": [
      "Bash(make:*)",
      "Bash(npm run:*)",
      "Bash(gh pr:*)"
    ],
    "deny": []
  }
}
```

## Reset / Uninstall

```bash
# Reset framework files but keep your customizations
agnostic init --force

# Full uninstall
rm -rf .claude CLAUDE.md agnostic.toml
```

Backups created during install live at `.claude.bak.<timestamp>` — restore one with:

```bash
rm -rf .claude
mv .claude.bak.<timestamp> .claude
```

## Verifying the Install

In your project directory, open Claude Code. Try:

```
/catchup       # quick state briefing — proves commands are found
/review        # multi-agent diff review — proves agents work
```

Run `/context` to see token baseline. Target: **<8K tokens always-loaded**.

If higher, see [docs/token-budget.md](docs/token-budget.md) for diagnosis.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Hooks don't run | Not executable | `chmod +x .claude/hooks/*.sh` |
| Stop hook hangs | Tests slow | Increase timeout in `.claude/settings.json` or blank `[verify] test` in `agnostic.toml` |
| Stack not detected | No marker files at root | `agnostic detect` to see what's found; manually copy from `rules/<closest-match>/` |
| `agnostic: command not found` | Symlink missing | `ln -s ~/code/agnostic/agnostic /usr/local/bin/agnostic` |
| `jq: command not found` | Missing dep | `brew install jq` (macOS) or `apt install jq` (Debian) |

## Requirements

### Core (required)
- `bash` 4+
- `jq` (for hook JSON output)
- `sed`, `awk`, `grep` (standard POSIX)
- `git`
- `gh` CLI — required for `/ship`, `/catchup`, `/fix-issue`, `/new-feature`, `/standup`, `/triage-inbox`
  ```bash
  brew install gh && gh auth login
  ```

### MCP Integrations (recommended)
- **Linear MCP** — used by `/fix-issue`, `/catchup`, `/standup`, `/triage-inbox`
- **Slack MCP** — used by `/standup`, `/notify-team`
- (Optional) **Atlassian MCP** — substitute for Linear if your team uses Jira

Setup MCPs at https://claude.ai/settings/connectors. Verify:
```bash
claude mcp list | grep -E "Linear|Slack"
```

`agnostic init` reports detected integrations and warns about missing ones — install proceeds either way; commands needing missing integrations fail loudly when invoked.

See [docs/integrations.md](docs/integrations.md) for full integration matrix.

## Updating the Framework

When the framework repo gets new agents, hooks, commands, or rules:

```bash
cd ~/code/agnostic && git pull
cd /path/to/your/project
agnostic update          # alias for `agnostic init --force`
```

This regenerates framework files. Your CLAUDE.md, agnostic.toml, and settings.local.json are preserved.
