#!/bin/bash
# install-plugins.sh — enable agnostic-recommended Claude Code plugins + MCPs
# in user's GLOBAL config (~/.claude/settings.json).
#
# Idempotent: skips plugins/marketplaces/MCPs already present.
# Non-destructive: merges into existing settings, never wipes user prefs.

set -e

SETTINGS="$HOME/.claude/settings.json"
SKIP_PROMPT="${1:-}"

echo "Installing recommended plugins + MCPs..."

# === Plugin list ===
PLUGINS=(
  "gopls-lsp@claude-plugins-official"          # Go LSP
  "claude-mem@thedotmack"                       # persistent memory across sessions
  "playwright@claude-plugins-official"          # browser MCP
  "atomic-agents@claude-plugins-official"       # small focused agent pattern
  "frontend-design@claude-plugins-official"     # UI design helpers
  "caveman@caveman"                             # terse mode
  "headroom@headroom-marketplace"               # startup hooks / context savings
)

# === Marketplace list (name → github repo) ===
MARKETS_NAMES=(thedotmack caveman headroom-marketplace)
MARKETS_REPOS=(thedotmack/claude-mem JuliusBrussee/caveman headroomlabs-ai/headroom)

# === MCPs (name → URL) ===
MCP_NAMES=(stitch)
MCP_URLS=(https://stitch.googleapis.com/mcp)

# Merge plugins + marketplaces into ~/.claude/settings.json via python
python3 - "$SETTINGS" "${PLUGINS[@]}" --markets "${MARKETS_NAMES[@]}" --repos "${MARKETS_REPOS[@]}" <<'PYEOF'
import json, os, sys
args = sys.argv[1:]
path = args.pop(0)

# Parse: plugins ... --markets names ... --repos repos ...
plugins = []
markets_names = []
markets_repos = []
mode = "plugins"
for a in args:
    if a == "--markets":
        mode = "markets"; continue
    if a == "--repos":
        mode = "repos"; continue
    if mode == "plugins": plugins.append(a)
    elif mode == "markets": markets_names.append(a)
    elif mode == "repos": markets_repos.append(a)

os.makedirs(os.path.dirname(path), exist_ok=True)
try:
    with open(path) as f: cfg = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}

cfg.setdefault("enabledPlugins", {})
added_plugins = []
for p in plugins:
    if not cfg["enabledPlugins"].get(p):
        cfg["enabledPlugins"][p] = True
        added_plugins.append(p)

cfg.setdefault("extraKnownMarketplaces", {})
added_markets = []
for name, repo in zip(markets_names, markets_repos):
    if name not in cfg["extraKnownMarketplaces"]:
        cfg["extraKnownMarketplaces"][name] = {
            "source": {"source": "github", "repo": repo}
        }
        added_markets.append(f"{name} → {repo}")

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)

for p in added_plugins: print(f"  + plugin: {p}")
for m in added_markets: print(f"  + marketplace: {m}")
if not added_plugins and not added_markets:
    print("  (all plugins + marketplaces already enabled)")
PYEOF

# Install MCPs via `claude mcp add` (idempotent — skip if already present)
if command -v claude &>/dev/null; then
  MCP_LIST=$(claude mcp list 2>&1 || true)
  for i in "${!MCP_NAMES[@]}"; do
    name="${MCP_NAMES[$i]}"
    url="${MCP_URLS[$i]}"
    if echo "$MCP_LIST" | grep -qi "^$name:"; then
      echo "  ✓ MCP $name already installed"
    else
      if claude mcp add --transport http "$name" "$url" 2>/dev/null; then
        echo "  + MCP $name added ($url)"
      else
        echo "  ⚠ MCP $name install failed — add manually: claude mcp add --transport http $name $url"
      fi
    fi
  done
fi

# gstack — Claude Code skill cloned into ~/.claude/skills/gstack
GSTACK_DIR="$HOME/.claude/skills/gstack"
GSTACK_REPO="https://github.com/garrytan/gstack.git"
if [ -d "$GSTACK_DIR/.git" ]; then
  echo "  ✓ gstack skill already installed"
elif [ -d "$GSTACK_DIR" ]; then
  echo "  ⚠ gstack dir exists but not a git repo — skipping (remove $GSTACK_DIR to reinstall)"
else
  mkdir -p "$HOME/.claude/skills"
  if git clone --quiet "$GSTACK_REPO" "$GSTACK_DIR" 2>/dev/null; then
    echo "  + gstack skill cloned → $GSTACK_DIR"
  else
    echo "  ⚠ gstack clone failed — install manually:"
    echo "    git clone $GSTACK_REPO $GSTACK_DIR"
  fi
fi

# notch-notify — Dynamic Island / notch Live Activity for Claude Code sessions.
# Not a marketplace plugin: its own install.sh builds a Swift binary into
# ~/.notch-notify and registers hooks in ~/.claude/settings.json (idempotent,
# backs up settings first). macOS + swift toolchain only.
NOTCH_HOME="${NOTCH_NOTIFY_HOME:-$HOME/.notch-notify}"
NOTCH_REPO="https://github.com/LedgerFi-Inc/notch-notify.git"
if [ "$(uname)" != "Darwin" ]; then
  echo "  ⏭ notch-notify skipped (macOS only)"
elif [ -x "$NOTCH_HOME/bin/notch-notify" ]; then
  echo "  ✓ notch-notify already installed ($NOTCH_HOME)"
elif ! command -v swift &>/dev/null; then
  echo "  ⚠ notch-notify needs the swift toolchain — skipping (run: xcode-select --install, then re-run)"
else
  NOTCH_TMP="$(mktemp -d)"
  if git clone --quiet "$NOTCH_REPO" "$NOTCH_TMP/notch-notify" 2>/dev/null; then
    if ( cd "$NOTCH_TMP/notch-notify" && ./install.sh ); then
      echo "  + notch-notify installed → $NOTCH_HOME (hooks registered — start a new session)"
    else
      echo "  ⚠ notch-notify install.sh failed — install manually:"
      echo "    git clone $NOTCH_REPO && cd notch-notify && ./install.sh"
    fi
    rm -rf "$NOTCH_TMP"
  else
    rm -rf "$NOTCH_TMP"
    echo "  ⚠ notch-notify clone failed — install manually:"
    echo "    git clone $NOTCH_REPO && cd notch-notify && ./install.sh"
  fi
fi

echo "Plugins + MCPs install: done"
