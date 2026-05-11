#!/bin/bash
# precompact-summary.sh
# Runs before context compaction. Injects a short summary so the
# compacted context retains the project's identity and hard rules.
#
# Reads from agnostic.toml [project] summary if set, else falls back
# to a generic message pointing at CLAUDE.md.

# shellcheck source=hooks/_lib.sh
. "$(dirname "$0")/_lib.sh"

TOML=$(toml_path)
SUMMARY=$(read_toml "$TOML" project summary)

if [ -z "$SUMMARY" ]; then
  SUMMARY="Project context preserved across compaction. See ./CLAUDE.md for stack identity, build commands, and hard rules. See .claude/rules/ for deep details and .claude/agents/ for specialists."
fi

jq -n --arg m "$SUMMARY" '{hookSpecificOutput: {hookEventName: "PreCompact", additionalContext: $m}}'
exit 0
