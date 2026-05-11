#!/bin/bash
# detect-stack.sh
# Probes cwd for stack markers. Prints newline-separated stack tokens.
# Tokens: go | node | python | rust | ruby | terraform | react
#
# Usage:
#   ./detect-stack.sh                  # prints found stacks
#   ./detect-stack.sh --primary        # prints only the most likely primary stack

set -e

TARGET_DIR="${TARGET_DIR:-$PWD}"
PRIMARY=0
for arg in "$@"; do
  case "$arg" in
    --primary) PRIMARY=1 ;;
    --dir=*)   TARGET_DIR="${arg#--dir=}" ;;
  esac
done

cd "$TARGET_DIR"

found=""

# Backend stacks
[ -f "go.mod" ] && found="${found}go\n"
[ -f "package.json" ] && found="${found}node\n"
{ [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; } && found="${found}python\n"
[ -f "Cargo.toml" ] && found="${found}rust\n"
[ -f "Gemfile" ] && found="${found}ruby\n"

# Frontend frameworks (React detection inside Node project)
if [ -f "package.json" ] && grep -q '"react"' package.json 2>/dev/null; then
  found="${found}react\n"
fi

# Infrastructure
if compgen -G "*.tf" > /dev/null || [ -d "terraform" ] || [ -d "infrastructure/terraform" ]; then
  found="${found}terraform\n"
fi

# Monorepo: scan one level deep for subprojects
for sub in */; do
  [ -d "$sub" ] || continue
  case "$sub" in
    node_modules/|.git/|.claude/|vendor/|dist/|build/) continue ;;
  esac
  [ -f "${sub}go.mod" ] && found="${found}go\n"
  if [ -f "${sub}package.json" ]; then
    found="${found}node\n"
    grep -q '"react"' "${sub}package.json" 2>/dev/null && found="${found}react\n"
  fi
  [ -f "${sub}pyproject.toml" ] || [ -f "${sub}setup.py" ] && found="${found}python\n"
  [ -f "${sub}Cargo.toml" ] && found="${found}rust\n"
  [ -f "${sub}Gemfile" ] && found="${found}ruby\n"
done

# Dedupe
DEDUPED=$(printf '%b' "$found" | sed '/^$/d' | sort -u)

if [ "$PRIMARY" = "1" ]; then
  # Priority order: backend before frontend, language stacks before infra
  for stack in go node python rust ruby react terraform; do
    if echo "$DEDUPED" | grep -q "^${stack}$"; then
      echo "$stack"
      exit 0
    fi
  done
  exit 1
fi

echo "$DEDUPED"
