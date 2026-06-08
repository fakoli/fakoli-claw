# fakoli-claw docs

Start with the architecture, then the build story, then go as deep as you need.

## Read in this order

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — the approach, what it solves, and the implementation. The
  one doc to read if you read one.
- **[THE-BUILD.md](THE-BUILD.md)** — how it actually got built, including every dead end (the dead
  ends are where the design came from).
- **[COMPARISON.md](COMPARISON.md)** — fakoli-claw vs. CrewAI, LangGraph, AutoGen, and the rest, as
  tradeoffs not a leaderboard.
- **[BACKGROUND.md](BACKGROUND.md)** — how each component maps to the writing it came from (the
  Fakoli Style operating model).

## Internals (the multi-detail layer)

- **[internals/wave-engine.md](internals/wave-engine.md)** — dependency→wave, dispatch packets, the
  gate loop, and the two async gotchas that cost real time.
- **[internals/tier-routing.md](internals/tier-routing.md)** — the local/cloud split, why it is
  drawn where it is, bring-your-own-model, and the compaction constraint.
- **[internals/evidence-and-state.md](internals/evidence-and-state.md)** — the evidence gates and the
  durable-state MCP, and why you need both together.

## Operations

- **[HARDENING.md](HARDENING.md)** — making OpenClaw smarter and safer, tradeoff by tradeoff.
- **[BRING-YOUR-OWN-MODEL.md](BRING-YOUR-OWN-MODEL.md)** — swap the local model or endpoint.
- **[NOTES-compaction.md](NOTES-compaction.md)** — the small-context compaction fix (issue #1).
- **[PORT-PLAN.md](PORT-PLAN.md)** · **[STATUS-PHASE-A.md](STATUS-PHASE-A.md)** — the original port plan and Phase A status.

Quickstart, install, and the tier table live in the top-level [README](../README.md).
The evals + health smoke live in [evals/](../evals/README.md).
