#!/bin/bash
# install.sh — install agnostic into a project.
#
# Usage:
#   /path/to/agnostic/bootstrap/install.sh [TARGET_DIR] [flags]
#
# Default behavior:
#   - OVERWRITES framework-managed files (hooks, agents, commands, rules, settings.json)
#     because these are versioned with the framework
#   - PRESERVES user-managed files (CLAUDE.md, agnostic.toml, settings.local.json)
#   - BACKS UP existing .claude/ to .claude.bak.<timestamp> on first install
#
# Flags:
#   --force         Also overwrite user-managed files (agnostic.toml, settings.local.json)
#   --no-overwrite  Skip framework files that already exist (idempotent)
#   --backup        Move previous config to .claude.bak.<timestamp>/ instead of deleting
#   --dry-run       Show what would happen, don't write

set -e

FW_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR=""
FORCE=0
NO_OVERWRITE=0
BACKUP=0
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --force)        FORCE=1 ;;
    --no-overwrite) NO_OVERWRITE=1 ;;
    --backup)       BACKUP=1 ;;
    --no-backup)    BACKUP=0 ;;  # legacy alias (default is no-backup now)
    --dry-run)      DRY_RUN=1 ;;
    --*)            echo "Unknown flag: $arg" >&2; exit 1 ;;
    *)              [ -z "$TARGET_DIR" ] && TARGET_DIR="$arg" ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-$PWD}"

cd "$TARGET_DIR"
ABS_TARGET="$(pwd)"

echo "agnostic install"
echo "  Framework: $FW_ROOT"
echo "  Target:    $ABS_TARGET"
[ "$DRY_RUN" = "1" ] && echo "  Mode:      DRY RUN (no files written)"
[ "$FORCE" = "1" ] && echo "  Mode:      FORCE (also overwrite CLAUDE.md, agnostic.toml, settings.local.json)"
[ "$NO_OVERWRITE" = "1" ] && echo "  Mode:      NO-OVERWRITE (skip existing framework files)"
echo

