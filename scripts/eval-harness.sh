#!/usr/bin/env bash
# Fakoli eval harness — score a crew agent on deterministic coding micro-tasks.
# Emits a repeatable pass-rate + latency per model/config; appends eval-history.jsonl.
# Usage: FAKOLI_EVAL_AGENT=fakoli-welder bash eval-harness.sh
set -uo pipefail
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
AGENT="${FAKOLI_EVAL_AGENT:-fakoli-welder}"
MODEL="${FAKOLI_EVAL_MODEL:-sglang/qwen3.6-35b-a3b-local}"
OUT="$HOME/fakoli-runner/eval"; mkdir -p "$OUT"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
PASS=0; TOTAL=0; TLAT=0; DETAIL=""

run_task() {
  TOTAL=$((TOTAL+1))
  local id="$1" prompt="$2" verify="$3"
  local f="$OUT/$id.py"; rm -f "$f"
  local t0 t1 dur ok
  t0=$(date +%s)
  openclaw agent --agent "$AGENT" --timeout 300 -m "Create the file $f containing Python. $prompt Write only that file; put no prose in the file." >/dev/null 2>&1
  t1=$(date +%s); dur=$((t1-t0)); TLAT=$((TLAT+dur))
  if [ -f "$f" ] && python3 -c "$verify" >/dev/null 2>&1; then ok=1; PASS=$((PASS+1)); echo "  PASS $id (${dur}s)"; else ok=0; echo "  FAIL $id (${dur}s)"; fi
  DETAIL="$DETAIL{\"id\":\"$id\",\"pass\":$ok,\"seconds\":$dur},"
}

echo "Fakoli eval — agent=$AGENT model=$MODEL  $TS"
run_task palindrome "Define is_palindrome(s) returning True iff s reads the same forwards and backwards, ignoring case." "import sys;sys.path.insert(0,'$OUT');import palindrome as m;assert m.is_palindrome('RaceCar') and not m.is_palindrome('abc')"
run_task fizzbuzz "Define fizzbuzz(n): 'Fizz' if divisible by 3, 'Buzz' if by 5, 'FizzBuzz' if both, else str(n)." "import sys;sys.path.insert(0,'$OUT');import fizzbuzz as m;assert m.fizzbuzz(15)=='FizzBuzz' and m.fizzbuzz(3)=='Fizz' and m.fizzbuzz(5)=='Buzz' and m.fizzbuzz(7)=='7'"
run_task factorial "Define factorial(n) returning n! for n>=0 with factorial(0)==1." "import sys;sys.path.insert(0,'$OUT');import factorial as m;assert m.factorial(0)==1 and m.factorial(5)==120"

SCORE=$(python3 -c "print(round($PASS/$TOTAL,3))" 2>/dev/null || echo 0)
RESULT="$OUT/eval-$TS.json"
printf '{"ts":"%s","agent":"%s","model":"%s","passed":%d,"total":%d,"score":%s,"total_seconds":%d,"tasks":[%s]}\n' \
  "$TS" "$AGENT" "$MODEL" "$PASS" "$TOTAL" "$SCORE" "$TLAT" "${DETAIL%,}" > "$RESULT"
cat "$RESULT"
cat "$RESULT" >> "$OUT/eval-history.jsonl"
cp "$RESULT" "$OUT/eval-latest.json"
echo "EVAL_DONE score=$SCORE ($PASS/$TOTAL) in ${TLAT}s"
