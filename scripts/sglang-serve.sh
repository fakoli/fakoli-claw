#!/usr/bin/env bash
# sglang-serve — run the SGLang inference server (Docker) with configurable model + params.
# This is the "serve" half of fakoli-claw: stand up an OpenAI-compatible local endpoint that the
# crew's local tier talks to. Works on any NVIDIA host with Docker (Linux native, or Windows/WSL
# + Docker Desktop). No GPU? Skip this and point OpenClaw at any OpenAI-compatible endpoint instead.
#
# Usage:
#   sglang-serve.sh up            # start (or restart) the server   [default]
#   sglang-serve.sh down          # stop + remove the container (frees the GPU — gaming mode)
#   sglang-serve.sh restart       # down then up
#   sglang-serve.sh status        # container + endpoint health
#   sglang-serve.sh logs          # follow logs
#   sglang-serve.sh print         # print the docker command without running it
#
# Configure with flags or env (flags win):
#   --model <hf-id|path>   FAKOLI_MODEL      (default unsloth/Qwen3.6-35B-A3B-NVFP4)
#   --port <n>             FAKOLI_PORT       (default 30000)
#   --ctx <n>              FAKOLI_CTX        (default 32768)
#   --max-running <n>      FAKOLI_MAXREQ     (default 3)
#   --mem-fraction <f>     FAKOLI_MEMFRAC    (default 0.82; lower if you hit OOM)
#   --tp <n>               FAKOLI_TP         (default 1; set 2/4/8 for multi-GPU)
#   --quantization <q>     FAKOLI_QUANT      (default none; e.g. fp8)
#   --kv-cache-dtype <d>   FAKOLI_KVDTYPE    (default fp8_e5m2; "" to disable)
#   --served-name <name>   FAKOLI_SERVED     (default qwen3.6-35b-a3b-local)
#   --image <ref>          FAKOLI_IMAGE      (default lmsysorg/sglang:latest; pin in prod)
#   --name <container>     FAKOLI_NAME       (default sglang)
#   --shm <size>           FAKOLI_SHM        (default 16g)
#   --hf-token <tok>       HUGGING_FACE_HUB_TOKEN  (optional, for gated models)
#   --extra "<args>"       FAKOLI_EXTRA      (extra raw sglang.launch_server args)
set -uo pipefail

ACTION="${1:-up}"; [[ "$ACTION" =~ ^-- ]] && ACTION="up" || shift || true

MODEL="${FAKOLI_MODEL:-unsloth/Qwen3.6-35B-A3B-NVFP4}"
PORT="${FAKOLI_PORT:-30000}"
CTX="${FAKOLI_CTX:-32768}"
MAXREQ="${FAKOLI_MAXREQ:-3}"
MEMFRAC="${FAKOLI_MEMFRAC:-0.82}"
TP="${FAKOLI_TP:-1}"
QUANT="${FAKOLI_QUANT:-}"
KVDTYPE="${FAKOLI_KVDTYPE:-fp8_e5m2}"
SERVED="${FAKOLI_SERVED:-qwen3.6-35b-a3b-local}"
IMAGE="${FAKOLI_IMAGE:-lmsysorg/sglang:latest}"
NAME="${FAKOLI_NAME:-sglang}"
SHM="${FAKOLI_SHM:-16g}"
HF_TOKEN="${HUGGING_FACE_HUB_TOKEN:-}"
EXTRA="${FAKOLI_EXTRA:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL="$2"; shift 2;; --port) PORT="$2"; shift 2;;
    --ctx|--context-length) CTX="$2"; shift 2;; --max-running) MAXREQ="$2"; shift 2;;
    --mem-fraction) MEMFRAC="$2"; shift 2;; --tp) TP="$2"; shift 2;;
    --quantization) QUANT="$2"; shift 2;; --kv-cache-dtype) KVDTYPE="$2"; shift 2;;
    --served-name) SERVED="$2"; shift 2;; --image) IMAGE="$2"; shift 2;;
    --name) NAME="$2"; shift 2;; --shm) SHM="$2"; shift 2;;
    --hf-token) HF_TOKEN="$2"; shift 2;; --extra) EXTRA="$2"; shift 2;;
    -h|--help) sed -n '2,29p' "$0"; exit 0;;
    *) echo "unknown arg: $1"; exit 2;;
  esac
done

need(){ command -v "$1" >/dev/null 2>&1 || { echo "FATAL: $1 not found"; exit 1; }; }

build_cmd() {
  CMD=(docker run -d --name "$NAME" --restart unless-stopped --gpus all --shm-size "$SHM" -p "${PORT}:${PORT}" -v sglang-hf:/root/.cache/huggingface)
  [ -n "$HF_TOKEN" ] && CMD+=(-e "HUGGING_FACE_HUB_TOKEN=$HF_TOKEN")
  CMD+=("$IMAGE" python3 -m sglang.launch_server --model-path "$MODEL" --served-model-name "$SERVED" --context-length "$CTX" --max-running-requests "$MAXREQ" --mem-fraction-static "$MEMFRAC" --tp "$TP" --host 0.0.0.0 --port "$PORT")
  [ -n "$KVDTYPE" ] && CMD+=(--kv-cache-dtype "$KVDTYPE")
  [ -n "$QUANT" ] && CMD+=(--quantization "$QUANT")
  [ -n "$EXTRA" ] && CMD+=($EXTRA)
}

health() {
  curl -fsS --max-time 4 "http://localhost:${PORT}/v1/models" >/dev/null 2>&1
}

case "$ACTION" in
  print)  build_cmd; printf '%q ' "${CMD[@]}"; echo;;
  down)   need docker; docker rm -f "$NAME" 2>/dev/null && echo "stopped + removed $NAME (GPU freed)" || echo "not running";;
  status) need docker; docker ps --filter "name=$NAME" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'; if health; then echo "endpoint: UP (http://localhost:${PORT}/v1)"; else echo "endpoint: not ready"; fi;;
  logs)   need docker; docker logs -f "$NAME";;
  up|restart)
    need docker; need curl
    docker rm -f "$NAME" >/dev/null 2>&1 || true
    build_cmd
    echo "starting $NAME: $MODEL (ctx $CTX, tp $TP, mem $MEMFRAC) on :$PORT"
    "${CMD[@]}" >/dev/null || { echo "FATAL: docker run failed (GPU/Docker available?)"; exit 1; }
    printf "waiting for endpoint"; for i in $(seq 1 120); do health && { echo " — UP"; break; }; printf "."; sleep 5; done
    health && echo "ready: http://localhost:${PORT}/v1  (served as '$SERVED')" || echo "still loading — watch: $0 logs"
    echo "free the GPU for gaming later with:  $0 down";;
  *) echo "unknown action: $ACTION (use up|down|restart|status|logs|print)"; exit 2;;
esac
