#!/bin/bash
# wizard.sh — interactive setup for agnostic.
# Collects project-specific answers, exports as env vars, then runs install.sh.
#
# Skip wizard with: agnostic init --non-interactive

set -e

FW_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:-$PWD}"
shift || true

# Forward extra flags to install.sh
EXTRA_FLAGS=("$@")

cd "$TARGET_DIR"
ABS_TARGET="$(pwd)"
PROJECT_DIR_NAME=$(basename "$ABS_TARGET")

# Detect stacks before asking
DETECTED=$("$FW_ROOT/bootstrap/detect-stack.sh" --dir="$ABS_TARGET" | tr '\n' ',' | sed 's/,$//')
PRIMARY=$("$FW_ROOT/bootstrap/detect-stack.sh" --dir="$ABS_TARGET" --primary 2>/dev/null || echo "")

# Detect git remote → suggest GitHub repo (python3 — macOS sed lacks lazy quantifiers)
GH_REPO_DEFAULT=""
if git -C "$ABS_TARGET" rev-parse --git-dir &>/dev/null; then
  REMOTE_URL=$(git -C "$ABS_TARGET" remote get-url origin 2>/dev/null || true)
  if [ -n "$REMOTE_URL" ]; then
    GH_REPO_DEFAULT=$(echo "$REMOTE_URL" | python3 -c "
import sys, re
url = sys.stdin.read().strip()
m = re.search(r'[/:]([^/:]+/[^/]+?)(?:\.git)?\$', url)
print(m.group(1) if m else '')
" 2>/dev/null)
  fi
fi

# Suggest stack-aware verify commands
case "$PRIMARY" in
  go)     LINT_FILE_DEF="golangci-lint run --fast {file}"; LINT_DEF="golangci-lint run ./..."; TEST_DEF="go test ./..."; TC_DEF="" ;;
  node)   LINT_FILE_DEF="npx --no-install eslint {file}";  LINT_DEF="npx eslint .";       TEST_DEF="npm test";   TC_DEF="npx tsc --noEmit" ;;
  python) LINT_FILE_DEF="ruff check {file}";               LINT_DEF="ruff check .";       TEST_DEF="pytest";     TC_DEF="mypy ." ;;
  *)      LINT_FILE_DEF=""; LINT_DEF=""; TEST_DEF=""; TC_DEF="" ;;
esac

# === Helpers ===
ask() {
  # ask VAR_NAME "Prompt" "default"
  local var="$1" prompt="$2" default="$3" answer
  if [ -n "$default" ]; then
    printf "  %s [%s]: " "$prompt" "$default" >&2
  else
    printf "  %s: " "$prompt" >&2
  fi
  IFS= read -r answer </dev/tty
  [ -z "$answer" ] && answer="$default"
  printf -v "$var" "%s" "$answer"
}

ask_yn() {
  # ask_yn VAR_NAME "Prompt" "default(y|n)"
  local var="$1" prompt="$2" default="$3" answer
  printf "  %s [%s]: " "$prompt" "$default" >&2
  IFS= read -r answer </dev/tty
  [ -z "$answer" ] && answer="$default"
  case "$answer" in
    y|Y|yes|YES) printf -v "$var" "y" ;;
    *)           printf -v "$var" "n" ;;
  esac
}

ask_multiline() {
  # ask_multiline VAR_NAME "Prompt (blank line to finish)" "prefix per line"
  local var="$1" prompt="$2" prefix="$3" line acc=""
  printf "  %s (one per line, blank line to finish):\n" "$prompt" >&2
  while IFS= read -r line </dev/tty; do
    [ -z "$line" ] && break
    if [ -n "$acc" ]; then
      acc="${acc}\n${prefix}${line}"
    else
      acc="${prefix}${line}"
    fi
  done
  printf -v "$var" "%s" "$acc"
}

# === Header ===
cat <<EOF >&2
============================================
  agnostic — interactive setup
============================================

Target:    $ABS_TARGET
Stacks:    ${DETECTED:-(none detected)}
Primary:   ${PRIMARY:-(none)}

