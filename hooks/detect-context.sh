#!/usr/bin/env bash
# fakoli-claw SessionStart hook (OpenClaw port of fakoli-flow detect-context).
# Detects project language + whether the fakoli crew is installed, and prints a one-line
# context banner. Reads the config file (fast, no gateway round-trip).
DETECTED_LANG="unknown"
[ -f "Cargo.toml" ] && DETECTED_LANG="Rust"
[ -f "pyproject.toml" ] && DETECTED_LANG="Python"
[ -f "setup.py" ] && DETECTED_LANG="Python"
[ -f "package.json" ] && DETECTED_LANG="TypeScript"
[ -f "tsconfig.json" ] && DETECTED_LANG="TypeScript"

CFG="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/openclaw.json"
CREW_COUNT=0
if [ -f "$CFG" ]; then
  CREW_COUNT=$(grep -cE '"id"[[:space:]]*:[[:space:]]*"fakoli-' "$CFG" 2>/dev/null || echo 0)
fi
if [ "${CREW_COUNT:-0}" -ge 8 ]; then
  CREW_STATUS="fakoli-claw crew (${CREW_COUNT} agents)"
else
  CREW_STATUS="not installed (generic mode)"
fi

echo "[fakoli-flow] Language: ${DETECTED_LANG} | Crew: ${CREW_STATUS} | Skills: brainstorm, plan, execute, verify, finish, quick"
