#!/usr/bin/env bash
# openclaw-bootstrap — make OpenClaw work well with small-context LOCAL models.
# General-audience helper (not fakoli-specific): applies the fixes a <~40K-ctx local model needs to
# run at all under OpenClaw, sane sub-agent defaults for crews, and optionally registers your local
# OpenAI-compatible endpoint as a provider. Idempotent. Backs up config. Validates. No restart
# unless --restart.
#
# Usage:
#   openclaw-bootstrap.sh                                   # compaction + sub-agent defaults
#   openclaw-bootstrap.sh --provider-url http://HOST:PORT/v1 --model my-local-model
#     (provider opts: --api / --api-key / --ctx / --max-tokens; env FAKOLI_API/_KEY/CTX/MAXTOK)
#   openclaw-bootstrap.sh --dry-run                         # show changes, write nothing
#   openclaw-bootstrap.sh --restart                         # restart the gateway after
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

DRY=0; RESTART=0; PROVIDER_URL=""; MODEL=""; PROVIDER="${FAKOLI_PROVIDER:-sglang}"
RESERVE="${FAKOLI_RESERVE_TOKENS:-8192}"
API="${FAKOLI_API:-openai-completions}"; APIKEY="${FAKOLI_API_KEY:-EMPTY}"
CTX="${FAKOLI_CTX:-32768}"; MAXTOK="${FAKOLI_MAXTOK:-8192}"
while [ $# -gt 0 ]; do case "$1" in
  --dry-run) DRY=1; shift;; --restart) RESTART=1; shift;;
  --provider-url) PROVIDER_URL="$2"; shift 2;; --model) MODEL="$2"; shift 2;;
  --provider) PROVIDER="$2"; shift 2;; --reserve) RESERVE="$2"; shift 2;;
  --api) API="$2"; shift 2;; --api-key) APIKEY="$2"; shift 2;;
  --ctx|--context-window) CTX="$2"; shift 2;; --max-tokens) MAXTOK="$2"; shift 2;;
  -h|--help) sed -n '2,13p' "$0"; exit 0;;
  *) echo "unknown arg: $1"; exit 2;; esac; done

command -v openclaw >/dev/null || { echo "FATAL: openclaw not on PATH"; exit 1; }
CFG="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/openclaw.json"
run(){ if [ "$DRY" = 1 ]; then echo "DRY: $*"; else "$@"; fi; }

echo "== OpenClaw bootstrap for local models =="
BK=""
if [ "$DRY" = 0 ]; then BK="$CFG.bak-bootstrap-$(date +%Y%m%d-%H%M%S)"; cp "$CFG" "$BK"; echo "backup: $BK"; fi

# THE fix: OpenClaw's default reserveTokens floor (20000) leaves a ~32K local model ~12K usable, so
# its own prompt + tool schemas trip turn-1 compaction and the openai-completions transcript
# compaction dead-locks ("Already compacted"). 8192 + floor 0 gives ~24.5K usable; harmless for big
# cloud windows (threshold auto-scales as contextWindow - reserveTokens).
echo "-- compaction fix (REQUIRED for small-context local models) --"
run openclaw config set agents.defaults.compaction.reserveTokens "$RESERVE"
run openclaw config set agents.defaults.compaction.reserveTokensFloor 0

echo "-- sub-agent defaults (depth + concurrency caps for crews) --"
run openclaw config set agents.defaults.subagents '{"maxSpawnDepth":2,"maxConcurrent":5,"maxChildrenPerAgent":8,"runTimeoutSeconds":1200}' --strict-json --merge

if [ -n "$PROVIDER_URL" ] && [ -n "$MODEL" ]; then
  echo "-- register provider '$PROVIDER' -> $PROVIDER_URL (model: $MODEL) --"
  # Schema matches OpenClaw's models.providers.<id>: api + apiKey live at the PROVIDER level,
  # each model carries id + contextWindow. apiKey "EMPTY" is correct for a no-auth local server;
  # pass --api-key for a hosted endpoint.
  VAL=$(printf '{"baseUrl":"%s","apiKey":"%s","api":"%s","models":[{"id":"%s","name":"%s","contextWindow":%s,"maxTokens":%s}]}' \
        "$PROVIDER_URL" "$APIKEY" "$API" "$MODEL" "$MODEL" "$CTX" "$MAXTOK")
  if openclaw config set "models.providers.$PROVIDER" "$VAL" --strict-json --merge --dry-run >/dev/null 2>&1; then
    run openclaw config set "models.providers.$PROVIDER" "$VAL" --strict-json --merge
    echo "   registered. Reference the model as: $PROVIDER/$MODEL"
  else
    echo "   NOTE: couldn't auto-register (provider may already exist, or schema differs in your build)."
    echo "   Set it manually with this value:"
    printf "     openclaw config set models.providers.%s '%s' --strict-json --merge\n" "$PROVIDER" "$VAL"
  fi
fi

if [ "$DRY" = 0 ]; then
  if openclaw config validate >/dev/null 2>&1; then
    echo "config valid"
  else
    echo "CONFIG INVALID — restoring backup"; [ -n "$BK" ] && cp "$BK" "$CFG"; openclaw config validate 2>&1 | tail -3; exit 1
  fi
  if [ "$RESTART" = 1 ]; then echo "restarting gateway..."; openclaw gateway restart >/dev/null 2>&1 || true; sleep 4; openclaw gateway status 2>&1 | grep -iE 'Runtime|Connectivity' || true
  else echo "run 'openclaw gateway restart' to apply."; fi
fi
echo "done."
