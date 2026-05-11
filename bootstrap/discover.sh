#!/bin/bash
# discover.sh — auto-detect project answers by reading files.
#
# Sources:
#   - README.md          → description, project name
#   - Makefile           → build commands, lint/test targets
#   - package.json       → scripts, react detection
#   - pyproject.toml     → ruff/mypy/pytest config
#   - go.mod             → Go version
#   - .golangci.yml      → linting constraints (hint at hard rules)
#   - git remote         → GitHub repo
#   - git branch         → Linear team key (LED-XXX, ENG-XXX patterns)
#   - existing CLAUDE.md → preserve hard rules + arch pointers
#   - entry points       → main.go, index.ts, App.tsx, entrypoint.py
#
# Outputs key=value pairs to stdout (env-var compatible).
# Usage:
#   eval "$(./discover.sh /path/to/project)"
#   Or sourced via wizard.sh as defaults.

# NOTE: no `set -e` here. Discovery is best-effort; missing files / failed
# greps must not abort the script. Each step handles its own errors.
shopt -s nullglob  # empty globs expand to nothing instead of literal
TARGET_DIR="${1:-$PWD}"
cd "$TARGET_DIR" 2>/dev/null || exit 0

# === DESCRIPTION ===
# Pull first non-heading paragraph from README.md
DESC=""
if [ -f README.md ]; then
  DESC=$(python3 -c "
import re
try:
    with open('README.md') as f: t = f.read()
    # Skip H1, find first paragraph
    lines = t.split('\n')
    started = False
    para = []
    for line in lines:
        s = line.strip()
        if not started:
            if s and not s.startswith('#') and not s.startswith('<'):
                started = True
                para.append(s)
            continue
        if not s or s.startswith('#'):
            break
        para.append(s)
    out = ' '.join(para)
    # Strip badges/links
    out = re.sub(r'\[!\[.*?\]\(.*?\)\]\(.*?\)', '', out)
    out = re.sub(r'<.*?>', '', out)
    out = re.sub(r'\s+', ' ', out).strip()
    # Trim to first full sentence under 300 chars
    if len(out) > 300:
        m = re.match(r'^(.{40,300}?\.) ', out + ' ')
        out = m.group(1) if m else out[:300]
    print(out)
except: pass
" 2>/dev/null)
fi

# === STACK SUMMARY (with versions) — probes monorepo subdirs ===
STACK_PARTS=()

# Find first file by name in cwd + 1-level subdirs
find_first() {
  local name="$1"
  [ -f "$name" ] && { echo "$name"; return; }
  for sub in */; do
    case "$sub" in node_modules/|.git/|.claude/|vendor/|dist/|build/|.claude.bak.*/) continue ;; esac
    [ -f "${sub}${name}" ] && { echo "${sub}${name}"; return; }
  done
}

GO_FILE=$(find_first "go.mod")
if [ -n "$GO_FILE" ]; then
  GO_VER=$(awk '/^go [0-9]/{print $2}' "$GO_FILE" 2>/dev/null | head -1)
  STACK_PARTS+=("Go ${GO_VER:-?}")
fi

