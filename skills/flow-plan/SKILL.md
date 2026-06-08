---
name: flow-plan
description: Plan phase — break an approved spec into an intent-driven task list for OpenClaw crew execution. Verify assumptions with a scout sub-agent, map files to owners, write WHAT-not-HOW tasks with acceptance criteria and Depends on, then hand off to flow:execute.
---

# flow:plan — Plan Phase (OpenClaw)

Read an approved spec, verify assumptions with a scout, write an intent-driven task list, and
hand off to `flow:execute`. Plans describe WHAT to achieve — never HOW.

<HARD-GATE>
No implementation code in tasks (no function bodies, test files, step-by-step instructions).
Prescriptive code ages immediately and suppresses agent expertise. Exceptions: schema
migrations, security-critical algorithms, external API contracts, exact config values — add a
"Prescriptive detail" subsection for those, after the intent.
</HARD-GATE>

## Process
1. **Read the spec** (path from brainstorm or the user). Extract goal, requirements, acceptance
   criteria, constraints, out-of-scope. If no spec, ask for it — never plan from memory.
2. **Scout phase.** If the crew is installed (`openclaw agents list | grep fakoli-scout`), spawn:
   `sessions_spawn(agentId="fakoli-scout", task=…)` to verify libraries/APIs exist, find existing
   patterns, and flag partial implementations. Derive a `plan-` run id and inject the absolute
   status path. `sessions_yield`, read findings before writing tasks. If scout finds a broken
   assumption (missing lib/API), flag it to the user before proceeding.
3. **Map files → owners.** One clear responsibility per file; same-file tasks go sequential.
4. **Write intent-driven tasks** in the format below.
5. **Self-review** (5 checks): spec coverage, criteria clarity (confirmable from a command's
   output), dependency correctness (no cycles; same-wave tasks touch different files), agent
   assignment matches work type, code-free.
6. **Save** to `docs/plans/<YYYY-MM-DD>-<feature>.md` (or the path CLAUDE.md specifies).
7. **Hand off:** announce the path and invoke `flow:execute` with it.

## Agent assignment
| Work | Agent |
|---|---|
| New modules / interfaces / types | fakoli-guido |
| Wiring new code into existing systems, integration | fakoli-welder |
| Research / codebase exploration / lib verification | fakoli-scout |
| Plugin manifests / commands / structure | fakoli-smith |
| README / docs / changelogs | fakoli-herald |
| Infra / CI / config | fakoli-keeper |
| Code review (review-only task) | fakoli-critic |
| Test/acceptance validation (review-only task) | fakoli-sentinel |
| Any role when crew absent | main / general |

Tier note: assignment is also a cost lever — welder/smith/scout/herald/keeper run on the local
SGLang tier (free, parallel); guido/critic/sentinel on GPT-5.5. Prefer local specialists for
high-fan-out work.

## Task format
```markdown
# <Feature> — Execution Plan
**Goal:** one sentence.
**Spec:** docs/specs/<date>-<topic>.md
**Language:** TypeScript | Python | Rust  (detected)
**Crew:** fakoli-claw crew (N agents) | generic (crew not installed)

### Task 1: <name>
**Intent:** verb-first outcome, one sentence.
**Acceptance criteria:** 2–5 independently checkable bullets.
**Scope:** exact/file/paths
**Agent:** fakoli-guido | fakoli-welder | … | generic
**Verify:** exact command proving done
**Depends on:** (none) | Task N
```

Crew detection command: `openclaw agents list 2>/dev/null | grep -c '^- fakoli-'` (0 = generic mode).
