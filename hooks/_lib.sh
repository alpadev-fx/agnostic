#!/bin/bash
# _lib.sh — shared helpers for agnostic hooks.
# Source from other hooks: . "$(dirname "$0")/_lib.sh"
#
# Shell, not Python — hooks stay dependency-free.
# Safe under `set -u`.

# read_toml <file> <section> <key>
# Prints value or nothing. Handles `key = "value"` or `key = value`.
# Skips lines after `#`. Not a full TOML parser — enough for config slots.
read_toml() {
  local file="$1" section="$2" key="$3"
  [ -f "$file" ] || return 0
  awk -v section="$section" -v key="$key" '
    BEGIN { in_sec = 0 }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*\[/ {
      sec = $0
      sub(/^[[:space:]]*\[/, "", sec); sub(/\][[:space:]]*$/, "", sec)
      gsub(/[[:space:]]/, "", sec)
      in_sec = (sec == section) ? 1 : 0
      next
    }
    in_sec && index($0, "=") > 0 {
      k = substr($0, 1, index($0, "=") - 1)
      v = substr($0, index($0, "=") + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
      sub(/[[:space:]]*#.*$/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      if (k == key) {
        if (v ~ /^".*"$/)      { gsub(/^"|"$/, "", v) }
        else if (v ~ /^'\''.*'\''$/) { gsub(/^'\''|'\''$/, "", v) }
        print v
        exit
      }
    }
  ' "$file"
}

# toml_path — location of project config (override with AGNOSTIC_TOML env)
toml_path() {
  echo "${AGNOSTIC_TOML:-agnostic.toml}"
}

# stat_mtime <path> — portable mtime in epoch seconds (Linux + macOS)
stat_mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null
}

# file_size <path> — portable byte size (Linux + macOS)
file_size() {
  stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null
}

# detect_pm — prints detected Node package manager based on lockfile, or nothing.
# Order: pnpm > yarn > bun > npm.
detect_pm() {
  if   [ -f "pnpm-lock.yaml" ];                       then echo pnpm
  elif [ -f "yarn.lock" ];                            then echo yarn
  elif [ -f "bun.lockb" ] || [ -f "bun.lock" ];       then echo bun
  elif [ -f "package-lock.json" ] || [ -f "package.json" ]; then echo npm
  fi
}

# npm_test_cmd — test-runner invocation for detected PM, or nothing.
npm_test_cmd() {
  case "$(detect_pm)" in
    pnpm) echo "pnpm test --silent" ;;
    yarn) echo "yarn test --silent" ;;
    bun)  echo "bun test" ;;
    npm)  echo "npm test --silent" ;;
    *)    echo "" ;;
  esac
}

# has_npm_test_script — returns 0 if package.json declares a real test script.
has_npm_test_script() {
  [ -f "package.json" ] || return 1
  local t
  t=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
  [ -n "$t" ] && [ "$t" != 'echo "Error: no test specified" && exit 1' ]
}

# detect_stack — prints primary stack identifier(s) found in cwd.
# Multiple stacks possible (monorepo). Output: newline-separated tokens.
# Tokens: go, node, python, rust, ruby, terraform
detect_stack() {
  local found=""
  [ -f "go.mod" ] && found="${found}go\n"
  [ -f "package.json" ] && found="${found}node\n"
  { [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; } && found="${found}python\n"
  [ -f "Cargo.toml" ] && found="${found}rust\n"
  [ -f "Gemfile" ] && found="${found}ruby\n"
  { compgen -G "*.tf" > /dev/null || [ -d "terraform" ] || [ -d "infrastructure/terraform" ]; } && found="${found}terraform\n"
  printf '%b' "$found" | sed '/^$/d'
}
