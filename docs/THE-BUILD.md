# How fakoli-claw got built

I gave an agent a goal at one in the morning, said "keep working until it's done," and went to bed.
By morning the crew it was coordinating had shipped six phases of a multi-agent system onto my own
hardware. I want to write down how that actually went — not the press-release version, the version
with the dead ends in it — because the dead ends are where the design decisions came from.

## The starting point

The pieces existed before this build. SGLang was already serving Qwen3.6-35B-A3B on the RTX 5090.
The OpenClaw gateway was already running on the Mac mini over Tailscale. Eight specialist prompts and
an orchestrator already existed as `fakoli-claw` agents — Phase A. What did not exist was proof that
the thing actually *ran*: that an orchestrator could dispatch real specialists, in parallel, on the
local model, and that a review gate could stop bad work.

So the work was never "write the agents." It was "prove the coordination," and then "make it
installable, durable, observable, and safe enough to hand to someone else."

## Phase B — proving the wave

The first real test was the keystone, and it failed in an instructive way. The orchestrator config
had an `allowAgents` list in a snippet in the repo — but that snippet had never been applied to the
live gateway. The orchestrator literally could not spawn the crew. The fix was one config write. The
lesson was older than this project: configuration that lives only in a file you intend to apply
someday is not configuration. It is a to-do.

Then the schema fought back. OpenClaw's per-agent `subagents` block accepts only `allowAgents` and
`delegationMode`; the limit fields belong in `agents.defaults.subagents`. Mix them and the whole
config is invalid. I found this the slow way the first time and the fast way every time after, by
dry-running the config set before writing it. Probe before you commit. That is true of schemas and
it is true of production changes.

The wave itself worked, and then it didn't, and then it did — and the failure taught me the most. A
single `openclaw agent` call returns after the orchestrator's *first* yield; the session keeps
running asynchronously as the children announce back. I checked the artifacts too early, saw a
half-finished directory, and nearly concluded the engine was broken. It wasn't. I was reading the
oven before the timer went off. Worse, I launched a second run on the same directory while the first
was still going, and the two waves clobbered each other — which produced a `sentinel: FAIL` that was
entirely my fault and not the crew's. The fix was a unique session key per run. The principle: when
work is asynchronous, you do not check it early, and you do not run two of it in the same room.

The clean run, when it finally came, was worth the trouble. Two specialists built in parallel on the
local model. The critic re-ran the verify command and passed it. The sentinel ran every acceptance
check and wrote a scorecard. `Final verdict: PASS`. The keystone held.

## Phases C through G — making it real

The middle phases were less dramatic and more about turning a demo into a system. The flow pipeline
became six installable skills. The durable-state server got registered as an MCP — which first
required noticing that the Mac did not have `uv` installed at all, and that the config key was
`mcp.servers`, not the `mcpServers` I confidently tried first. Style became a skill. Packaging became
a plugin, a hardened installer with preflight checks, and a bring-your-own-model guide. Ops became an
eval harness, a health smoke test, and a dashboard fed by metrics the GPU host pushes to the Mac.

I will be honest about the one that does not get a clean checkmark. The `/crew` and `/flow` slash
commands fought me for an entire session. The plugin built, installed, and loaded — and then
`register()` threw `Cannot read properties of undefined (reading 'trim')` and I could not see why.
The answer, when I finally read the right doc, was almost insulting in its smallness: an OpenClaw
command handler must return an object `{ text }`, not a bare string, and I was returning the string.
The SDK normalized my result, called `.trim()` on a field that wasn't there, and died. One character
of `{ }` was the difference between a broken plugin and `Commands: crew, flow`. I do not love how
long that took. I do love that the research — reading the docs and the SDK source instead of guessing
— is what finally cracked it.

## What broke, collected in one place

Because the failures are the real documentation:

- A config snippet that was never applied to the live system.
- A schema that splits per-agent and default fields and rejects the mix.
- Async dispatch that returns before the work is done.
- Two runs racing on one directory, producing a false failure.
- A plugin registry that kept a ghost row and invalidated config even after a clean restore.
- A handler returning a string where the SDK wanted an object.
- An eval harness — mine — that named a Python module with a hyphen and failed every import.
- A default session that bloated past the context window and deadlocked compaction.

Every one of those is now a line in the gotchas file, which means the next person — or the next agent
— does not have to rediscover it. That is the actual deliverable. The code is downstream of the
lessons.

## What this unlocks

Three things changed once the gate was trustworthy.

Implementation got cheap. The local builders run on a GPU I already own, in parallel, for free, while
the frontier model is spent only on the work that sets quality. The economics of "just run more
agents" stopped being a cloud bill.

The work got reproducible. A plan, a wave, a scorecard, durable state — a stranger can clone the repo
and run the same wave. That is the difference between a clever demo and a thing other people can use.

And the skill transferred. The hardest problems in this build were not model problems. They were
coordination problems — ordering, ownership, review, evidence, escalation. I have been solving those
problems with humans for twenty years. It turns out the muscle moves over.

The thing I would tell anyone starting this: do not try to make the small model brilliant. Make the
system around it trustworthy, and let the small model be exactly as good as it already is. That is
not a workaround. That is the design.
