#!/bin/bash
# truncation-check.sh
# Runs after Grep and Bash. Detects when tool output was truncated
# (>50K chars → 2KB preview). Warns the agent to read full file or narrow scope.

INPUT=$(cat)

TOOL_RESPONSE=$(echo "$INPUT" | jq -r '
  if (.tool_response | type) == "string" then .tool_response
  elif (.tool_response | type) == "object" then (.tool_response | tostring)
  else empty
  end
')

if echo "$TOOL_RESPONSE" | grep -q "Output too large"; then
  MSG="WARNING: Tool output was truncated to a 2KB preview. Full output saved to disk. Read the full file at the given path before acting, or re-run with narrower scope (single directory, stricter pattern)."
  jq -n --arg m "$MSG" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}'
  exit 0
fi

exit 0