Answers fill CLAUDE.md, agnostic.toml, and memory/*. Press Enter to accept defaults.

EOF

# === Section 1: project identity ===
echo "## Project identity" >&2
ask Q_PROJECT_NAME       "Project name"                "$PROJECT_DIR_NAME"
ask Q_DESCRIPTION        "One-line description"        ""
ask Q_STACK_SUMMARY      "Stack summary"               "${PRIMARY:-mixed}"

echo >&2

# === Section 2: verification commands ===
echo "## Verification commands (used by Stop hook + memory/verify.md)" >&2
ask Q_LINT_FILE_CMD      "Per-file lint (post Write/Edit)" "$LINT_FILE_DEF"
ask Q_TYPECHECK_CMD      "Project typecheck"            "$TC_DEF"
ask Q_LINT_CMD           "Project lint"                 "$LINT_DEF"
ask Q_TEST_CMD           "Project tests"                "$TEST_DEF"

echo >&2

# === Section 3: integrations ===
echo "## Integrations (used by /standup, /triage-inbox, /notify-team)" >&2
ask Q_GITHUB_REPO        "GitHub repo (owner/name)"     "$GH_REPO_DEFAULT"
ask Q_LINEAR_TEAM        "Linear team key (blank to skip)" ""
ask Q_STANDUP_CHANNEL    "Slack standup channel"        "standup"
ask Q_ENG_CHANNEL        "Slack engineering channel"    "engineering"
ask Q_INCIDENTS_CHANNEL  "Slack incidents channel"      "incidents"
ask Q_RELEASES_CHANNEL   "Slack releases channel"       "releases"

echo >&2

# === Section 3.5: Claude Code plugins (auto-detect from ~/.claude/settings.json) ===
echo "## Claude Code plugins (expected toolchain)" >&2
DETECTED_PLUGINS=""
DETECTED_MARKETS=""
if [ -f "$HOME/.claude/settings.json" ]; then
  DETECTED_PLUGINS=$(python3 -c "
import json
try:
    d = json.load(open('$HOME/.claude/settings.json'))
    plugins = d.get('enabledPlugins', {})
    for k, v in plugins.items():
        if v: print(k)
except: pass
" 2>/dev/null)
  DETECTED_MARKETS=$(python3 -c "
import json
try:
    d = json.load(open('$HOME/.claude/settings.json'))
    markets = d.get('extraKnownMarketplaces', {})
    for k, v in markets.items():
        src = v.get('source', {})
        kind = src.get('source', '?')
        repo = src.get('repo', '?')
        print(f'{k}|{kind}|{repo}')
except: pass
" 2>/dev/null)
fi

if [ -n "$DETECTED_PLUGINS" ]; then
  echo "  Detected $(echo "$DETECTED_PLUGINS" | wc -l | tr -d ' ') plugins:" >&2
  echo "$DETECTED_PLUGINS" | sed 's/^/    - /' >&2
  if [ -n "$DETECTED_MARKETS" ]; then
    echo "  Detected $(echo "$DETECTED_MARKETS" | wc -l | tr -d ' ') marketplaces:" >&2
    echo "$DETECTED_MARKETS" | sed 's/|/ → /g' | sed 's/^/    - /' >&2
  fi
  echo >&2
  ask_yn Q_INCLUDE_PLUGINS "Document these as the project's expected toolchain?" "y"
  if [ "$Q_INCLUDE_PLUGINS" = "y" ]; then
    Q_PLUGINS="$DETECTED_PLUGINS"
    Q_MARKETPLACES="$DETECTED_MARKETS"
  fi
else
  echo "  No plugins detected in ~/.claude/settings.json (skipping)" >&2
fi

echo >&2

# === Section 4: project content ===
echo "## Build & test commands (one shell line per entry)" >&2
ask_multiline Q_BUILD_COMMANDS "Build commands" ""

echo >&2

echo "## Hard rules (project-specific invariants)" >&2
ask_multiline Q_HARD_RULES "Hard rules" "- "

echo >&2

echo "## Architecture pointers (key entry/aggregation files)" >&2
ask_multiline Q_ARCH_POINTERS "Architecture pointers" "- "

echo >&2

# === Section 5: post-install ===
echo "## Post-install" >&2
ask_yn Q_COMMIT          "Commit to git after install?" "n"

echo >&2
echo "============================================" >&2
echo "  Review" >&2
echo "============================================" >&2
echo "Project:        $Q_PROJECT_NAME" >&2
echo "Description:    $Q_DESCRIPTION" >&2
echo "Stack:          $Q_STACK_SUMMARY" >&2
echo "GitHub repo:    $Q_GITHUB_REPO" >&2
echo "Linear team:    $Q_LINEAR_TEAM" >&2
echo "Channels:       $Q_STANDUP_CHANNEL / $Q_ENG_CHANNEL / $Q_INCIDENTS_CHANNEL / $Q_RELEASES_CHANNEL" >&2
echo "Verify lint_file: $Q_LINT_FILE_CMD" >&2
echo "Verify typecheck: $Q_TYPECHECK_CMD" >&2
echo "Verify lint:      $Q_LINT_CMD" >&2
echo "Verify test:      $Q_TEST_CMD" >&2
echo "Commit:         $Q_COMMIT" >&2
echo >&2

ask_yn Q_CONFIRM         "Proceed with install?" "y"
if [ "$Q_CONFIRM" != "y" ]; then
  echo "Aborted by user." >&2
  exit 1
fi

# === Export answers as env vars for install.sh ===
export AGNOSTIC_PROJECT_NAME="$Q_PROJECT_NAME"
export AGNOSTIC_DESCRIPTION="$Q_DESCRIPTION"
export AGNOSTIC_STACK_SUMMARY="$Q_STACK_SUMMARY"
export AGNOSTIC_BUILD_COMMANDS="$Q_BUILD_COMMANDS"
export AGNOSTIC_HARD_RULES="$Q_HARD_RULES"
export AGNOSTIC_ARCH_POINTERS="$Q_ARCH_POINTERS"
export AGNOSTIC_LINT_FILE_CMD="$Q_LINT_FILE_CMD"
export AGNOSTIC_TYPECHECK_CMD="$Q_TYPECHECK_CMD"
export AGNOSTIC_LINT_CMD="$Q_LINT_CMD"
export AGNOSTIC_TEST_CMD="$Q_TEST_CMD"
export AGNOSTIC_GITHUB_REPO="$Q_GITHUB_REPO"
export AGNOSTIC_LINEAR_TEAM="$Q_LINEAR_TEAM"
export AGNOSTIC_STANDUP_CHANNEL="$Q_STANDUP_CHANNEL"
export AGNOSTIC_ENG_CHANNEL="$Q_ENG_CHANNEL"
export AGNOSTIC_INCIDENTS_CHANNEL="$Q_INCIDENTS_CHANNEL"
export AGNOSTIC_RELEASES_CHANNEL="$Q_RELEASES_CHANNEL"
export AGNOSTIC_PLUGINS="${Q_PLUGINS:-}"
export AGNOSTIC_MARKETPLACES="${Q_MARKETPLACES:-}"

echo >&2
echo "## Running install..." >&2
echo >&2

"$FW_ROOT/bootstrap/install.sh" "$ABS_TARGET" "${EXTRA_FLAGS[@]}"

# === Post-install: git commit ===
if [ "$Q_COMMIT" = "y" ] && git -C "$ABS_TARGET" rev-parse --git-dir &>/dev/null; then
  cd "$ABS_TARGET"
  # Add gitignore entries
  for entry in ".claude/settings.local.json" ".claude.bak.*" "CLAUDE.md.bak.*" ".claude.manual-bak.*"; do
    if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
      echo "$entry" >> .gitignore
    fi
  done
  git add CLAUDE.md agnostic.toml .claude/ memory/ .gitignore 2>/dev/null || true
  if git diff --cached --quiet; then
    echo "No changes to commit." >&2
  else
    git commit -m "chore: install agnostic framework" >&2
    echo "✓ Committed." >&2
  fi
fi

echo >&2
echo "============================================" >&2
echo "  Setup complete" >&2
echo "============================================" >&2
echo "Next: open Claude Code in this directory and try /catchup or /review." >&2
