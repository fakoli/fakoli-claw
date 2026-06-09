#!/usr/bin/env bash
# Fakoli routing eval — prove the fakoli-claw-router skill routes correctly, not just that it installs.
#
# Two parts:
#   1) Static lint (deterministic, no gateway): SKILL.md exists; frontmatter name + description are
#      present; the description is a single line <=160 chars; and every `flow:*` route the skill names
#      maps to a real skills/flow-* directory (no dangling routes).
#   2) Decision cases (need a reachable gateway + an agent that has the router skill): prompt the agent
#      with sample requests and check it returns the expected route token. Auto-skips if the gateway is
#      unreachable or the agent lacks the router.
#
#   bash evals/routing-eval.sh                              # decision agent: main
#   FAKOLI_ROUTING_AGENT=fakoli-orchestrator bash evals/routing-eval.sh
#   bash evals/routing-eval.sh --lint-only                 # static checks only (CI-friendly, no LLM)
set -uo pipefail
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPO_DIR/skills/fakoli-claw-router/SKILL.md"
AGENT="${FAKOLI_ROUTING_AGENT:-main}"
LINT_ONLY=0; [ "${1:-}" = "--lint-only" ] && LINT_ONLY=1

fail=0
echo "== routing-eval: static lint =="
if [ -f "$SKILL" ]; then echo "  [ok]   SKILL.md present"; else echo "  [FAIL] SKILL.md missing: $SKILL"; exit 1; fi

name="$(awk -F': *' '/^name:/{print $2; exit}' "$SKILL")"
[ "$name" = "fakoli-claw-router" ] && echo "  [ok]   name=$name" \
  || { echo "  [FAIL] name should be fakoli-claw-router (got: '$name')"; fail=1; }

desc="$(awk '/^description:/{sub(/^description:[ ]*/,""); print; exit}' "$SKILL")"
if [ -z "$desc" ]; then
  echo "  [FAIL] description missing"; fail=1
else
  len=${#desc}
  if [ "$len" -le 160 ]; then echo "  [ok]   description is one line, $len chars (<=160)"; \
    else echo "  [FAIL] description $len chars (>160 — OpenClaw best practice)"; fail=1; fi
fi

routes="$(grep -oE 'flow:(quick|brainstorm|plan|execute|verify|finish)' "$SKILL" | sort -u)"
if [ -z "$routes" ]; then echo "  [FAIL] skill names no flow:* routes"; fail=1; fi
for r in $routes; do
  s="flow-${r#flow:}"
  if [ -d "$REPO_DIR/skills/$s" ]; then echo "  [ok]   route $r -> skills/$s"; \
    else echo "  [FAIL] route $r has no skills/$s directory"; fail=1; fi
done

if [ "$fail" = 0 ]; then echo "  static lint: PASS"; else echo "  static lint: FAIL"; exit 1; fi
if [ "$LINT_ONLY" = 1 ]; then echo "routing-eval: lint-only done"; exit 0; fi

# ---- decision cases (need gateway + router-equipped agent) ----
if ! openclaw gateway status >/dev/null 2>&1; then
  echo "== routing-eval: decision cases SKIPPED (gateway not reachable) =="; exit 0
fi
if ! openclaw skills list --agent "$AGENT" 2>/dev/null | grep -q fakoli-claw-router; then
  echo "== routing-eval: decision cases SKIPPED (agent '$AGENT' has no fakoli-claw-router; run install.sh) =="; exit 0
fi

echo "== routing-eval: decision cases (agent=$AGENT) =="
TS="$(date -u +%Y%m%dT%H%M%SZ)"; PASS=0; TOTAL=0
KNOWN='flow:(quick|brainstorm|plan|execute|verify|finish)|native'

case_check() {
  TOTAL=$((TOTAL+1))
  local id="$1" expect="$2" req="$3" out got
  out="$(openclaw agent --agent "$AGENT" --session-key "routing-eval-$TS-$id" --timeout 120 -m \
    "Use the fakoli-claw-router skill to route this request. Reply with ONLY one route token and nothing else, chosen from: native, flow:quick, flow:brainstorm, flow:plan, flow:execute, flow:verify, flow:finish. Request: $req" 2>/dev/null)"
  got="$(printf '%s' "$out" | tr 'A-Z' 'a-z' | grep -oE "$KNOWN" | head -1)"
  if [ "$got" = "$expect" ]; then PASS=$((PASS+1)); echo "  PASS $id -> $got"; \
    else echo "  FAIL $id (expected $expect, got '${got:-none}')"; fi
}

case_check typo        native          "Fix a single typo in the README heading."
case_check newfeature  flow:brainstorm "Add a brand-new authentication subsystem spanning about 12 files with a DB migration; the design is not decided yet."
case_check smallchange flow:quick      "Add a --verbose flag to the CLI plus one test. Under three files, no design decision."
case_check execplan    flow:execute    "Execute the already-approved plan at plan.md; it is multi-file and dependency-ordered."
case_check readiness   flow:verify     "Is the billing branch done and safe to ship?"

echo "routing-eval: $PASS/$TOTAL decision cases passed"
[ "$PASS" = "$TOTAL" ] && exit 0 || exit 1
