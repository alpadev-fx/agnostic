#!/bin/bash
# detect-stack.sh
# Probes cwd for stack markers. Prints newline-separated stack tokens.
# Tokens: go | node | python | rust | ruby | terraform | react | c | cpp | asm | rpi | opi
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

# Systems stacks (C / C++ / assembly)
has_glob() {
  for pat in "$@"; do
    compgen -G "$pat" > /dev/null && return 0
  done
  return 1
}
has_glob "*.cpp" "*.cc" "*.hpp" "src/*.cpp" "src/*.cc" && found="${found}cpp\n"
if [ -f "CMakeLists.txt" ] && ! printf '%b' "$found" | grep -q '^cpp$'; then
  # CMake project with no C++ sources yet — treat as C++ unless C sources dominate
  has_glob "*.c" "src/*.c" || found="${found}cpp\n"
fi
has_glob "*.c" "src/*.c" && found="${found}c\n"
has_glob "*.s" "*.S" "*.asm" "src/*.s" "src/*.S" "src/*.asm" "asm/*" && found="${found}asm\n"

# Embedded boards (dependency / config markers)
board_grep() {
  grep -qsiE "$1" requirements.txt pyproject.toml setup.py package.json \
    CMakeLists.txt Makefile config.txt README.md 2>/dev/null
}
board_grep 'rpi[._-]gpio|gpiozero|pigpio|bcm28[0-9]+|raspberry[ -]?pi|picamera|pico-sdk' && found="${found}rpi\n"
board_grep 'wiringop|opi[._-]gpio|orange[ -]?pi|allwinner|rockchip|rk35[0-9]{2}|armbian' && found="${found}opi\n"

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
  compgen -G "${sub}*.cpp" > /dev/null || compgen -G "${sub}*.cc" > /dev/null && found="${found}cpp\n"
  compgen -G "${sub}*.c" > /dev/null && found="${found}c\n"
  compgen -G "${sub}*.S" > /dev/null || compgen -G "${sub}*.s" > /dev/null || compgen -G "${sub}*.asm" > /dev/null && found="${found}asm\n"
done

# Dedupe
DEDUPED=$(printf '%b' "$found" | sed '/^$/d' | sort -u)

if [ "$PRIMARY" = "1" ]; then
  # Priority order: backend before frontend, language stacks before infra
  for stack in go node python rust ruby cpp c react terraform asm rpi opi; do
    if echo "$DEDUPED" | grep -q "^${stack}$"; then
      echo "$stack"
      exit 0
    fi
  done
  exit 1
fi

echo "$DEDUPED"
