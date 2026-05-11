#!/bin/bash
# post-edit-verify.sh
# Runs after every Write/Edit/MultiEdit. Surfaces lint failures so the
# agent sees them immediately. Type-checking runs at Stop (stop-verify.sh)
# to avoid 10-30s tsc delays on every edit.
#
# Hook output contract:
#   exit 0 + JSON on stdout → Claude reads structured decision.
# Emits {decision: "block", reason: ...} so Claude sees errors.
#
# Configuration (agnostic.toml):
#   [verify]
#   lint_file = "npx --no-install eslint {file}"
# {file} is substituted with edited file path.

# shellcheck source=hooks/_lib.sh
. "$(dirname "$0")/_lib.sh"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Per-file lint scope. Project-wide checks happen at Stop.
if ! echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|rb)$'; then
  exit 0
fi

TOML=$(toml_path)
CFG_LINT_FILE=$(read_toml "$TOML" verify lint_file)

ERRORS=""

if [ -n "$CFG_LINT_FILE" ]; then
  export AGNOSTIC_FILE="$FILE_PATH"
  OUT=$(bash -c "${CFG_LINT_FILE//\{file\}/\"\$AGNOSTIC_FILE\"}" 2>&1)
  if [ $? -ne 0 ]; then
    ERRORS="lint errors in ${FILE_PATH}:
${OUT}"
  fi
else
  # Heuristic fallback per extension.
  if echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx)$' \
     && { compgen -G ".eslintrc*" > /dev/null || compgen -G "eslint.config.*" > /dev/null; }; then
    OUT=$(npx --no-install eslint "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
      ERRORS="eslint errors in ${FILE_PATH}:
${OUT}"
    fi
  fi

  if echo "$FILE_PATH" | grep -qE '\.py$' && command -v ruff &>/dev/null; then
    OUT=$(ruff check "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
      ERRORS="${ERRORS}
ruff errors in ${FILE_PATH}:
${OUT}"
    fi
  fi

  if echo "$FILE_PATH" | grep -qE '\.go$' && command -v golangci-lint &>/dev/null; then
    OUT=$(golangci-lint run --fast "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
      ERRORS="${ERRORS}
golangci-lint errors in ${FILE_PATH}:
${OUT}"
    fi
  fi
fi

if [ -n "$ERRORS" ]; then
  TRUNCATED=$(printf '%s' "$ERRORS" | head -50)
  REASON="Lint failed. Fix before continuing:
${TRUNCATED}"
  jq -n --arg r "$REASON" '{decision: "block", reason: $r}'
  exit 0
fi
