# Routing work into fakoli-claw

`fakoli-claw` is a crew, not a reflex. The useful question is not "can an
agent do this?" The useful question is "does this task need the coordination,
review, and durable state that the crew provides?"

This guide is the routing policy for assistants that have both native coding
tools and the fakoli-claw flow skills available. It keeps small work small, and
it makes larger work use the operating model on purpose.

## The rule of thumb

Use the lightest path that preserves the four invariants:

1. **Intent over recipe** — pass goals, acceptance criteria, scope, and verify
   commands, not a line-by-line script.
2. **Specialist over generalist** — assign focused roles with one owner per
   file per wave.
3. **Evidence over claim** — cite command output, artifacts, and gate results.
4. **Durability over chat** — keep plans, run state, scorecards, and decisions
   outside the transcript.

Native Codex is still the right path for many tasks. fakoli-claw earns its keep
when coordination or evidence risk is high enough to justify the machinery.

## Routing table

| Request shape | Route | Why |
|---|---|---|
| Simple Q&A, explanation, summary, or no implementation path | Native assistant | No crew value. |
| Tiny low-risk edit, usually 1-2 files | Native Codex | Fastest path; direct verification is enough. |
| Small change under 3 files that benefits from one specialist and a critic pass | `flow:quick` | Keeps the fast path but adds a review gate. |
| New feature, architecture change, unclear behavior, or unresolved human decisions | `flow:brainstorm` | Write and approve a spec before implementation. |
| Approved spec that needs task decomposition | `flow:plan` | Produces intent-driven tasks with owners, scope, dependencies, and verify commands. |
| Approved plan with multi-file, dependency-ordered, or risky work | `flow:execute` | Runs waves, critic gates, and final sentinel evidence. |
| Existing work needs a readiness answer | `flow:verify` | Produces a fresh evidence scorecard. |
| Verified branch needs merge, PR, keep, or discard decision | `flow:finish` | Re-runs tests and waits for an explicit shipping choice. |

## Stay native when the crew would be ceremony

Stay in native Codex when all of these are true:

- The task is simple, low-risk, and likely touches 1-2 files.
- The current turn can gather context, edit, and verify safely.
- There is no need for sub-agent specialization or durable run state.
- A critic or sentinel gate would not change the decision.

Examples: typo fixes, small docs edits, one-file config tweaks, direct code
questions, or reading a command output and explaining it.

## Use the flow skills as the canonical process

The flow skills are the public interface for the crew:

- `flow:quick` is the bounded fast path: one specialist, one verification pass,
  one critic cycle.
- `flow:brainstorm` resolves the design before code exists. If required human
  decisions are unresolved, route here instead of executing.
- `flow:plan` writes the task map. The plan describes what to achieve, not how
  to write the code.
- `flow:execute` owns dependency waves, `sessions_spawn`, critic gates, and the
  final sentinel run.
- `flow:verify` turns claims into a scorecard.
- `flow:finish` is the shipping gate. It must not auto-merge, auto-push, or
  discard work.

Do not reimplement those workflows in another skill or prompt. A router should
choose the right flow, then let that flow be canonical.

## Direct specialist dispatch is an exception

Directly spawn a single specialist only when the work is narrow, bounded, and a
full flow would add noise. The packet still needs intent, acceptance criteria,
exact scope, a verification command, and a fresh session key.

Role map:

- `fakoli-welder` — integration, wiring, bug fixes, adapting existing code.
- `fakoli-smith` — OpenClaw plugins, commands, manifests, MCP/tool structure.
- `fakoli-scout` — codebase research, library/API verification, pattern
  discovery; no code writes.
- `fakoli-herald` — docs, READMEs, changelogs, release notes, prose cleanup.
- `fakoli-keeper` — CI, infra, config, runtime, environment, scripts.
- `fakoli-guido` — architecture, interfaces, type design, naming, design review.
- `fakoli-critic` — review gate only.
- `fakoli-sentinel` — final evidence and acceptance gate only.

## Do not use fakoli-claw for these

- Sensitive external actions: email, public posts, account changes, payments,
  or messages as a human.
- Emergency fixes where orchestration latency is the main risk.
- Tiny changes where direct editing and direct verification are cleaner.
- Execution work that still depends on unresolved human decisions. Use
  `flow:brainstorm` first.
- High-volume work when the local tier is unhealthy and cloud fallback would
  materially change cost, privacy, or risk.

If the crew or local tier is unavailable, fall back to native Codex for
small/medium work and say that the crew route was skipped. For high-volume or
risky work, ask before routing the job to cloud or general agents.

## Operational checks before a crew run

Before crew-sized work:

1. Inspect repository context and current git state.
2. Confirm fakoli agents exist:

   ```bash
   openclaw agents list 2>/dev/null | grep -c '^- fakoli-'
   ```

3. For large runs, health-check the stack when practical:

   ```bash
   bash ~/ai-code/remote-cowork/fakoli-claw/evals/health-smoke.sh
   ```

4. Avoid dispatching during gateway restart or drain windows.
5. Use a fresh `--session-key` for every orchestrator or direct specialist run.

That last point is not optional. Reusing a default local-agent session can bloat
the local model's transcript past its useful context and trigger compaction
failures.

## What good reporting looks like

When native Codex handles the work, report the files changed and the verification
command normally.

When fakoli-claw handles the work, report:

- route used: `flow:quick`, `flow:brainstorm`, `flow:plan`, `flow:execute`,
  `flow:verify`, `flow:finish`, or direct specialist;
- verification evidence: command, exit status, or artifact summary;
- critic and sentinel results when those gates ran;
- durable plan, run, or status path when relevant;
- skipped verification, blocked evidence, or fallback behavior.

The goal is not more ceremony. The goal is to know when the crew adds value, and
to make the result easier to trust when it does.
