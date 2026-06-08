#!/usr/bin/env bash
# Collect live stack metrics into dashboard/metrics.js (a JS global, so the dashboard
# loads it via <script> without file:// CORS issues). Run from the repo root or scripts/.
# GPU/gaming fields come from the GPU host; pass via FAKOLI_GPU_JSON / FAKOLI_GAMING_ON env,
# else they render as "n/a" (collect on fakoli-dark with nvidia-smi).
set -uo pipefail
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$HOME/.openclaw/openclaw.json"
OUT="$REPO_DIR/dashboard/metrics.js"
mkdir -p "$REPO_DIR/dashboard"
SGLANG_URL="${FAKOLI_SGLANG_URL:-http://100.87.34.66:30000}"

GEN="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GW_STATE="$(openclaw gateway status 2>&1 | grep -oE 'state [a-z]+' | head -1 | awk '{print $2}')"; GW_STATE="${GW_STATE:-unknown}"
CFG_VALID=false; openclaw config validate >/dev/null 2>&1 && CFG_VALID=true
STATE_MCP=false; jq -e '.mcp.servers."fakoli-state"' "$CFG" >/dev/null 2>&1 && STATE_MCP=true
SGLANG_OK=false; curl -fsS --max-time 5 "$SGLANG_URL/v1/models" >/dev/null 2>&1 && SGLANG_OK=true
RUNNING_REQ="$(curl -fsS --max-time 5 "$SGLANG_URL/metrics" 2>/dev/null | grep -E '^sglang:num_running_reqs' | awk '{print $2}' | head -1)"; RUNNING_REQ="${RUNNING_REQ:-null}"

# Agents (id + model + tier) from config.
AGENTS_JSON="$(jq -c '[.agents.list[] | select(.id|startswith("fakoli-")) | {id, model, tier: (if (.model|test("sglang")) then "local" else "cloud" end)}]' "$CFG" 2>/dev/null || echo '[]')"
EVAL_JSON="$(cat "$HOME/fakoli-runner/eval/eval-latest.json" 2>/dev/null || echo 'null')"
GPU_JSON="${FAKOLI_GPU_JSON:-null}"
GAMING_ON="${FAKOLI_GAMING_ON:-null}"

cat > "$OUT" <<JS
window.FAKOLI_METRICS = {
  "generated": "$GEN",
  "gateway": {"state": "$GW_STATE"},
  "config_valid": $CFG_VALID,
  "state_mcp": $STATE_MCP,
  "sglang": {"reachable": $SGLANG_OK, "url": "$SGLANG_URL", "running_req": $RUNNING_REQ, "concurrency_budget": 3, "model": "qwen3.6-35b-a3b-local"},
  "gpu": $GPU_JSON,
  "gaming_on": $GAMING_ON,
  "agents": $AGENTS_JSON,
  "eval": $EVAL_JSON
};
JS
echo "wrote $OUT"
