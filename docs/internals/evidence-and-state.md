# Internals — evidence gates and durable state

Two of the four invariants — evidence over claim, durability over chat — live here. They are the
parts that keep a parallel crew honest, and they are the parts most agent systems skip.

## Evidence over claim

A claim is "it works." Evidence is an exit code. The distinction is the whole gate.

- **Language verification** runs before the critic, between wave completion and review: TypeScript
  `npx tsc --noEmit`, Python `ruff check . && mypy .`, Rust `cargo check`. There is no point reviewing
  code that does not compile.
- **The critic gate** re-runs the verify commands itself and reports `MUST FIX / SHOULD FIX /
  CONSIDER / NIT`. It does not trust the specialist's word.
- **The sentinel** runs every acceptance check and writes a scorecard where each `PASS` cites the
  exact command and its output. A criterion with no verifiable output is not a `PASS`; it is a
  question for a human.

This earned its place during the build. The sentinel returned `FAIL` on a run the critic had already
passed, because in the gap between the two the file on disk was momentarily inconsistent and the
sentinel ran the command instead of trusting the prior gate. A gate that pattern-matches text waves
through broken work. A gate that runs the command does not. That is not a tuning detail. It is the
reason the local builders can be trusted at all.

## Durability over chat

Coordination runs through the `fakoli-state` MCP server, not through agents reading each other's
free-form notes. Status files have no schema and no ordering guarantees; coordination built on them
races and silently disagrees. The state layer fixes that:

- **22 tools over stdio**, backed by SQLite, covering the full PRD → plan → review → claim → apply
  lifecycle (`init_project`, `get_next_task`, `claim_task`, `submit_completion_evidence`,
  `apply_review_decision`, …).
- **Leased claims with heartbeats.** A claim has an expiry; a dead agent's task is reaped back to the
  ready pool. No task is lost to a crashed worker.
- **Typed events, not prose.** Evidence is captured as structured events in an append-only log, so
  state is a deterministic projection of that log — replayable, auditable, not a transcript you hope
  to parse later.

On OpenClaw it is registered at `.mcp.servers.fakoli-state` (shape `{command, args}` — `type:"stdio"`
is a legacy alias the doctor strips), vendored in-repo at `state/bin/`, and runs under `uv`. The
crew picks up all 22 tools automatically; tier routing is unaffected because the state tools are
model-agnostic.

## Why both, together

Evidence without durability is a gate that forgets. Durability without evidence is a careful record
of unverified claims. You need both: the gate proves each step, and the log remembers what was
proven. That pairing is what lets a wave that ran at one in the morning be trusted at nine — and what
lets the next run build on it instead of relitigating it.
