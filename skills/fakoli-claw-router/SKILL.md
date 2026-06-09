---
name: fakoli-claw-router
description: Choose how to handle a new coding request — native for tiny edits vs a fakoli-claw flow for multi-file, risky, design, or explicit crew/Fakoli work.
---

# fakoli-claw-router

Pick the lightest path that still preserves the four invariants. This skill **decides** between
staying native and invoking a `flow:*` skill — it does not re-implement any workflow. Once a route
is chosen, that flow skill is canonical: defer to it.

Full policy and rationale: `docs/ROUTING.md`.

## Who routes

Routing is the job of the **entry / coordinating agent** — usually `main` or `fakoli-orchestrator` —
when it first picks up a request. If you are a **specialist already executing a scoped packet** (you
were handed one task with scope, acceptance criteria, and a verify command), do **not** re-route:
finish the packet and report evidence. If a request handed straight to a specialist genuinely needs a
flow, hand it back to `main` / `fakoli-orchestrator` rather than running a flow yourself.

## Use this skill when

- A coding request could be multi-file, risky, or a refactor.
- It implements an architecture/design, or a design decision is still open.
- The user explicitly asks for the crew, a flow, Fakoli, or "the agents".
- Work should be delegated durably, or needs an evidence / "is it ready to ship?" check.

## Skip this skill when

- You are a specialist mid-packet — complete the scoped task and report; don't re-route.
- The change is a tiny, low-risk edit (1–2 files) you can make and verify directly.
- It's pure Q&A, explanation, or summary with no implementation path.
- It's an emergency fix where orchestration latency is the bigger risk.

## The four invariants

1. **Intent over recipe** — pass goals, acceptance criteria, scope, and verify commands, not a
   line-by-line script.
2. **Specialist over generalist** — focused roles, one owner per file per wave.
3. **Evidence over claim** — cite command output, artifacts, and gate results.
4. **Durability over chat** — keep plans, run state, and scorecards outside the transcript.

## Routing table

| Request shape | Route | Why |
|---|---|---|
| Q&A, explanation, summary; no implementation path | native | No crew value. |
| Tiny low-risk edit, ~1–2 files | native | Fastest path; direct verification is enough. |
| Small change under 3 files that wants one specialist + a review pass | `flow:quick` | Fast path plus a critic gate. |
| New feature, architecture change, unclear behavior, or unresolved human decisions | `flow:brainstorm` | Approve a spec before code. |
| Approved spec needing task decomposition | `flow:plan` | Intent-driven tasks: owners, scope, deps, verify commands. |
| Approved plan; multi-file, dependency-ordered, or risky | `flow:execute` | Waves, critic gates, sentinel evidence. |
| Existing work needs a readiness answer | `flow:verify` | Fresh evidence scorecard. |
| Verified branch needs merge / PR / keep / discard | `flow:finish` | Re-runs tests; waits for an explicit shipping choice. Never auto-merges. |

The flow skills are the canonical process — route to one, then let it run. Do not reimplement a flow
in this skill or in an ad-hoc prompt.

## Direct specialist exception

Spawn a single specialist directly only when the work is narrow, bounded, and a full flow would add
noise. The packet still needs intent, acceptance criteria, exact scope, a verify command, and a
fresh session key.

- `fakoli-welder` — integration, wiring, bug fixes, adapting existing code.
- `fakoli-smith` — OpenClaw plugins, commands, manifests, MCP/tool structure.
- `fakoli-scout` — codebase research, library/API verification; no code writes.
- `fakoli-herald` — docs, READMEs, changelogs, release notes, prose cleanup.
- `fakoli-keeper` — CI, infra, config, runtime, environment, scripts.
- `fakoli-guido` — architecture, interfaces, type design, naming, design review.
- `fakoli-critic` — review gate only.
- `fakoli-sentinel` — final evidence/acceptance gate only.

## Do not route to fakoli-claw for

- Sensitive external actions: email, public posts, account changes, payments, or messages as the user.
- Emergency fixes where orchestration latency is the main risk.
- Tiny changes where direct editing and direct verification are cleaner.
- Execution that still depends on unresolved human decisions — use `flow:brainstorm` first.
- High-volume work when the local tier is unhealthy and cloud fallback would materially change cost,
  privacy, or risk. Ask before routing it to cloud or general agents.

If the crew or local tier is unavailable, fall back to native for small/medium work and say the crew
route was skipped. Still preserve the invariants: scoped ownership, explicit verification, evidence
reporting, and durable notes when useful.

## Operational checks before a crew run

1. Inspect repository context and current git state.
2. Confirm fakoli agents exist: `openclaw agents list 2>/dev/null | grep -c '^- fakoli-'`.
3. For large runs, health-check the stack when practical with the repo's `evals/health-smoke.sh`.
4. Avoid dispatching during a gateway restart or drain window.
5. Use a fresh `--session-key` for every orchestrator or specialist run. Reusing the default
   local-agent session bloats the local model's transcript and triggers compaction failures.

## Reporting

When native handles the work, report files changed and the verify command. When a fakoli route
handles it, also report: the route used; verification evidence (command, exit status, or artifact);
critic/sentinel results when those gates ran; the durable plan/run/status path when relevant; and any
skipped verification or fallback. The goal is better routing and proof, not ceremony.