# --- WIPE existing agent configs (DESTRUCTIVE by default, opt-in --backup) ---
# Goal: after init, only agnostic-managed files exist.
if [ "$DRY_RUN" != "1" ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  BACKUP_DIR="$ABS_TARGET/.claude.bak.$TS"
  ANY_PROCESSED=0

  wipe_path() {
    # wipe_path SOURCE — removes SOURCE (or moves to BACKUP_DIR if --backup)
    local src="$1"
    [ -e "$ABS_TARGET/$src" ] || return 0
    if [ "$BACKUP" = "1" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$src")"
      mv "$ABS_TARGET/$src" "$BACKUP_DIR/$src"
    else
      rm -rf "$ABS_TARGET/$src"
    fi
    ANY_PROCESSED=1
  }

  # Wipe .claude/ (BUT preserve settings.local.json — user permissions)
  if [ -d "$ABS_TARGET/.claude" ]; then
    if [ -f "$ABS_TARGET/.claude/settings.local.json" ]; then
      cp "$ABS_TARGET/.claude/settings.local.json" "$ABS_TARGET/.claude.settings.local.json.preserved"
    fi
    wipe_path ".claude"
    mkdir -p "$ABS_TARGET/.claude"
    if [ -f "$ABS_TARGET/.claude.settings.local.json.preserved" ]; then
      mv "$ABS_TARGET/.claude.settings.local.json.preserved" "$ABS_TARGET/.claude/settings.local.json"
    fi
  fi

  # Wipe CLAUDE.md (will be regenerated)
  wipe_path "CLAUDE.md"

  # Wipe other agent-framework configs (agent-md, codex, cursor, windsurf)
  wipe_path "agent-md.toml"
  wipe_path ".agent-md"
  wipe_path ".agents"
  wipe_path "AGENTS.md"
  wipe_path "AGENT.md"
  wipe_path ".codex"
  wipe_path ".cursor/rules/agent-md.mdc"
  wipe_path ".windsurf/rules/agent-md.md"
  # NOTE: .githooks/ NOT touched — may contain user's own pre-commit logic
  # NOTE: .gemini/ NOT touched — likely user's own Gemini config, not agent-md

  # Wipe ALL prior backup dirs from earlier installs (cleanup)
  for old_bak in "$ABS_TARGET"/.claude.bak.* "$ABS_TARGET"/.agnostic-bak.*; do
    [ -d "$old_bak" ] || continue
    # Skip the backup we just created (current TS), if --backup was used
    [ "$old_bak" = "$BACKUP_DIR" ] && continue
    rm -rf "$old_bak"
    ANY_PROCESSED=1
  done

  if [ "$ANY_PROCESSED" = "1" ]; then
    if [ "$BACKUP" = "1" ]; then
      echo "wiped previous agent configs → .claude.bak.$TS/"
    else
      echo "removed previous agent configs (use --backup to keep them)"
    fi
    echo
  fi
fi

# --- Detect stacks ---
STACKS=$("$FW_ROOT/bootstrap/detect-stack.sh" --dir="$ABS_TARGET")
PRIMARY=$("$FW_ROOT/bootstrap/detect-stack.sh" --dir="$ABS_TARGET" --primary 2>/dev/null || echo "unknown")
if [ -z "$STACKS" ]; then
  echo "No recognized stack markers (go.mod, package.json, pyproject.toml, etc.)."
  echo "Continuing with universal rules only."
  STACKS=""
fi

echo "Detected stacks:"
echo "$STACKS" | sed 's/^/  - /'
echo "Primary: $PRIMARY"
echo

# --- Detect MCP integrations (report only — don't block install) ---
echo "MCP integrations:"
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null; then
    GH_USER=$(gh api user --jq .login 2>/dev/null || echo "?")
    echo "  ✓ gh CLI authenticated ($GH_USER)"
  else
    echo "  ⚠ gh CLI installed but not authenticated — run: gh auth login"
  fi
else
  echo "  ✗ gh CLI not installed — required for /ship, /catchup, /fix-issue"
fi

if command -v claude &>/dev/null; then
  MCP_LIST=$(claude mcp list 2>&1 || true)
  for svc in Linear Slack Atlassian Figma Gmail Calendar; do
    if echo "$MCP_LIST" | grep -qiE "$svc.*Connected"; then
      echo "  ✓ $svc MCP connected"
    elif echo "$MCP_LIST" | grep -qi "$svc"; then
      echo "  ⚠ $svc MCP configured but not authenticated — visit https://claude.ai/settings/connectors"
    fi
  done
fi
echo

# --- Helpers ---
# Framework-managed: overwrite by default. Skip only with --no-overwrite.
write_fw() {
  local src="$1" dst="$2"
  if [ "$NO_OVERWRITE" = "1" ] && [ -f "$dst" ]; then
    echo "skip   $dst (--no-overwrite)"
    return
  fi
  if [ "$DRY_RUN" = "1" ]; then
    [ -f "$dst" ] && echo "WOULD overwrite $dst" || echo "WOULD write $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  if [ "$dst" = "${dst%.sh}.sh" ] && echo "$dst" | grep -q "hooks/"; then
    chmod +x "$dst"
  fi
  echo "wrote  $dst"
}

# User-managed: preserve by default. Overwrite only with --force.
write_user() {
  local src="$1" dst="$2"
  if [ -f "$dst" ] && [ "$FORCE" != "1" ]; then
    echo "keep   $dst (exists — use --force to overwrite)"
    return
  fi
  if [ "$DRY_RUN" = "1" ]; then
    [ -f "$dst" ] && echo "WOULD overwrite $dst" || echo "WOULD write $dst"
    return
  fi
  cp "$src" "$dst"
  echo "wrote  $dst"
}

# --- Framework files (overwrite by default) ---
[ "$DRY_RUN" = "1" ] || mkdir -p .claude/{hooks,agents,commands,rules}

# Hooks
for hook in _lib.sh block-destructive.sh post-edit-verify.sh stop-verify.sh truncation-check.sh precompact-summary.sh; do
  write_fw "$FW_ROOT/hooks/$hook" ".claude/hooks/$hook"
done

# Agents
for agent in architect code-reviewer security-reviewer performance-analyst db-specialist tdd-guide; do
  write_fw "$FW_ROOT/agents/$agent.md" ".claude/agents/$agent.md"
done

# Commands
for cmd in review ship catchup fix-issue new-feature bug-hunt debug-service add-endpoint standup triage-inbox notify-team; do
  write_fw "$FW_ROOT/commands/$cmd.md" ".claude/commands/$cmd.md"
done

# Universal rules
for rule in general security ci-cd; do
  write_fw "$FW_ROOT/rules/universal/$rule.md" ".claude/rules/universal/$rule.md"
done

# Stack-specific rules
while IFS= read -r stack; do
  [ -z "$stack" ] && continue
  case "$stack" in
    go)        STACK_DIR="backend-go" ;;
    node)      STACK_DIR="backend-node" ;;
    python)    STACK_DIR="backend-python" ;;
    react)     STACK_DIR="frontend-react" ;;
    terraform) STACK_DIR="infra-terraform" ;;
    *)         continue ;;
  esac
  if [ -d "$FW_ROOT/rules/$STACK_DIR" ]; then
    for f in "$FW_ROOT/rules/$STACK_DIR"/*.md; do
      [ -f "$f" ] || continue
      write_fw "$f" ".claude/rules/$STACK_DIR/$(basename "$f")"
    done
  fi
done <<< "$STACKS"

# settings.json (framework-managed — hook wiring)
write_fw "$FW_ROOT/templates/settings.json.tmpl" ".claude/settings.json"

# --- User-managed files (preserve by default) ---
write_user "$FW_ROOT/templates/settings.local.json.tmpl" ".claude/settings.local.json"

# agnostic.toml — generated, user-managed
if [ -f "agnostic.toml" ] && [ "$FORCE" != "1" ]; then
  echo "keep   agnostic.toml (exists — use --force to regenerate)"
else
  if [ "$DRY_RUN" = "1" ]; then
    echo "WOULD write agnostic.toml"
  else
    PROJECT_NAME="${AGNOSTIC_PROJECT_NAME:-$(basename "$ABS_TARGET")}"
    case "$PRIMARY" in
      go)     LFC_DEF="golangci-lint run --fast {file}"; LC_DEF="golangci-lint run ./..."; TC_DEF="go test ./..."; TY_DEF="" ;;
      node)   LFC_DEF="npx --no-install eslint {file}";  LC_DEF="npx eslint .";       TC_DEF="npm test";   TY_DEF="npx tsc --noEmit" ;;
      python) LFC_DEF="ruff check {file}";               LC_DEF="ruff check .";       TC_DEF="pytest";     TY_DEF="mypy ." ;;
      *)      LFC_DEF=""; LC_DEF=""; TC_DEF=""; TY_DEF="" ;;
    esac
    LFC="${AGNOSTIC_LINT_FILE_CMD-$LFC_DEF}"
    LC="${AGNOSTIC_LINT_CMD-$LC_DEF}"
    TC="${AGNOSTIC_TEST_CMD-$TC_DEF}"
    TY="${AGNOSTIC_TYPECHECK_CMD-$TY_DEF}"
    DESC="${AGNOSTIC_DESCRIPTION:-TODO: describe this project}"
    STACK_SUM="${AGNOSTIC_STACK_SUMMARY:-$PRIMARY}"
    STD_CH="${AGNOSTIC_STANDUP_CHANNEL:-standup}"
    ENG_CH="${AGNOSTIC_ENG_CHANNEL:-engineering}"
    INC_CH="${AGNOSTIC_INCIDENTS_CHANNEL:-incidents}"
    REL_CH="${AGNOSTIC_RELEASES_CHANNEL:-releases}"
    LIN_TEAM="${AGNOSTIC_LINEAR_TEAM:-}"
    GH_REPO="${AGNOSTIC_GITHUB_REPO:-}"
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{ONE_LINE_DESCRIPTION}}|$DESC|g" \
        -e "s|{{STACK_SUMMARY}}|$STACK_SUM|g" \
        -e "s|{{LINT_FILE_CMD}}|$LFC|g" \
        -e "s|{{LINT_CMD}}|$LC|g" \
        -e "s|{{TEST_CMD}}|$TC|g" \
        -e "s|{{TYPECHECK_CMD}}|$TY|g" \
        -e "s|{{STANDUP_CHANNEL}}|$STD_CH|g" \
        -e "s|{{ENG_CHANNEL}}|$ENG_CH|g" \
        -e "s|{{INCIDENTS_CHANNEL}}|$INC_CH|g" \
        -e "s|{{RELEASES_CHANNEL}}|$REL_CH|g" \
        -e "s|{{LINEAR_TEAM}}|$LIN_TEAM|g" \
        -e "s|{{GITHUB_REPO}}|$GH_REPO|g" \
        "$FW_ROOT/templates/agnostic.toml.tmpl" > agnostic.toml
    echo "wrote  agnostic.toml"
  fi
fi

# CLAUDE.md — framework-managed (agent-md style directives), back up existing
# Skip overwrite with --no-overwrite; back up always unless --no-backup
if [ "$NO_OVERWRITE" = "1" ] && [ -f "CLAUDE.md" ]; then
  echo "skip   CLAUDE.md (--no-overwrite)"
else
  if [ "$DRY_RUN" = "1" ]; then
    [ -f "CLAUDE.md" ] && echo "WOULD overwrite CLAUDE.md (backup to CLAUDE.md.bak.<ts>)" || echo "WOULD write CLAUDE.md"
  else
    PROJECT_NAME="${AGNOSTIC_PROJECT_NAME:-$(basename "$ABS_TARGET")}"
    DESC="${AGNOSTIC_DESCRIPTION:-TODO: one-line description}"
    STACK_SUM="${AGNOSTIC_STACK_SUMMARY:-$PRIMARY}"
    BUILD_CMDS="${AGNOSTIC_BUILD_COMMANDS:-# TODO: add build/test commands}"
    HARD_RULES="${AGNOSTIC_HARD_RULES:-TODO: list 5-10 hard rules specific to this project}"
    ARCH_POINTERS="${AGNOSTIC_ARCH_POINTERS:-TODO: list the most important entry points and aggregation files}"
    # CLAUDE.md backup already handled by wipe phase (.agnostic-bak.<ts>/CLAUDE.md)
    # Use python for multiline-safe substitution (sed gets tricky with \n in shell vars)
    python3 - "$FW_ROOT/templates/CLAUDE.md.tmpl" CLAUDE.md \
      "$PROJECT_NAME" "$DESC" "$STACK_SUM" "ARCHITECTURE.md" "" \
      "$BUILD_CMDS" "$HARD_RULES" "$ARCH_POINTERS" <<'PYEOF'
import sys
src, dst, project, desc, stack, archdoc, addl, build, rules, arch = sys.argv[1:11]
with open(src) as f:
    content = f.read()
subs = {
    "{{PROJECT_NAME}}": project,
    "{{ONE_LINE_DESCRIPTION}}": desc,
    "{{STACK_SUMMARY}}": stack,
    "{{ARCH_DOC}}": archdoc,
    "{{ADDITIONAL_DOC_POINTERS}}": addl,
    "{{BUILD_COMMANDS}}": build.replace("\\n", "\n"),
    "{{HARD_RULES}}": rules.replace("\\n", "\n"),
    "{{ARCH_POINTERS}}": arch.replace("\\n", "\n"),
}
for k, v in subs.items():
    content = content.replace(k, v)
with open(dst, "w") as f:
    f.write(content)
PYEOF
    echo "wrote  CLAUDE.md"
  fi
fi

# --- memory/ scaffold (user-managed, preserve existing) ---
[ "$DRY_RUN" = "1" ] || mkdir -p memory
case "$PRIMARY" in
  go)     TY_M=""; LC_M="golangci-lint run ./..."; TC_M="go test ./..." ;;
  node)   TY_M="npx tsc --noEmit"; LC_M="npx eslint ."; TC_M="npm test" ;;
  python) TY_M="mypy ."; LC_M="ruff check ."; TC_M="pytest" ;;
  *)      TY_M=""; LC_M=""; TC_M="" ;;
esac

# Detect plugins from global settings if not already set by wizard
if [ -z "${AGNOSTIC_PLUGINS:-}" ] && [ -f "$HOME/.claude/settings.json" ]; then
  AGNOSTIC_PLUGINS=$(python3 -c "
import json
try:
    d = json.load(open('$HOME/.claude/settings.json'))
    for k, v in d.get('enabledPlugins', {}).items():
        if v: print(k)
except: pass
" 2>/dev/null)
fi
if [ -z "${AGNOSTIC_MARKETPLACES:-}" ] && [ -f "$HOME/.claude/settings.json" ]; then
  AGNOSTIC_MARKETPLACES=$(python3 -c "
import json
try:
    d = json.load(open('$HOME/.claude/settings.json'))
    for k, v in d.get('extraKnownMarketplaces', {}).items():
        src = v.get('source', {})
        print(f'{k}|{src.get(\"source\",\"?\")}|{src.get(\"repo\",\"?\")}')
except: pass
" 2>/dev/null)
fi

# Build PLUGINS_LIST + MARKETPLACES_LIST as markdown for memory/agents.md
if [ -n "${AGNOSTIC_PLUGINS:-}" ]; then
  PLUGINS_LIST=$(echo "$AGNOSTIC_PLUGINS" | sed 's/^/- `/; s/$/`/' | python3 -c "import sys; print(sys.stdin.read().rstrip())")
else
  PLUGINS_LIST="(no plugins detected — add as your team adopts them)"
fi
if [ -n "${AGNOSTIC_MARKETPLACES:-}" ]; then
  MARKETPLACES_LIST=$(echo "$AGNOSTIC_MARKETPLACES" | awk -F'|' '{printf "- **%s** → `%s:%s`\n", $1, $2, $3}' | python3 -c "import sys; print(sys.stdin.read().rstrip())")
else
  MARKETPLACES_LIST="(none — only default Claude Code marketplaces)"
fi

for mem in agents plan progress verify gotchas; do
  src="$FW_ROOT/templates/memory/$mem.md.tmpl"
  dst="memory/$mem.md"
  [ -f "$src" ] || continue
  if [ -f "$dst" ] && [ "$FORCE" != "1" ]; then
    echo "keep   $dst (exists — use --force to regenerate)"
    continue
  fi
  if [ "$DRY_RUN" = "1" ]; then
    [ -f "$dst" ] && echo "WOULD overwrite $dst" || echo "WOULD write $dst"
    continue
  fi
  # Use python3 for multiline-safe substitution
  python3 - "$src" "$dst" \
    "$(basename "$ABS_TARGET")" "$PRIMARY" "$TY_M" "$LC_M" "$TC_M" \
    "$PLUGINS_LIST" "$MARKETPLACES_LIST" <<'PYEOF'
import sys
src, dst, project, stack, ty, lc, tc, plugins, markets = sys.argv[1:10]
with open(src) as f:
    content = f.read()
subs = {
    "{{PROJECT_NAME}}": project,
    "{{STACK_SUMMARY}}": stack,
    "{{TYPECHECK_CMD}}": ty,
    "{{LINT_CMD}}": lc,
    "{{TEST_CMD}}": tc,
    "{{PLUGINS_LIST}}": plugins,
    "{{MARKETPLACES_LIST}}": markets,
}
for k, v in subs.items():
    content = content.replace(k, v)
with open(dst, "w") as f:
    f.write(content)
PYEOF
  echo "wrote  $dst"
done

echo
if [ "$DRY_RUN" = "1" ]; then
  echo "Dry run complete. Re-run without --dry-run to apply."
else
  echo "Done. Next steps:"
  echo "  1. Edit CLAUDE.md — fill in TODOs (project description, build cmds, hard rules)"
  echo "  2. Edit agnostic.toml — adjust [verify] commands if heuristics aren't right"
  echo "  3. Review .claude/settings.local.json — add project-specific permission allowlist"
  echo "  4. Start Claude Code in this directory and try /review or /catchup"
  if ls "$ABS_TARGET"/.claude.bak.* &>/dev/null; then
    echo
    echo "  Previous config backed up to: $(ls -d "$ABS_TARGET"/.claude.bak.* | tail -1)"
    echo "  Restore: rm -rf .claude && mv .claude.bak.<ts> .claude"
  fi
fi
