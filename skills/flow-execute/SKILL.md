---
name: flow-execute
description: Execute phase — wave-based crew dispatch on OpenClaw with critic gates and evidence-based verification. Load an intent-driven plan, group tasks into dependency waves, sessions_spawn specialists in parallel per wave (local SGLang tier), run a critic gate after every code wave, then a sentinel evidence gate.
---

# flow:execute — Execute Phase (OpenClaw)

Load an intent-driven plan, group tasks into dependency-ordered **waves**, dispatch
specialist sub-agents in parallel within each wave via `sessions_spawn`, run a mandatory
**critic gate** between waves, then dispatch the **sentinel** for an evidence-based final
sign-off. This is the OpenClaw port of fakoli-flow `execute`; the canonical driver is the
`fakoli-orchestrator` agent.

<HARD-GATE>
The critic gate runs after EVERY wave that writes code. It cannot be skipped. Proceed only
when the critic returns PASS (or SHOULD FIX / NIT with no MUST FIX).
</HARD-GATE>

## OpenClaw mapping (how this differs from the Claude Code original)

| Claude Code | OpenClaw |
|---|---|
| `Agent(subagent_type="fakoli-crew:welder", prompt=…)` | `sessions_spawn(agentId="fakoli-welder", task=…)` then `sessions_yield` |
| `claude plugin list \| grep fakoli-crew` | `openclaw agents list \| grep '^- fakoli-'` |
| model tier picked per dispatch | **tiers are config-routed already**: welder/smith/scout/herald/keeper → `sglang/qwen3.6-35b-a3b-local`; guido/critic/sentinel/orchestrator → `openai/gpt-5.5` |
| each agent has fresh context | same — each spawned session is isolated; pass only the scoped packet |

**Spawn depth:** the human/main agent spawns `fakoli-orchestrator` (depth 1); the orchestrator
spawns specialists (depth 2). `agents.defaults.subagents.maxSpawnDepth` must be ≥ 2 (it is).

**Async yield (important):** `sessions_spawn` is non-blocking; children **announce** results back
to the parent session, and `sessions_yield` awaits them. A single CLI turn returns after the
first yield resolves — the orchestrator session then continues across turns as later children
announce. When driving from a script, **poll the scratch dir for the terminal artifact**
(the sentinel scorecard) rather than assuming one CLI turn finishes the whole wave.

## Process

1. **Load the plan.** Read it fully. Extract each task's Intent, Acceptance, Scope, Agent,
   Verify, and `Depends on:`. If the file is missing, ask for the path.

2. **Derive the run id + scratch root.** `run-id = <plan-basename>-<YYYYMMDDHHmm UTC>`.
   Scratch root (gitignored, outside VCS — fakoli-style P10): `<project>/.fakoli/runs/<run-id>/`.
   Use ABSOLUTE paths; inject each agent's own status-file path into its packet. Log it once.

3. **Detect specialists.** `openclaw agents list`. If the `fakoli-*` crew is present, dispatch to
   `fakoli-<role>`. If not, fall back to the `main` agent / `general` for every role (the pipeline
   still runs; you lose specialization). Log which mode you're in.

4. **Group into waves** from `Depends on:` — no deps → Wave 1; deps all in Wave N → Wave N+1.
   Same-wave tasks are independent and must target non-overlapping files.

5. **For each wave:**
   - **Dispatch in parallel:** one `sessions_spawn` per task, each carrying ONLY its scoped packet
     (Intent, Acceptance verbatim, Scope = exact files, Upstream context = prior waves' Decisions,
     Verify command, and the absolute status-file path to write). Then `sessions_yield`.
   - **Collect status files** from the scratch root. Confirm each is `done`/`COMPLETE`. Surface any
     `BLOCKED`/`NEEDS_REVIEW` to the user — never swallow them.
   - **Language verification** before the gate: TypeScript `npx tsc --noEmit`; Python
     `ruff check . && mypy .`; Rust `cargo check`. On failure, dispatch welder to fix, re-run.
   - **Critic gate (non-negotiable):** `sessions_spawn(agentId="fakoli-critic", …)` with the wave's
     modified-file list + the relevant acceptance criteria. The critic re-runs the verify commands
     itself (evidence over claim) and returns MUST FIX / SHOULD FIX / CONSIDER / NIT.
     - No MUST FIX → proceed.
     - MUST FIX → fix cycle: spawn the owning specialist with the exact findings, re-spawn critic,
       max 3 cycles, then escalate to the user.

6. **After the final wave: sentinel.** `sessions_spawn(agentId="fakoli-sentinel", …)`. Sentinel runs
   EVERY plan Verify command, quotes exit codes + output, and writes a pass/fail scorecard to
   `<scratch>/sentinel-final.status`. **Confirm the prior wave's edits are on disk before dispatching
   sentinel** (avoid the read-before-write race). Sentinel does not trust prior claims.

7. **Report.** Waves run, tasks completed, files modified, critic findings (MUST FIX resolved /
   SHOULD FIX logged), sentinel verdict. End with `WAVE-OK` only if the sentinel scorecard passes all
   acceptance criteria, else `WAVE-BLOCKED: <reason>`.

## Packet template (per spawned task)

```
Task: <name>
Intent: <one sentence, from plan>
Acceptance criteria: <verbatim from plan>
Scope: <exact files>
Upstream context: <Decisions extracted from prior-wave status files>
Verify: <exact command from plan>
Write your status file to: <abs scratch>/<role>-<task>.status  (status: IN_PROGRESS at start, done when all criteria met + Verify passes)
```

## Notes
- Status-file format + reading/writing rules: see `references/status-protocol.md`.
- Wave-assignment DSL + capability matrix: `references/wave-engine-ref.md`.
- Keep packets tight and tool surface minimal (Fakoli: intent over recipe, specialist over generalist,
  evidence over claim, durability over chat).
