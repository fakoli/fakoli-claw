#!/usr/bin/env bash
# install.sh — register the Fakoli crew + flow + state on this OpenClaw gateway.
# Idempotent. One-command setup: agents (tier-routed) -> orchestrator subagents allowlist ->
# compaction fix -> flow skills -> state MCP (if present) -> restart -> verify.
#
# Tier routing (override with env):
#   FAKOLI_CLOUD_MODEL (default openai/gpt-5.5)               -> orchestrator, guido, critic, sentinel
#   FAKOLI_LOCAL_MODEL (default sglang/qwen3.6-35b-a3b-local) -> welder, smith, scout, herald, keeper
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CFG="$STATE/openclaw.json"
CLOUD_MODEL="${FAKOLI_CLOUD_MODEL:-openai/gpt-5.5}"
LOCAL_MODEL="${FAKOLI_LOCAL_MODEL:-sglang/qwen3.6-35b-a3b-local}"

CLOUD_AGENTS="fakoli-orchestrator fakoli-guido fakoli-critic fakoli-sentinel"
LOCAL_AGENTS="fakoli-welder fakoli-smith fakoli-scout fakoli-herald fakoli-keeper"
FLOW_SKILLS="flow-brainstorm flow-plan flow-execute flow-verify flow-finish flow-quick"
SPECIALISTS='["fakoli-guido","fakoli-critic","fakoli-scout","fakoli-smith","fakoli-welder","fakoli-herald","fakoli-keeper","fakoli-sentinel"]'

command -v openclaw >/dev/null || { echo "FATAL: openclaw not on PATH"; exit 1; }
command -v jq >/dev/null       || { echo "FATAL: jq required"; exit 1; }
command -v python3 >/dev/null  || { echo "FATAL: python3 required"; exit 1; }

echo "== Preflight =="
SGLANG_URL="${FAKOLI_SGLANG_URL:-http://100.87.34.66:30000}"
if curl -fsS --max-time 5 "$SGLANG_URL/v1/models" >/dev/null 2>&1 || curl -fsS --max-time 5 "$SGLANG_URL/health" >/dev/null 2>&1; then
  echo "  [ok] SGLang reachable ($SGLANG_URL)"
else
  echo "  [warn] SGLang NOT reachable ($SGLANG_URL) — local tier offline; turn it ON or set FAKOLI_SGLANG_URL"
fi
openclaw gateway status >/dev/null 2>&1 && echo "  [ok] gateway reachable" || echo "  [warn] gateway not reachable (will start/restart at the end)"
grep -q 'sglang/qwen3.6-35b-a3b-local' "$CFG" 2>/dev/null && echo "  [ok] local model in config" || echo "  [warn] local model not yet in config"
grep -q 'openai/gpt-5.5' "$CFG" 2>/dev/null && echo "  [ok] cloud model in config" || echo "  [warn] cloud model not yet in config"
command -v uv >/dev/null 2>&1 && echo "  [ok] uv present" || echo "  [warn] uv missing (needed for the fakoli-state MCP; install-state.sh will add it)"

install_agent() {
  local id="$1" model="$2" ws="$STATE/workspace-$1"
  if [ ! -f "$REPO_DIR/agents/$id/AGENTS.md" ]; then
    echo "  SKIP $id (missing agents/$id/AGENTS.md)"; return
  fi
  openclaw agents add "$id" --non-interactive --workspace "$ws" --model "$model" --json >/dev/null 2>&1 || true
  cp "$REPO_DIR/agents/$id/AGENTS.md" "$ws/AGENTS.md"
  rm -f "$ws/BOOTSTRAP.md"
  if [ -d "$REPO_DIR/agents/_references" ]; then
    mkdir -p "$ws/skills/crew-ops/references"
    cp -a "$REPO_DIR/agents/_references/." "$ws/skills/crew-ops/references/" 2>/dev/null || true
  fi
  echo "  installed $id ($model)"
}

echo "== Fakoli crew agents =="
for id in $CLOUD_AGENTS; do install_agent "$id" "$CLOUD_MODEL"; done
for id in $LOCAL_AGENTS; do install_agent "$id" "$LOCAL_MODEL"; done

echo "== Orchestrator subagents allowlist + defaults limits (Phase B) =="
# Per-agent subagents schema accepts ONLY allowAgents + delegationMode; limit fields live in
# agents.defaults.subagents. (Learned from live schema validation.)
TMP="$(mktemp)"
jq --argjson allow "$SPECIALISTS" '
  .agents.defaults.subagents = ((.agents.defaults.subagents // {}) + {maxSpawnDepth:2, maxConcurrent:5, maxChildrenPerAgent:8, runTimeoutSeconds:1200})
  | .agents.list |= map(if .id=="fakoli-orchestrator" then .subagents = {delegationMode:"prefer", allowAgents:$allow} else . end)
' "$CFG" > "$TMP" && python3 -c "import json;json.load(open('$TMP'))" && cp "$CFG" "$CFG.bak-install-$(date +%Y%m%d-%H%M%S)" && mv "$TMP" "$CFG"
echo "  orchestrator allowAgents set; defaults limits set"

echo "== Compaction fix (small-context local models) =="
openclaw config set agents.defaults.compaction.reserveTokensFloor 0 >/dev/null
openclaw config set agents.defaults.compaction.reserveTokens 8192 >/dev/null

echo "== Flow skills =="
for s in $FLOW_SKILLS; do
  if [ -d "$REPO_DIR/skills/$s" ]; then
    openclaw skills install "$REPO_DIR/skills/$s" --agent fakoli-orchestrator --as "$s" --force >/dev/null 2>&1 \
      && echo "  $s -> fakoli-orchestrator" || echo "  WARN $s -> fakoli-orchestrator failed"
    openclaw skills install "$REPO_DIR/skills/$s" --agent main --as "$s" --force >/dev/null 2>&1 \
      && echo "  $s -> main" || echo "  WARN $s -> main failed"
  fi
done

echo "== Style skill =="
if [ -d "$REPO_DIR/skills/style-ops" ]; then
  openclaw skills install "$REPO_DIR/skills/style-ops" --agent main --as style-ops --force >/dev/null 2>&1 \
    && echo "  style-ops -> main" || echo "  WARN style-ops -> main failed"
  openclaw skills install "$REPO_DIR/skills/style-ops" --agent fakoli-orchestrator --as style-ops --force >/dev/null 2>&1 \
    && echo "  style-ops -> fakoli-orchestrator" || echo "  WARN style-ops -> fakoli-orchestrator failed"
fi

echo "== State MCP (Phase D, if present) =="
if [ -x "$REPO_DIR/scripts/install-state.sh" ]; then
  bash "$REPO_DIR/scripts/install-state.sh" || echo "  WARN state install failed (non-fatal)"
else
  echo "  (scripts/install-state.sh not present — skipping)"
fi

echo "== Validate + restart =="
if openclaw config validate >/dev/null 2>&1; then echo "  config valid"; else echo "  CONFIG INVALID"; openclaw config validate 2>&1 | tail -5; exit 1; fi
openclaw gateway restart >/dev/null 2>&1 || true
sleep 4
openclaw gateway status 2>&1 | grep -iE "Runtime|Connectivity" || true

echo
echo "Done. Verify:  openclaw agents list ; openclaw skills list --agent fakoli-orchestrator"
echo "Run a wave:    openclaw agent --agent fakoli-orchestrator -m 'Execute the plan at <path> ...'"
