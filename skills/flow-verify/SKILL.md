---
name: flow-verify
description: Verify phase — evidence-based validation. Detect language, run the full check suite, dispatch the sentinel against the plan's acceptance criteria, and produce a pass/fail scorecard where every PASS cites fresh command output from this session.
---

# flow:verify — Verify Phase (OpenClaw)

Verification is not an opinion. It is a command you ran, output you read, and a result you can
cite. Every PASS cites fresh output from this session; every FAIL cites what the output showed.

Invoked automatically after `flow:execute`, after `flow:quick`, or manually.

## Steps
1. **Detect language.** `tsconfig.json`/`package.json` → TypeScript; `Cargo.toml` → Rust;
   `pyproject.toml`/`setup.py` → Python. Prefer the most specific. If none, ask.
2. **Run the full suite** (don't split, don't skip on prior pass):
   - TypeScript: `npx tsc --noEmit && bun test`
   - Python: `ruff check . && mypy . && pytest`
   - Rust: `cargo check && cargo test`
   Capture full output, read exit codes, count errors explicitly.
3. **Dispatch sentinel** (if crew installed): `sessions_spawn(agentId="fakoli-sentinel", task=…)`
   with the acceptance criteria + exact verify command per task from the most recent plan
   (`ls docs/plans | sort | tail -1`; if several for today, ask which). Derive a `verify-` run id
   and inject the absolute status path; `sessions_yield`. Quick-mode (no plan) → verify modified
   files against the user's original task description; run id `verify-quick-<YYYYMMDDHHmm>`.
   If crew absent, run the criteria checks yourself with the same evidence gate.
4. **Evidence gate (non-negotiable).** Evidence = exit 0 from the test command, zero errors in
   typecheck, expected value present, file exists. NOT evidence: "should work", stale output, an
   agent's claim without command output, partial output, "looks good". On conflict → mark FAIL,
   don't retry hoping for a different result, don't move the goalposts, report the actual output.
5. **Scorecard.** Per criterion: `[PASS] … Evidence: <cmd> → <output>` or `[FAIL] … Evidence: …`.
   End: `Result: N/M criteria PASS — READY TO SHIP` or `— NOT READY TO SHIP`.
6. **Report.** All PASS → "Run flow:finish to ship." Any FAIL → state what failed and stop; do not
   suggest retrying without fixing the underlying issue.

## Red flags — stop and report
A non-zero exit, any typecheck error line, any failed test, a criterion with no verifiable output,
or a missing plan file outside quick mode.
