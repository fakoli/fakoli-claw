# fakoli-claw — Architecture

A 35-billion-parameter model running on the RTX 5090 in my office will confidently hand you a
function that does not compile. I know, because I watched it happen — over and over — until I
stopped asking it to behave like a frontier model and started asking it to behave like a junior
engineer on a well-run team.

That sentence is the whole architecture. Everything below is the mechanism that makes it true.

## What this solves

The problem with a lone local model is not that it is dumb. It is that it is *unsupervised*. Give a
small model a vague goal and the whole codebase, and it will wander. Give it a tight task, the exact
files it owns, and a command that proves whether it succeeded, and it does fine work — the same way a
junior does fine work when the task is scoped and someone reviews the result.

So the problem fakoli-claw solves is not "make the local model smarter." It is **coordination**. And
the thing about coordination is that we already know how to do it, because we have been coordinating
humans on shared codebases for decades. The problems of multi-agent work are the problems of
multi-team work. File ownership is code ownership. Wave execution is sprint sequencing. A code review
gate is a code review gate. I did not invent any of this. I ported it.

Concretely, fakoli-claw answers four questions that break first when you run real multi-agent work on
your own hardware:

- **Who does what?** A crew of nine specialists, each scoped to one kind of work.
- **In what order?** A wave engine that derives dependencies and runs independent work in parallel.
- **How do we know it worked?** A critic that re-runs the verify command and a sentinel that refuses
  to rubber-stamp a claim.
- **What survives the session?** Durable state in SQLite, exposed over MCP, so work outlives the chat.

## The approach — four invariants

fakoli-claw is not a toolkit you import. It is an operating model, and it holds four invariants. They
are not suggestions. They are the load-bearing walls.

1. **Intent over recipe.** An agent gets the goal and an evidence loop, never a line-by-line script.
   A plan that prescribes the code ages the moment the codebase moves, and it suppresses the one
   thing the model is actually good at — reading the real files and adapting.
2. **Specialist over generalist.** Scoped work packets go to focused agents. A generalist asked to do
   everything does everything adequately and nothing well. A welder that only ever integrates gets
   good at integrating.
3. **Evidence over claim.** Every result is backed by captured, re-run evidence. "It works" is not a
   result. An exit code is a result. The critic does not trust the welder's word; it runs the command
   again.
4. **Durability over chat.** State persists outside the conversation. The transcript is not the
   system of record — the SQLite event log is.

Read those four again as management principles instead of engineering ones. They are the same. That
is not a coincidence; it is the entire bet.

## The architecture

### The crew — nine roles, two tiers

Nine agents, each a role with a system prompt, a model, and a tool surface:

- **fakoli-orchestrator** — runs the waves. Dispatches, gates, synthesizes. Does no specialist work itself.
- **fakoli-guido** — architecture, interfaces, type design.
- **fakoli-scout** — research and codebase mapping. Writes no code.
- **fakoli-smith** — plugin and module engineering.
- **fakoli-welder** — integration; wiring new code into old without breaking callers.
- **fakoli-herald** — documentation.
- **fakoli-keeper** — infrastructure, CI, config.
- **fakoli-critic** — the review gate.
- **fakoli-sentinel** — final evidence-based QA.

The roles split across two tiers, and the split is the most important configuration decision in the
system. The high-volume builders — welder, smith, scout, herald, keeper — run **local** on the RTX
5090 through SGLang. The roles that set the quality ceiling for the whole run — orchestrator, guido,
critic, sentinel — route to **GPT-5.5** in the cloud.

Here is the reasoning, stated as a tradeoff because every architecture decision is one: planning,
architecture, and the review gates decide whether the entire wave is good or garbage. That is worth
frontier-model money. Implementation, research, and docs are high-fan-out, repetitive, and cheap to
verify — that is exactly the work a local model should do for free while the GPU is mine anyway. The
assignment is pure config. If you disagree with my split, change one field.

### The wave engine

A plan is a list of tasks, and each task can declare `Depends on:`. The orchestrator reads those
declarations and computes waves: everything with no unmet dependency runs now, in parallel; the rest
waits for its inputs. This is the part people overcomplicate. It is topological sort, and it is the
same thing a tech lead does at sprint planning when they say "these three can go in parallel, that
one waits for the API."

