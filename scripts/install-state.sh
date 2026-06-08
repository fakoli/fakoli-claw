#!/usr/bin/env bash
# Phase D: register the fakoli-state FastMCP server with OpenClaw and ensure its runtime.
# Idempotent. Does NOT restart the gateway (the parent install.sh does that).
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
STATE="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CFG="$STATE/openclaw.json"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Locate the state server launcher (vendored under this repo, else the fakoli-plugins clone).
CANDIDATES=(
  "$REPO_DIR/state/bin/fakoli-state-mcp"
  "$HOME/ai-code/remote-cowork/fakoli-plugins/plugins/fakoli-state/bin/fakoli-state-mcp"
)
STATE_BIN=""
for c in "${CANDIDATES[@]}"; do [ -f "$c" ] && STATE_BIN="$c" && break; done
[ -z "$STATE_BIN" ] && { echo "FATAL: fakoli-state-mcp launcher not found in: ${CANDIDATES[*]}"; exit 1; }
echo "state launcher: $STATE_BIN"

# Ensure uv (the launcher runs 'uv sync' then 'python -m fakoli_state.mcp_server').
if ! command -v uv >/dev/null 2>&1; then
  echo "uv not found — attempting 'brew install uv'..."
  brew install uv >/dev/null 2>&1 || echo "WARN: brew install uv failed — install uv manually, then re-run."
fi
if command -v uv >/dev/null 2>&1; then echo "uv: $(uv --version)"; else echo "uv: STILL MISSING (state MCP will fail to start until uv is present)"; fi

# Pre-warm the venv so the gateway's first MCP spawn doesn't block on a cold uv sync.
if command -v uv >/dev/null 2>&1; then
  (cd "$(dirname "$STATE_BIN")" && uv sync >/dev/null 2>&1) && echo "uv sync OK (deps warmed)" || echo "WARN: uv sync failed (server may sync on first call)"
fi

# Register fakoli-state under .mcp.servers (OpenClaw schema: mcp.servers.<id>, NOT top-level mcpServers).
TMP="$(mktemp)"
jq --arg bin "$STATE_BIN" '
  .mcp.servers."fakoli-state" = {type:"stdio", command:"bash", args:[$bin]}
' "$CFG" > "$TMP" && python3 -c "import json;json.load(open('$TMP'))" \
  && cp "$CFG" "$CFG.bak-state-$(date +%Y%m%d-%H%M%S)" && mv "$TMP" "$CFG" \
  && echo "registered mcp.servers.fakoli-state -> bash $STATE_BIN"

if openclaw config validate >/dev/null 2>&1; then
  echo "config valid (mcpServers accepted)"
else
  echo "CONFIG INVALID after mcp add — review schema:"; openclaw config validate 2>&1 | tail -8
fi

echo "Tier routing: state tools are model-agnostic; crew tiers stay config-routed"
echo "  (welder/smith/scout/herald/keeper -> SGLang; guido/critic/sentinel/orchestrator -> GPT-5.5)."
echo "install-state done. Restart gateway to load the MCP: openclaw gateway restart"
