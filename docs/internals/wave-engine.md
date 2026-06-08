# Internals — the wave engine

The wave engine is the part that turns a flat list of tasks into ordered, parallel, gated work. It
lives in the `fakoli-orchestrator` prompt and the `flow-execute` skill. This is how it actually runs
on OpenClaw, including the parts that bit me.

## Dependency → wave

Each task in a plan may declare `Depends on:`. Assignment is a topological sort:

- No dependencies → Wave 1.
- Depends only on Wave-N tasks → Wave N+1.
- Same-wave tasks are independent and must touch non-overlapping files (one owner per file per wave).

That last rule is not a nicety. It is the exact discipline that stops two humans from editing one
Terraform module at once, applied to agents. Break it and two specialists in the same wave race on a
file and you get a corrupt merge — the agent version of a bad rebase.

## The dispatch packet

Each spawned specialist receives only its own packet, never the whole plan or another agent's
history:

- **Intent** — the outcome, one sentence.
- **Acceptance criteria** — verbatim from the plan.
- **Scope** — exact file paths it owns.
- **Upstream context** — decisions extracted from prior-wave status, not raw transcripts.
- **Verify** — the exact command that proves done.
- **Status path** — the absolute scratch file to write (`.fakoli/runs/<run-id>/`).

Tight packets are why a small local model performs. A 35B model handed one scoped task with a verify
command behaves; the same model handed the whole repo wanders.

## Spawn mechanics on OpenClaw

- `sessions_spawn(agentId, model, task)` is non-blocking; `sessions_yield` awaits announces.
- `maxSpawnDepth: 2` means: human/main (0) → orchestrator (1) → specialists (2).
- Limits live in `agents.defaults.subagents` (`maxConcurrent`, `maxChildrenPerAgent`, `runTimeoutSeconds`);
  the per-agent block holds only `allowAgents` + `delegationMode`. Mixing them fails validation.

## The two gotchas that cost real time

**Async return.** A single `openclaw agent -m` call returns after the orchestrator's *first*
`sessions_yield`. The session then keeps running as children announce. Do not read artifacts
immediately — poll the scratch dir for the sentinel scorecard (or a `.done` sentinel). The clean
demo runner (`scripts/run-wave-clean.sh`) does exactly this: launch, then poll to completion.

**Session collision.** Two orchestrator runs on the default session key (`agent:fakoli-orchestrator:main`)
collide on the lane (`lane wait exceeded`) and, if pointed at the same project dir, clobber each
other — which once produced a false `sentinel: FAIL`. Use a unique `--session-key` per run.

## The gate loop

After every code wave: collect modified files from status → run language verification → spawn
`fakoli-critic` with the file list + acceptance criteria. The critic re-runs the verify commands and
returns severity levels. `MUST FIX` enters a fix cycle (max 3, then escalate to a human — bounded
refinement, never an open loop). After the final wave, `fakoli-sentinel` runs every check and writes
a scorecard that cites command output for each `PASS`.

See `agents/_references/wave-patterns.md` for the full wave taxonomy and worked examples, and
`skills/flow-execute/references/status-protocol.md` for the status-file contract.
