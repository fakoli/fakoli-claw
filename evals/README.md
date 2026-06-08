# fakoli-claw evals & health

Focused tooling for measuring and smoke-testing the crew. Run on the gateway host (or via
`ssh mac`); they exercise the live agents on their configured tiers.

## `eval-harness.sh` — repeatable crew score

Scores a crew agent on deterministic coding micro-tasks (palindrome / fizzbuzz / factorial), each
with a real verify command, and emits a **repeatable pass-rate + latency per model/config** so model
or config swaps become decisions, not vibes (Fakoli invariant: *evidence over claim*).

```bash
FAKOLI_EVAL_AGENT=fakoli-welder bash evals/eval-harness.sh
```

Writes `eval-<ts>.json`, appends `eval-history.jsonl`, and updates `eval-latest.json` under
`~/fakoli-runner/eval/` (the dashboard reads `eval-latest.json`). Baseline: `fakoli-welder` on
`sglang/qwen3.6-35b-a3b-local` → **3/3** in ~53s.

Extend by adding `run_task <id> "<prompt>" "<python-assert verify>"` lines; point
`FAKOLI_EVAL_AGENT` at any agent to compare tiers.

## `health-smoke.sh` — fast regression check

Verifies the live stack in one shot: SGLang reachable, gateway active, config valid, 9+ fakoli
agents, state MCP configured, the flow-execute skill ready, and a welder SGLang round-trip. Prints
`HEALTH: PASS` / `HEALTH: FAIL`. Use it before/after any config change or model swap.

```bash
bash evals/health-smoke.sh
```

## Why these live in fakoli-claw

This is the repo focused on running the crew on OpenClaw, so the harness that grades it and the smoke
test that guards it belong next to it. They are model- and config-agnostic — repoint the tier
(`docs/BRING-YOUR-OWN-MODEL.md`) and re-run to get a comparable number.
