---
name: flow-quick
description: Fast path — skip brainstorm/plan/waves for small tasks under 3 files. Estimate scope, dispatch a single specialist (welder by default), run verification, run a one-cycle critic gate, done. Escalates to flow:execute if scope or fixes exceed the limit.
---

# flow:quick — Fast Path (OpenClaw)

One agent, one pass, critic gate, done. For changes too small to justify the full pipeline.

Invocation: `flow:quick "<task>"` (inline task, no spec, no plan, no waves).

## Steps
1. **Estimate scope.** Read the likely file + its importers + test files. If ≥3 files, stop and
   suggest `flow:brainstorm` (offer `--force` to override). Under 3 files → continue.
2. **Detect language** (`tsconfig.json`/`Cargo.toml`/`pyproject.toml`).
3. **Dispatch one specialist** via `sessions_spawn`: welder by default (code/bug/param), guido for
   design/naming, scout for research. Packet = task + scope files + language + "keep it minimal,
   don't refactor unrelated code". If crew absent, do it directly with the same scope constraint.
4. **Verify:** TS `npx tsc --noEmit && bun test`; Py `ruff check . && mypy . && pytest`; Rust
   `cargo check && cargo test`. Read full output + exit code.
5. **Critic gate:** `sessions_spawn(agentId="fakoli-critic", …)` on the modified files → PASS /
   SHOULD FIX / MUST FIX.
6. **Evaluate:**
   - PASS → report files changed + verification + critic PASS. Done (no finish step unless asked).
   - MUST FIX → ONE fix cycle (spawn welder with the exact findings, re-verify, re-critic). Still
     MUST FIX → stop and escalate to `flow:execute`.
   - SHOULD FIX → log suggestions, proceed as PASS.

Quick mode has no spec, no plan, no sentinel — intentionally limited. If a "small" task turns out
to need a design decision, stop and route to `flow:brainstorm`.
