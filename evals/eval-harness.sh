#!/usr/bin/env bash
# Fakoli eval harness — score crew agents on deterministic coding micro-tasks.
# Emits a repeatable pass-rate + latency per model/config; appends eval-history.jsonl.
#
#   bash eval-harness.sh                      # default agent (fakoli-welder, SGLang)
#   FAKOLI_EVAL_AGENT=fakoli-guido bash ...   # score a specific agent
#   bash eval-harness.sh --compare            # local (welder/SGLang) vs cloud (guido/GPT-5.5)
#
# Integration (full-wave) eval: scripts/run-wave-clean.sh runs an orchestrator wave end to end
# and scores the sentinel scorecard — use that for the wave path; this harness scores raw
# per-agent coding capability.
set -uo pipefail
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
OUT="$HOME/fakoli-runner/eval"; mkdir -p "$OUT"

run_suite() {
  local AGENT="$1" MODEL="$2" SAFE="${1//-/_}"
  local TS PASS=0 TOTAL=0 TLAT=0 DETAIL=""
  TS="$(date -u +%Y%m%dT%H%M%SZ)"

  run_task() {
    TOTAL=$((TOTAL+1))
    local id="$1" prompt="$2" verify="$3"
    local f="$OUT/${SAFE}_${id}.py"; rm -f "$f"
    local t0 t1 dur ok
    t0=$(date +%s)
    openclaw agent --agent "$AGENT" --session-key "agent:$AGENT:eval-$TS-$id" --timeout 300 -m "Create the file $f containing Python. $prompt Write only that file; put no prose in the file." >/dev/null 2>&1
    t1=$(date +%s); dur=$((t1-t0)); TLAT=$((TLAT+dur))
    if [ -f "$f" ] && python3 -c "$verify" >/dev/null 2>&1; then ok=1; PASS=$((PASS+1)); echo "  PASS $id (${dur}s)"; else ok=0; echo "  FAIL $id (${dur}s)"; fi
    DETAIL="$DETAIL{\"id\":\"$id\",\"pass\":$ok,\"seconds\":$dur},"
  }

  local M="import sys;sys.path.insert(0,'$OUT');import ${SAFE}_"
  echo "Fakoli eval — agent=$AGENT model=$MODEL  $TS"
  run_task palindrome   "Define is_palindrome(s): True iff s reads the same forwards/backwards ignoring case." "${M}palindrome as m;assert m.is_palindrome('RaceCar') and not m.is_palindrome('abc')"
  run_task fizzbuzz     "Define fizzbuzz(n): 'Fizz' if div by 3, 'Buzz' if by 5, 'FizzBuzz' if both, else str(n)." "${M}fizzbuzz as m;assert m.fizzbuzz(15)=='FizzBuzz' and m.fizzbuzz(3)=='Fizz' and m.fizzbuzz(5)=='Buzz' and m.fizzbuzz(7)=='7'"
  run_task factorial    "Define factorial(n) returning n! for n>=0 with factorial(0)==1." "${M}factorial as m;assert m.factorial(0)==1 and m.factorial(5)==120"
  run_task reversewords "Define reverse_words(s) returning the words of s in reverse order, space-joined." "${M}reversewords as m;assert m.reverse_words('a b c')=='c b a' and m.reverse_words('hi')=='hi'"
  run_task isprime      "Define is_prime(n): True iff n is a prime number (n<2 is not prime)." "${M}isprime as m;assert m.is_prime(7) and not m.is_prime(8) and not m.is_prime(1) and m.is_prime(2)"
  run_task countvowels  "Define count_vowels(s) returning the count of vowels (aeiou, case-insensitive) in s." "${M}countvowels as m;assert m.count_vowels('Hello')==2 and m.count_vowels('xyz')==0"

  local SCORE; SCORE=$(python3 -c "print(round($PASS/$TOTAL,3))" 2>/dev/null || echo 0)
  local RESULT="$OUT/eval-$AGENT-$TS.json"
  printf '{"ts":"%s","agent":"%s","model":"%s","passed":%d,"total":%d,"score":%s,"total_seconds":%d,"tasks":[%s]}\n' \
    "$TS" "$AGENT" "$MODEL" "$PASS" "$TOTAL" "$SCORE" "$TLAT" "${DETAIL%,}" > "$RESULT"
  cat "$RESULT"; cat "$RESULT" >> "$OUT/eval-history.jsonl"; cp "$RESULT" "$OUT/eval-latest.json"
  echo "SUITE_DONE agent=$AGENT score=$SCORE ($PASS/$TOTAL) in ${TLAT}s"
}

if [ "${1:-}" = "--compare" ]; then
  echo "=== TIER COMPARE: local SGLang vs cloud GPT-5.5 ==="
  run_suite "fakoli-welder" "sglang/qwen3.6-35b-a3b-local"
  run_suite "fakoli-guido"  "openai/gpt-5.5"
else
  run_suite "${FAKOLI_EVAL_AGENT:-fakoli-welder}" "${FAKOLI_EVAL_MODEL:-sglang/qwen3.6-35b-a3b-local}"
fi
