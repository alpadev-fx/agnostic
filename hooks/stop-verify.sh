#!/bin/bash
# stop-verify.sh
# Runs when Claude tries to finish (Stop event).
# Agent cannot declare "Done!" until project compiles, lints, and passes tests.
#
# Hook output contract:
#   exit 0 + JSON on stdout → Claude reads structured decision.
# Emits {decision:"block", reason:...} when checks fail.
#
# Configuration (agnostic.toml):
#   [verify]
#   typecheck = "npx --no-install tsc --noEmit"
#   lint      = "make lint"
#   test      = "make test"
# Falls back to heuristics if config missing.

# shellcheck source=hooks/_lib.sh
. "$(dirname "$0")/_lib.sh"

cat > /dev/null  # discard stdin

TOML=$(toml_path)
CFG_TYPECHECK=$(read_toml "$TOML" verify typecheck)
CFG_LINT=$(read_toml "$TOML" verify lint)
CFG_TEST=$(read_toml "$TOML" verify test)

ERRORS=""
CHECKS_RUN=0

run_check() {
  local label="$1" cmd="$2"
  [ -n "$cmd" ] || return 0
  CHECKS_RUN=$((CHECKS_RUN + 1))
  local OUT
  OUT=$(eval "$cmd" 2>&1)
  if [ $? -ne 0 ]; then
    ERRORS="${ERRORS}${label} FAILED:
$(echo "$OUT" | head -30)

"
  fi
}

# --- Typecheck ---
if [ -n "$CFG_TYPECHECK" ]; then
  run_check "TYPECHECK ($CFG_TYPECHECK)" "$CFG_TYPECHECK"
elif [ -f "tsconfig.json" ]; then
  run_check "TSC --noEmit" "npx --no-install tsc --noEmit"
fi

# --- Lint ---
if [ -n "$CFG_LINT" ]; then
  run_check "LINT ($CFG_LINT)" "$CFG_LINT"
else
  if compgen -G ".eslintrc*" > /dev/null || compgen -G "eslint.config.*" > /dev/null; then
    run_check "ESLINT" "npx --no-install eslint ."
  fi
  if command -v ruff &>/dev/null && compgen -G "*.py" > /dev/null; then
    run_check "RUFF" "ruff check ."
  fi
  if [ -f "go.mod" ] && command -v golangci-lint &>/dev/null; then
    run_check "GOLANGCI-LINT" "golangci-lint run ./..."
  fi
fi

# --- Python mypy (heuristic) ---
if [ -z "$CFG_TYPECHECK" ] && command -v mypy &>/dev/null \
   && { [ -f "mypy.ini" ] || grep -q '\[tool.mypy\]' pyproject.toml 2>/dev/null; }; then
  run_check "MYPY" "mypy ."
fi

# --- Tests ---
if [ -n "$CFG_TEST" ]; then
  run_check "TEST ($CFG_TEST)" "$CFG_TEST"
else
  if has_npm_test_script; then
    run_check "NPM TEST" "$(npm_test_cmd)"
  fi
  if [ -f "go.mod" ]; then
    run_check "GO TEST" "go test ./..."
  fi
  if [ -f "pytest.ini" ] || grep -q '\[tool.pytest' pyproject.toml 2>/dev/null; then
    run_check "PYTEST" "pytest"
  fi
fi

if [ -n "$ERRORS" ]; then
  REASON="Stop blocked — verification failed (${CHECKS_RUN} checks run):

${ERRORS}
Fix or override by editing agnostic.toml [verify]."
  jq -n --arg r "$REASON" '{decision: "block", reason: $r}'
  exit 0
fi

exit 0
