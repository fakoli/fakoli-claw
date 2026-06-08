#!/usr/bin/env bash
# install.sh — register the Fakoli crew as OpenClaw agents on this gateway.
#
# Tier routing (override with env vars):
#   FAKOLI_CLOUD_MODEL  (default openai/gpt-5.5)            -> orchestrator, guido, critic, sentinel
#   FAKOLI_LOCAL_MODEL  (default sglang/qwen3.6-35b-a3b-local) -> welder, smith, scout, herald, keeper
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STATE="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CLOUD_MODEL="${FAKOLI_CLOUD_MODEL:-openai/gpt-5.5}"
LOCAL_MODEL="${FAKOLI_LOCAL_MODEL:-sglang/qwen3.6-35b-a3b-local}"

CLOUD_AGENTS="fakoli-orchestrator fakoli-guido fakoli-critic fakoli-sentinel"
LOCAL_AGENTS="fakoli-welder fakoli-smith fakoli-scout fakoli-herald fakoli-keeper"

install_agent() {
  local id="$1" model="$2"
  local ws="$STATE/workspace-$id"
  if [ ! -f "$REPO_DIR/agents/$id/AGENTS.md" ]; then
    echo "  SKIP $id (missing agents/$id/AGENTS.md — run scripts/build-prompts.sh first)"; return
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

echo "Installing Fakoli crew agents..."
for id in $CLOUD_AGENTS; do install_agent "$id" "$CLOUD_MODEL"; done
for id in $LOCAL_AGENTS; do install_agent "$id" "$LOCAL_MODEL"; done

# Compaction fix for small-context local models (see docs/NOTES-compaction.md).
# reserveTokens floor of 20000 is too large for a ~32K local window and forces
# turn-1 compaction; 8192 + floor 0 gives the local model ~24.5K usable.
echo "Applying compaction settings..."
openclaw config set agents.defaults.compaction.reserveTokensFloor 0 >/dev/null
openclaw config set agents.defaults.compaction.reserveTokens 8192 >/dev/null

echo "Restarting gateway..."
openclaw gateway restart >/dev/null 2>&1 || true

echo
echo "Done. Verify with:  openclaw agents list"
echo "Run a specialist:   openclaw agent --agent fakoli-welder -m '<task>'"
echo
echo "Phase B (wave dispatch) note: to let fakoli-orchestrator spawn the crew, set"
echo "  agents.list[<orchestrator>].subagents.allowAgents to the 8 specialist ids"
echo "  (see config/fakoli-claw.agents.json5)."
