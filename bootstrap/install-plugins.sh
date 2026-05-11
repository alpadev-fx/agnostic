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
)

# === Marketplace list (name → github repo) ===
MARKETS_NAMES=(thedotmack caveman)
MARKETS_REPOS=(thedotmack/claude-mem JuliusBrussee/caveman)

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

# gstack — external CLI, not auto-installed (needs brew or curl)
if ! command -v gstack &>/dev/null; then
  echo "  ⚠ gstack CLI not installed (external tool — separate install required)"
  echo "    Install: see https://github.com/gstack-cli/gstack (or skip if not needed)"
fi

echo "Plugins + MCPs install: done"
