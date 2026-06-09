# fakoli-claw evals & health

Focused tooling for measuring and smoke-testing the crew. Run on the gateway host (or via
`ssh mac`); they exercise the live agents on their configured tiers.

## `eval-harness.sh` — repeatable crew score

Scores a crew agent on **6 deterministic coding micro-tasks** (palindrome, fizzbuzz, factorial,
reverse-words, is-prime, count-vowels), each with a real Python verify, and emits a **repeatable
pass-rate + latency per model/config** so model or config swaps become decisions, not vibes (Fakoli
invariant: *evidence over claim*).

```bash
bash evals/eval-harness.sh                    # default: fakoli-welder (SGLang)
FAKOLI_EVAL_AGENT=fakoli-guido bash evals/eval-harness.sh   # score a specific agent
bash evals/eval-harness.sh --compare          # local SGLang (welder) vs cloud GPT-5.5 (guido)
```

Writes `eval-<agent>-<ts>.json`, appends `eval-history.jsonl`, and updates `eval-latest.json` under
`~/fakoli-runner/eval/` (the dashboard reads `eval-latest.json`). `--compare` runs the full suite on
both tiers back to back so you can see the local/cloud quality gap on the same tasks.

Extend by adding `run_task <id> "<prompt>" "<python-assert verify>"` lines inside `run_suite`.

> Note: the per-task scratch module is named `<agent-with-underscores>_<id>.py` — agent ids contain
> hyphens, which are illegal in Python module names, so the harness sanitizes `-` → `_` before import.

## Integration (full-wave) eval

`scripts/run-wave-clean.sh` runs a complete orchestrator wave end to end (2 SGLang specialists in
parallel → critic gate → dependent integration → critic gate → sentinel) and scores the sentinel
scorecard. Use it for the wave path; `eval-harness.sh` scores raw per-agent coding capability.

## `health-smoke.sh` — fast regression check

Verifies the live stack in one shot: SGLang reachable, gateway active, config valid, 9+ fakoli
agents, state MCP configured, the flow-execute skill ready, and a welder SGLang round-trip. Prints
`HEALTH: PASS` / `HEALTH: FAIL`. Use it before/after any config change or model swap.

```bash
bash evals/health-smoke.sh
```

## `routing-eval.sh` — prove the router routes, not just installs

Validates the `fakoli-claw-router` skill (issue #3). Two parts: a **static lint** (deterministic, no
gateway) checking that `SKILL.md` has `name` + a one-line `description` ≤160 chars and that every
`flow:*` route it names maps to a real `skills/flow-*` directory; and **decision cases** that prompt a
router-equipped agent with sample requests (typo → `native`, undecided new feature → `flow:brainstorm`,
small under-3-file change → `flow:quick`, approved plan → `flow:execute`, "ready to ship?" →
`flow:verify`) and check the chosen route token.

```bash
bash evals/routing-eval.sh                 # static lint + decision cases (agent: main)
bash evals/routing-eval.sh --lint-only     # static checks only (CI-friendly, no LLM calls)
FAKOLI_ROUTING_AGENT=fakoli-orchestrator bash evals/routing-eval.sh
```

Decision cases auto-skip when the gateway is unreachable or the agent lacks the router skill, so
`--lint-only` is always safe in CI.

## Why these live in fakoli-claw

This is the repo focused on running the crew on OpenClaw, so the harness that grades it and the smoke
test that guards it belong next to it. They are model- and config-agnostic — repoint the tier
(`docs/BRING-YOUR-OWN-MODEL.md`) and re-run to get a comparable number.
