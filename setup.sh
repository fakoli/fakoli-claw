#!/usr/bin/env bash
# setup — the complete story: serve a model, fix OpenClaw for it, install the crew, run a wave.
# Each step is also runnable on its own; this just sequences them. Run from the repo root.
#
#   bash setup.sh                                       # bootstrap OpenClaw + install crew + state + smoke
#   bash setup.sh --serve --model <hf-id>              # also start SGLang first (needs NVIDIA GPU + Docker)
#   bash setup.sh --provider-url http://HOST:PORT/v1 --served-name <id>   # point at any OpenAI-compatible endpoint
#   bash setup.sh --no-state                            # skip the fakoli-state MCP
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SERVE=0; STATE=1; MODEL=""; PROVIDER_URL=""; SERVED=""
while [ $# -gt 0 ]; do case "$1" in
  --serve) SERVE=1; shift;; --no-state) STATE=0; shift;;
  --model) MODEL="$2"; shift 2;; --served-name) SERVED="$2"; shift 2;;
  --provider-url) PROVIDER_URL="$2"; shift 2;;
  -h|--help) sed -n '2,8p' "$0"; exit 0;;
  *) echo "unknown arg: $1"; exit 2;; esac; done

echo "== fakoli-claw setup =="
echo "-- preflight --"
for b in openclaw jq python3; do command -v "$b" >/dev/null 2>&1 && echo "  [ok] $b" || echo "  [MISSING] $b (required)"; done
command -v docker >/dev/null 2>&1 && echo "  [ok] docker" || echo "  [info] docker (only needed for --serve)"
command -v uv >/dev/null 2>&1 && echo "  [ok] uv" || echo "  [info] uv (state MCP installs it)"

if [ "$SERVE" = 1 ]; then
  echo "-- step 1: serve a model (SGLang) --"
  ARGS=(); [ -n "$MODEL" ] && ARGS+=(--model "$MODEL"); [ -n "$SERVED" ] && ARGS+=(--served-name "$SERVED")
  bash "$HERE/scripts/sglang-serve.sh" up "${ARGS[@]}"
fi

echo "-- step 2: bootstrap OpenClaw for local models --"
BARGS=(); { [ -n "$PROVIDER_URL" ] && [ -n "${SERVED:-$MODEL}" ]; } && BARGS+=(--provider-url "$PROVIDER_URL" --model "${SERVED:-$MODEL}")
bash "$HERE/scripts/openclaw-bootstrap.sh" "${BARGS[@]}"

echo "-- step 3: install the crew (agents + flow/style skills + router on every agent) --"
bash "$HERE/scripts/install.sh"

if [ "$STATE" = 1 ]; then
  echo "-- step 4: install durable state (MCP) --"
  bash "$HERE/scripts/install-state.sh" || echo "  (state install had warnings — non-fatal)"
fi

echo "-- step 5: health check --"
bash "$HERE/evals/health-smoke.sh" || true

echo
echo "Done. Run a wave:"
echo "  openclaw agent --agent fakoli-orchestrator --session-key agent:fakoli-orchestrator:run1 -m \"Execute the plan at <abs-path> ...\""
echo "Docs: docs/GETTING-STARTED.md · docs/ROUTING.md · docs/ARCHITECTURE.md"
