#!/bin/bash
# block-destructive.sh
# PreToolUse hook for Bash commands.
# Blocks obviously destructive operations before they execute.
#
# Scope: seatbelt, not security boundary. Catches common foot-guns:
#   rm -rf /, DROP TABLE, force push, .env reads.
# Does NOT catch every destructive path. For real isolation, container/VM.

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# shellcheck disable=SC2016

# rm -rf targeting root, home, parent, or cwd
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+|(-[a-zA-Z]*\s+)*)(\/($|[[:space:];&|])|(~|\$HOME|\.\.)(/|$|[[:space:];&|])|\.($|[[:space:];&|]))'; then
  deny "Blocked destructive rm targeting root, home, or parent. Run manually if intentional."
fi

# find -delete / find -exec rm
if echo "$COMMAND" | grep -qE 'find\s+.*(-delete|-exec\s+rm)'; then
  deny "Blocked find -delete / find -exec rm. Run manually if intentional."
fi

# git clean -fdx
if echo "$COMMAND" | grep -qE 'git\s+clean\s+.*-[a-z]*[fx][a-z]*'; then
  deny "Blocked 'git clean -f/-x'. Wipes untracked/ignored files. Run manually if intentional."
fi

# DROP / TRUNCATE / unfiltered DELETE
if echo "$COMMAND" | grep -qiE 'DROP\s+(TABLE|DATABASE)|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\S+\s*;?\s*$'; then
  deny "Blocked destructive database command. Run manually if intentional."
fi

# Force push / hard reset
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f\b|git\s+reset\s+--hard\b'; then
  deny "Blocked force push or hard reset. Run manually if intentional."
fi

# .env reads (credential exposure)
if echo "$COMMAND" | grep -qE '(^|[[:space:];&|])(cat|less|head|tail|more|source|grep|sed|awk|bat)([[:space:]][^;&|>]*)?[[:space:]]([^[:space:];&|>]*/)?\.env([[:space:];&|>]|$)|echo.*\$\(.*([^[:space:];&|>]*/)?\.env([[:space:];&|>]|$)'; then
  deny "Blocked .env file access. Credentials should not be read by the agent."
fi

exit 0
