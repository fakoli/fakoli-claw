---
name: style-ops
description: Manage the Fakoli Style operating-model principles ledger — add principles, advance lifecycle status, validate the ledger, and read the current status report. The canonical source is data/principles.json; docs/fakoli-style.md is a generated projection.
---

# style-ops (OpenClaw)

Operate the Fakoli Style principles ledger. The canonical source of truth is
`data/principles.json` (in this skill dir); `fakoli-style.md` is a generated projection — edit
the data, never the doc, then regenerate.

**Lifecycle rule:** a principle cannot reach `proven` unless its `proof` field resolves to a real
test file on disk. The validator enforces this and exits non-zero on any violation.

The four operating-model invariants the whole fakoli-claw suite preserves:
1. **Intent over recipe** — agents get the goal + an evidence loop, not a rigid script.
2. **Specialist over generalist** — scoped work packets to focused agents.
3. **Evidence over claim** — every result is backed by captured, re-run evidence.
4. **Durability over chat** — state persists; work survives the session.

## Verbs

### add
Append a new principle to `data/principles.json` (defaults to `aspirational`, requires `open_work`).
Then regenerate + validate.

### set-status
Advance a principle's status by editing its entry:
- `asserted`: add `proof` (repo-relative path) + non-empty `embodied_in`.
- `proven`: as asserted, but `proof` must point to a test file (`test_*.py`, `*_test.py`, or under
  a `tests/` dir). The validator rejects a non-test proof on a `proven` entry.

### validate
Run the full ledger validator: schema validity, duplicate IDs, proof-path existence,
embodiment-path existence, the proven-requires-test rule, and staleness of the generated doc.

```bash
# Preferred (PEP 723 inline deps): requires uv
uv run --script scripts/validate.py
# Fallback if uv is absent: plain python3 (ensure jsonschema is available)
python3 scripts/validate.py
```
Exits 0 with `OK: ledger and generated doc are valid and in sync`; exits 1 with `FAIL: <reason>`.

### report
Read principle statuses.
```bash
# Counts by status (no deps beyond jq):
jq '[.principles[].status] | group_by(.) | map({(.[0]): length}) | add' data/principles.json
# Or read the generated table:
cat fakoli-style.md
```

## OpenClaw notes
- Install: `openclaw skills install <this-dir> --agent main --as style-ops --force` (also installed
  for `fakoli-orchestrator` so wave output can be checked against the operating model).
- The `generate.py` / `validate.py` scripts use uv's inline-script deps; if `uv` is not installed,
  run them with `python3` after installing their deps, or `brew install uv`.
- Style applies to crew output by having herald/critic consult these principles when reviewing
  prose and structure (consistent voice/format across the suite).
