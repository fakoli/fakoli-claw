#!/usr/bin/env bash
# Runs on fakoli-dark (inside WSL Ubuntu-24.04). Collects GPU + Docker (SGLang/gaming) state
# the Mac can't reach directly, and PUSHES it to the Mac over the proven reverse SSH
# (`ssh mac`), where collect-metrics.sh / the dashboard consume it.
#
# Why push, not pull: fakoli-dark's Windows OpenSSH (tailnet :22) needs the Mac key in the
# admin-only administrators_authorized_keys (elevation required), and WSL :2222 is LAN-only.
# The reverse path (fakoli-dark -> Mac) already works with no elevation, so we use it.
#
# Schedule on fakoli-dark (Task Scheduler / cron in WSL) every minute for a live dashboard.
set -uo pipefail
OUT=/tmp/fakoli-host-metrics.json
NSMI="$(command -v nvidia-smi.exe || echo /mnt/c/Windows/System32/nvidia-smi.exe)"
DOCKER="$(command -v docker.exe || echo docker.exe)"

GPU="$("$NSMI" --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d '\r')"
NAME="$(printf '%s' "$GPU" | awk -F', *' '{print $1}')"
VUSED="$(printf '%s' "$GPU" | awk -F', *' '{print $2}')"
VTOTAL="$(printf '%s' "$GPU" | awk -F', *' '{print $3}')"
UTIL="$(printf '%s' "$GPU" | awk -F', *' '{print $4}')"
SGLANG="$("$DOCKER" ps --filter name=sglang --format '{{.Names}}' 2>/dev/null | tr -d '\r' | head -1)"
GAMING=true; [ -n "$SGLANG" ] && GAMING=false

printf '{"host":"fakoli-dark","ts":"%s","gpu":{"name":"%s","vram_used_mb":%s,"vram_total_mb":%s,"util_pct":%s},"sglang_container":"%s","gaming_on":%s}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${NAME:-unknown}" "${VUSED:-null}" "${VTOTAL:-null}" "${UTIL:-null}" "${SGLANG:-none}" "$GAMING" > "$OUT"
cat "$OUT"
mkdir -p "$HOME/.ssh"
rsync -tz "$OUT" mac:fakoli-runner/host-metrics.json 2>/dev/null && echo PUSHED || echo "PUSH_FAILED (need 'ssh mac' working from this WSL)"
