# fakoli-claw vs. the multi-agent frameworks

Every time I describe fakoli-claw, someone asks why I didn't just use CrewAI. It is a fair question,
and the honest answer is that fakoli-claw is not the same kind of thing. CrewAI, LangGraph, and
AutoGen are libraries you import into a Python program you write and run. fakoli-claw is an operating
model and a config that runs on a personal-assistant runtime I already use every day. Comparing them
is comparing a building code to a framing crew. Related, not interchangeable.

But the question deserves a real answer, tradeoff by tradeoff.

## The frameworks, briefly

The three that matter in 2026, from the current write-ups:

| Framework | Shape | Strength | Cost |
|---|---|---|---|
| **CrewAI** | Role-based crews, little code | Fastest to a working team of agents | Least control over the graph |
| **LangGraph** | Explicit state graph, checkpoints, human-in-the-loop | Most control, most production-mature | Steepest learning curve |
| **AutoGen** | Conversational multi-party agents | Group debate, consensus, dialogue | Less deterministic control flow |
| **Claude Code subagents** | `Agent(subagent_type=…)` inside one CLI | Tight integration, great single-box DX | Cloud-only, one model family |
| **OpenClaw native sub-agents** | `sessions_spawn` on a gateway | Channels, durability, multi-model out of the box | A runtime to operate, not a library |

I am not here to dunk on any of them. CrewAI's role abstraction is genuinely close to what I built —
fakoli-crew started as Claude Code agents that look a lot like CrewAI roles. LangGraph's checkpointed
state graph is the most serious answer to durability in the Python world, and if I were building a
hosted product I would look hard at it. AutoGen's conversational model is the right tool when the
agents genuinely need to argue.

## Where fakoli-claw is actually different

Four differences, and each one is a deliberate tradeoff, not a free win.

**It is local-first and tier-routed.** This is the big one. The high-volume builders run on my own
GPU through an OpenAI-compatible endpoint; only planning and review touch a frontier model. None of
the frameworks above stop you from doing this, but none of them make it the default or the point. For
me it is the entire point: implementation should be free and parallel on hardware I already own, and
frontier spend should go only where it sets the quality ceiling. The cost is operational — I run an
inference server and a GPU that is also a gaming rig. That is a real bill, paid in ops instead of
API credits.

**The review gate runs the command.** Most agent frameworks treat "the critic agent said it's fine"
as the gate. fakoli-claw's critic re-runs the verify command and the sentinel refuses to pass a
criterion without citing fresh command output. The difference sounds academic until a gate that only
reads text waves through code that does not compile — which I have watched happen, and which the
re-run gate caught in this very build. The cost: every gate is another model call and another command
execution. Slower. Worth it.

**State is a typed event log, not a transcript.** Coordination runs through an MCP server backed by
SQLite, with leased claims and captured evidence — not through agents parsing each other's free-form
status files. LangGraph is the only one of the others that takes durability this seriously, and it
does it inside the graph; fakoli-claw does it as a standalone MCP any runtime can call. The cost: a
second service to run and a schema to maintain.

**It rides a runtime instead of being a library.** Because it lives on OpenClaw, it inherits channels
(I can drive a wave from Telegram), always-on gateway behavior, multi-model routing, and sub-agent
spawning without writing any of it. The cost is the inverse of CrewAI's pitch: there is no `pip
install` and a twenty-line script. There is a gateway to operate. I made that trade on purpose,
because I wanted the agents to live where my assistant already lives, not in a script I run by hand.

## When to use what

Let me be blunt, because tradeoff comparisons that refuse to recommend are useless:

- Shipping a hosted product with complex branching state? **LangGraph.**
- Prototyping a team-of-agents workflow this afternoon in Python? **CrewAI.**
- You need agents to debate to a consensus? **AutoGen.**
- You live inside one cloud CLI and want specialists now? **Claude Code subagents.**
- You want a crew that runs mostly on your own GPU, gates work with real evidence, keeps durable
  state, and lives on an assistant you already run — and you are willing to operate that runtime?
  That is the narrow case fakoli-claw was built for. It was built for exactly one person's
  requirements: mine. It generalizes, but it does not pretend to be the default for everyone.

The takeaway is not "fakoli-claw wins." It is that the interesting axis in 2026 is no longer *which
framework orchestrates your agents* — they all do that competently now. The interesting axis is
*where the work runs and how you prove it is correct*. Pick the system whose defaults match the bill
you would rather pay.

---

Sources: framework characterizations drawn from current 2026 comparisons —
[LangGraph vs CrewAI vs AutoGen](https://pecollective.com/blog/ai-agent-frameworks-compared/),
[open-source agent frameworks compared](https://openagents.org/blog/posts/2026-02-23-open-source-ai-agent-frameworks-compared),
[top AI agent frameworks](https://www.turing.com/resources/ai-agent-frameworks).