Each agent in a wave gets **only its own packet** — intent, acceptance criteria, scope, the upstream
decisions it needs, and the exact verify command. Not the whole plan. Not the other agents' history.
The same discipline that keeps two humans from editing the same Terraform module at once keeps two
agents from clobbering each other: one owner per file, per wave.

### The gates

After every wave that writes code, the critic reviews it. Not by reading and nodding — by re-running
the verify commands itself and reporting `MUST FIX / SHOULD FIX / CONSIDER / NIT`. A `MUST FIX`
blocks the wave and sends a fix back to the owning specialist, bounded to three cycles before it
escalates to a human. After the final wave, the sentinel runs every acceptance check and writes a
scorecard where every `PASS` cites a command and its output.

I want to be honest about why this matters more than it looks. During the build, the sentinel
returned `FAIL` on a run where the critic had already said `PASS` — because between the two gates the
file on disk was momentarily inconsistent, and the sentinel ran the command instead of trusting the
claim. That is the invariant earning its keep. A gate that only pattern-matches text is a gate that
waves through broken work. A gate that runs the command is a gate.

### Durable state

The crew coordinates through the `fakoli-state` MCP server — 22 tools over stdio, backed by SQLite,
exposing the full PRD → plan → review → claim → apply lifecycle. Claims have leases and heartbeats so
a dead agent's task returns to the pool. Evidence is captured as typed events, not free text. This is
the layer almost nobody builds, and it is the layer that breaks first when you run real parallel
work, because status files have no schema and no ordering guarantees — coordination built on them
races and silently disagrees.

## The implementation — porting onto OpenClaw

fakoli-claw runs on OpenClaw, a personal-assistant runtime, rather than a Python agent framework.
That choice has consequences, and they are mostly upside: the gateway, channels, sub-agent spawning,
and tool surface already exist and are maintained by someone else. The mapping:

- Each crew role → an entry in `agents.list[]` with a model (the tier) and a workspace prompt.
- Wave dispatch → the `sessions_spawn` / `sessions_yield` sub-agent tools; children announce results
  back up the chain (`maxSpawnDepth: 2` = main → orchestrator → specialists).
- The flow pipeline → six OpenClaw skills (`flow-brainstorm/plan/execute/verify/finish/quick`).
- Durable state → an MCP server registered at `mcp.servers.fakoli-state`.
- `/crew` and `/flow` → a compiled plugin (`index.ts` → `dist/index.mjs`) registering the commands.

One hard-won detail belongs in the architecture, not a footnote: a ~32K-context local model
**deadlocks on turn-1 compaction** under OpenClaw's default token reserve, because the floor (20000)
leaves too little usable window. The fix is global — `reserveTokens: 8192`, `reserveTokensFloor: 0` —
and without it the local tier does not run at all. The whole local-first thesis rested on a
two-line config change. I am still a little annoyed about how long that took to find.

## What it costs

I will not pretend this is free. The honest tradeoffs:

- **Operational surface.** You now run an inference server, a gateway, a tailnet, and a GPU that is
  also a gaming machine. That is real ops. The toggle that frees the GPU for games is not a
  convenience; it is a requirement I had to design around.
- **Latency vs. control.** Routing review to a frontier model adds network latency and cost to every
  wave. I pay it because the gate quality is what makes the local builders trustworthy.
- **The small-model ceiling.** A 35B model is good at scoped tasks and bad at sprawling ones. The
  whole design is an admission of that limit, not a denial of it.

## What it unlocks

When the gate is trustworthy, the local builders become trustworthy, and once that is true a few
things change at once. Implementation becomes effectively free and parallel — the GPU is already
paid for. The frontier model is spent only where it sets quality, not where it does typing. And the
work is reproducible: a plan, a wave, a scorecard, durable state, and a stranger can run the same
wave from the README.

The deeper unlock is the one I keep coming back to. Twenty years of coordinating engineers turned out
to be the most transferable skill I had for coordinating agents — more transferable than any
prompt-engineering trick. If you can run a team, you can run a crew. The mechanism is different. The
job is the same.