PKG_FILE=$(find_first "package.json")
if [ -n "$PKG_FILE" ]; then
  REACT_VER=$(python3 -c "
import json
try:
    d = json.load(open('$PKG_FILE'))
    deps = {**d.get('dependencies',{}), **d.get('devDependencies',{})}
    r = deps.get('react','')
    print(r.lstrip('^~') if r else '')
except: pass
" 2>/dev/null)
  if [ -n "$REACT_VER" ]; then
    STACK_PARTS+=("React $REACT_VER")
  else
    STACK_PARTS+=("Node")
  fi
fi

PY_FILE=$(find_first "pyproject.toml")
[ -z "$PY_FILE" ] && PY_FILE=$(find_first "setup.py")
[ -z "$PY_FILE" ] && PY_FILE=$(find_first "requirements.txt")
if [ -n "$PY_FILE" ]; then
  PY_VER=""
  if [[ "$PY_FILE" == *"pyproject.toml" ]]; then
    PY_VER=$(python3 -c "
import re
try:
    with open('$PY_FILE') as f:
        t = f.read()
    m = re.search(r'python\s*=\s*[\"\\']([^\"\\']+)[\"\\']', t)
    if m: print(m.group(1).lstrip('>=^~ ').split(',')[0])
except: pass
" 2>/dev/null)
  fi
  STACK_PARTS+=("Python ${PY_VER:-3.x}")
fi

[ -n "$(find_first Cargo.toml)" ] && STACK_PARTS+=("Rust")
[ -n "$(find_first Gemfile)" ] && STACK_PARTS+=("Ruby")
[ "${#STACK_PARTS[@]}" -gt 0 ] && STACK_SUMMARY=$(printf '%s + ' "${STACK_PARTS[@]}" | sed 's/ + $//')

# === BUILD COMMANDS ===
# Top Makefile targets relevant to dev workflow (excluding internal/helper)
BUILD_COMMANDS=""
if [ -f Makefile ]; then
  BUILD_COMMANDS=$(awk -F: '
    /^[a-zA-Z][a-zA-Z0-9_-]*:/ && !/^\./ && !/=/ {
      target=$1
      gsub(/[[:space:]]/, "", target)
      # Skip noisy/internal targets
      if (target ~ /^(\.PHONY|help|all)$/) next
      print "make " target
    }' Makefile 2>/dev/null | head -10)
fi
if [ -z "$BUILD_COMMANDS" ] && [ -f package.json ]; then
  BUILD_COMMANDS=$(python3 -c "
import json
try:
    d = json.load(open('package.json'))
    for k in d.get('scripts', {}).keys():
        if k in ('start','dev','build','test','lint','typecheck','format'):
            print(f'npm run {k}')
except: pass
" 2>/dev/null)
fi

# === VERIFY COMMANDS (prefer Makefile if has lint/test) ===
LINT_FILE_CMD=""
LINT_CMD=""
TEST_CMD=""
TYPECHECK_CMD=""

# Check Makefile for lint/test targets
if [ -f Makefile ]; then
  grep -qE '^lint:' Makefile && LINT_CMD="make lint"
  grep -qE '^test:' Makefile && TEST_CMD="make test"
fi

# Stack-default fallbacks (probes monorepo subdirs)
if [ -n "$GO_FILE" ]; then
  [ -z "$LINT_FILE_CMD" ] && LINT_FILE_CMD="golangci-lint run --fast {file}"
  [ -z "$LINT_CMD" ] && LINT_CMD="golangci-lint run ./..."
  [ -z "$TEST_CMD" ] && TEST_CMD="go test ./..."
fi
if [ -n "$PKG_FILE" ]; then
  [ -z "$LINT_FILE_CMD" ] && LINT_FILE_CMD="npx --no-install eslint {file}"
  [ -z "$LINT_CMD" ] && LINT_CMD="npx eslint ."
  [ -z "$TEST_CMD" ] && TEST_CMD="npm test"
  if [ -n "$(find_first tsconfig.json)" ] && [ -z "$TYPECHECK_CMD" ]; then
    TYPECHECK_CMD="npx --no-install tsc --noEmit"
  fi
fi
if [ -n "$PY_FILE" ]; then
  [ -z "$LINT_FILE_CMD" ] && LINT_FILE_CMD="ruff check {file}"
  [ -z "$LINT_CMD" ] && LINT_CMD="ruff check ."
  [ -z "$TEST_CMD" ] && TEST_CMD="pytest"
  if [ "$PY_FILE" = "pyproject.toml" ] && grep -q "mypy" "$PY_FILE" 2>/dev/null && [ -z "$TYPECHECK_CMD" ]; then
    TYPECHECK_CMD="mypy ."
  fi
fi

# === HARD RULES — extract from CLAUDE.md (or latest backup) ===
# Look for "IMPORTANT Rules" / "Hard Rules" section and grab its bullets.
HARD_RULES=""
extract_rules() {
  local src="$1"
  python3 -c "
import re
try:
    with open('$src') as f: t = f.read()
    # Find a section titled 'IMPORTANT Rules' or 'Hard Rules' (any heading level)
    pat = re.compile(r'^#+\s*(?:IMPORTANT\s+Rules|Hard\s+Rules\b.*)\$', re.IGNORECASE | re.MULTILINE)
    m = pat.search(t)
    if not m: exit(0)
    rest = t[m.end():]
    # Stop at next heading
    end = re.search(r'^#+\s', rest, re.MULTILINE)
    section = rest[:end.start()] if end else rest
    bullets = re.findall(r'^- .+\$', section, re.MULTILINE)
    for b in bullets[:12]: print(b)
except: pass
" 2>/dev/null
}

# Latest backup first (preserve pre-install rules), then current CLAUDE.md
LATEST_BAK=$(ls -t CLAUDE.md.bak.* 2>/dev/null | head -1)
if [ -n "$LATEST_BAK" ]; then
  HARD_RULES=$(extract_rules "$LATEST_BAK")
fi
if [ -z "$HARD_RULES" ] && [ -f CLAUDE.md ]; then
  HARD_RULES=$(extract_rules "CLAUDE.md")
fi

# === ARCH POINTERS — find entry files ===
ARCH=""
for entry in cmd/*/main.go back/cmd/*/main.go src/index.ts src/index.tsx \
             src/main.ts front/src/index.js front/src/App.js \
             ai/deployment/entrypoint.py main.py app.py src/main.py \
             infrastructure/terraform/main.tf; do
  for f in $entry; do
    [ -f "$f" ] && ARCH="${ARCH}- ${f}"$'\n'
  done
done
# Also include aggregation files if they exist
for agg in back/internal/adapters/http/handlers/handler.go \
           back/internal/usecase/usecase.go \
           back/internal/db/migrations \
           front/src/Features \
           ai/apps; do
  [ -e "$agg" ] && ARCH="${ARCH}- ${agg}"$'\n'
done
ARCH=$(echo -n "$ARCH" | head -10)

# === LINEAR TEAM — infer from current branch ===
LINEAR_TEAM=""
if git rev-parse --git-dir &>/dev/null; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "")
  LINEAR_TEAM=$(echo "$BRANCH" | grep -oE '^[A-Z]{2,5}-[0-9]+' | head -1 | sed 's/-[0-9]*$//')
  if [ -z "$LINEAR_TEAM" ]; then
    # Try recent branch history
    LINEAR_TEAM=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/origin/ 2>/dev/null | \
      grep -oE '^[A-Z]{2,5}-[0-9]+' | head -5 | sed 's/-[0-9]*$//' | sort -u | head -1)
  fi
fi

# === GITHUB REPO — from remote ===
GH_REPO=""
if git rev-parse --git-dir &>/dev/null; then
  REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
  if [ -n "$REMOTE_URL" ]; then
    GH_REPO=$(echo "$REMOTE_URL" | python3 -c "
import sys, re
url = sys.stdin.read().strip()
m = re.search(r'[/:]([^/:]+/[^/]+?)(?:\.git)?\$', url)
print(m.group(1) if m else '')
" 2>/dev/null)
  fi
fi

# === OUTPUT (one var per line, shell-quoted) ===
emit() {
  # emit VAR "value" — outputs VAR='value' (escaped)
  local var="$1" val="$2"
  printf "%s=%s\n" "$var" "$(printf '%q' "$val")"
}

emit AGNOSTIC_PROJECT_NAME "$(basename "$TARGET_DIR")"
emit AGNOSTIC_DESCRIPTION "$DESC"
emit AGNOSTIC_STACK_SUMMARY "$STACK_SUMMARY"
emit AGNOSTIC_BUILD_COMMANDS "$BUILD_COMMANDS"
emit AGNOSTIC_HARD_RULES "$HARD_RULES"
emit AGNOSTIC_ARCH_POINTERS "$ARCH"
emit AGNOSTIC_LINT_FILE_CMD "$LINT_FILE_CMD"
emit AGNOSTIC_TYPECHECK_CMD "$TYPECHECK_CMD"
emit AGNOSTIC_LINT_CMD "$LINT_CMD"
emit AGNOSTIC_TEST_CMD "$TEST_CMD"
emit AGNOSTIC_GITHUB_REPO "$GH_REPO"
emit AGNOSTIC_LINEAR_TEAM "$LINEAR_TEAM"
