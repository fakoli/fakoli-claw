#!/usr/bin/env bash
# Fakoli health smoke — fast regression check of the live stack.
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
FAIL=0
chk(){ if eval "$2" >/dev/null 2>&1; then echo "  [ok]   $1"; else echo "  [FAIL] $1"; FAIL=1; fi; }
echo "Fakoli health smoke — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
SGLANG_URL="${FAKOLI_SGLANG_URL:-http://100.87.34.66:30000}"
chk "SGLang reachable ($SGLANG_URL)" "curl -fsS --max-time 5 $SGLANG_URL/v1/models"
chk "gateway active"                  "openclaw gateway status 2>&1 | grep -q 'state active'"
chk "config valid"                    "openclaw config validate 2>&1 | grep -qi 'valid'"
chk "9+ fakoli agents"                "[ \$(openclaw agents list 2>/dev/null | grep -c '^- fakoli-') -ge 9 ]"
chk "state MCP configured"            "jq -e '.mcp.servers.\"fakoli-state\"' \$HOME/.openclaw/openclaw.json"
chk "flow-execute skill ready"        "openclaw skills list --agent fakoli-orchestrator 2>/dev/null | grep -q flow-execute"
echo "  welder smoke (SGLang round-trip)..."
if openclaw agent --agent fakoli-welder --timeout 180 -m 'Reply with exactly: SMOKE-OK' 2>/dev/null | grep -q 'SMOKE-OK'; then
  echo "  [ok]   welder responded SMOKE-OK"
else
  echo "  [FAIL] welder smoke"; FAIL=1
fi
if [ "$FAIL" = 0 ]; then echo "HEALTH: PASS"; else echo "HEALTH: FAIL"; fi
