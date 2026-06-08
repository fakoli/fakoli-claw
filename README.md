# fakoli-claw

**The Fakoli plugin suite, ported to [OpenClaw](https://openclaw.ai) — a local-first, tier-routed multi-agent coding crew.**

`fakoli-claw` brings the *Fakoli style* — a crew of specialist AI agents driven by intent, evidence, and durable state — to the OpenClaw runtime. High-volume specialist work runs on **your own GPU** through an OpenAI-compatible endpoint (SGLang / vLLM / Ollama); planning and review route to a frontier model. The split is pure config and trivially re-tunable.

## What's inside

- **The crew** — 9 agents installed as OpenClaw `agents.list[]`: `fakoli-orchestrator` + 8 specialists (guido architect, critic reviewer, scout researcher, smith plugin-eng, welder integration, herald docs, keeper infra, sentinel QA).
- **The wave engine** — the orchestrator dispatches specialists in parallel **waves** via `sessions_spawn` + `sessions_yield`, runs a **critic gate** after every code wave (it re-runs the verify commands — evidence over claim), and finishes with a **sentinel** evidence scorecard.
- **The flow pipeline** — six OpenClaw skills: `flow-brainstorm → flow-plan → flow-execute → flow-verify → flow-finish` (+ `flow-quick` fast path).
- **Durable state** — the `fakoli-state` FastMCP server (22 tools) exposes the PRD → plan → review → claim → apply lifecycle as MCP tool calls, backed by SQLite.
- **Style** — `style-ops` maintains the operating-model principles ledger.
- **Plugin shell** — `index.ts` registers the `/crew` and `/flow` menu commands + a SessionStart context banner.

## Tier routing (default)

| Tier | Model | Agents |
|---|---|---|
| Cloud (quality-critical) | `openai/gpt-5.5` | orchestrator, guido, critic, sentinel |
| Local GPU (parallel, high-volume) | `sglang/qwen3.6-35b-a3b-local` | welder, smith, scout, herald, keeper |

Override per install with `FAKOLI_CLOUD_MODEL` / `FAKOLI_LOCAL_MODEL`. See [docs/BRING-YOUR-OWN-MODEL.md](docs/BRING-YOUR-OWN-MODEL.md).

## Install (one command)

```bash
git clone https://github.com/fakoli/fakoli-claw && cd fakoli-claw
bash scripts/install.sh           # crew agents + subagents + compaction + flow/style skills
bash scripts/install-state.sh     # optional: fakoli-state MCP (installs uv, registers the server)
```

`install.sh` runs preflight checks (SGLang reachable? gateway up? models present? uv?), registers the crew tier-routed, wires the orchestrator's `subagents.allowAgents`, applies the **compaction fix** required for small-context local models, installs the flow + style skills into the `main` and `fakoli-orchestrator` workspaces, then restarts the gateway.

## Quickstart — run a wave

```bash
# 1. SGLang must be ON (local tier). On the GPU host: docker ps --filter name=sglang
# 2. Write an intent-driven plan (see flow-plan), then:
openclaw agent --agent fakoli-orchestrator -m "Execute the plan at /path/plan.md using your wave-engine protocol: parallel sessions_spawn per wave, sessions_yield, a fakoli-critic gate after each code wave, then a fakoli-sentinel evidence scorecard. End with WAVE-OK or WAVE-BLOCKED."
```

The orchestrator spawns specialists (local on SGLang), gates with the critic, and the sentinel writes an evidence scorecard. Verify the crew + skills:

```bash
openclaw agents list
openclaw skills list --agent fakoli-orchestrator   # flow-*, style-ops show "ready"
```

## Why local models become useful here

Smaller local models are unreliable as lone generalists but strong when work is scoped into tight packets with an evidence loop. fakoli-claw makes that native: each specialist gets only its task (intent + acceptance + scope + verify), and nothing is trusted without re-run evidence.

**The compaction gotcha (important):** OpenClaw's default `reserveTokens` floor (20000) is too large for a ~32K-context local model and dead-locks turn-1 compaction. fakoli-claw ships the fix — `agents.defaults.compaction.reserveTokens=8192`, `reserveTokensFloor=0` (global only). See [docs/NOTES-compaction.md](docs/NOTES-compaction.md).

## Philosophy — the Fakoli style

Four invariants: **intent over recipe**, **specialist over generalist**, **evidence over claim**, **durability over chat**.

## Status

Crew + wave engine + flow + state + style are live and validated on SGLang (Qwen3.6-35B-A3B) + GPT-5.5. See [CHANGELOG.md](CHANGELOG.md) and `docs/`.

## Documentation

Architecture, internals, the build story, and the framework comparison live in
[`docs/`](docs/README.md) — start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), then
[`docs/THE-BUILD.md`](docs/THE-BUILD.md) and [`docs/COMPARISON.md`](docs/COMPARISON.md). Operating
OpenClaw safely with an autonomous crew: [`docs/HARDENING.md`](docs/HARDENING.md).

## Background & further reading

fakoli-claw is the OpenClaw implementation of the **Fakoli Style** operating model. The "why" behind
every design choice here is in the writing — start with
**[The Fakoli Style: An Operating Model for Building With Agents](https://sekoudoumbouya.com/blog/the-fakoli-style)**,
then [Intent-Driven Flow](https://sekoudoumbouya.com/blog/intent-driven-agentic-flow),
[crew archetypes](https://sekoudoumbouya.com/blog/fakoli-crew-agent-archetypes), and
[State Is the Product](https://sekoudoumbouya.com/blog/state-is-the-product). Full map of components →
essays: [`docs/BACKGROUND.md`](docs/BACKGROUND.md). More: [sekoudoumbouya.com/writing](https://sekoudoumbouya.com/writing).

## Evals & health

`evals/eval-harness.sh` scores the crew on deterministic coding tasks (a repeatable per-model number);
`evals/health-smoke.sh` is a one-shot live-stack check. See [`evals/README.md`](evals/README.md).

## Credits

By [Sekou Doumbouya](https://github.com/fakoli). Canonical agent prompts: [fakoli-plugins](https://github.com/fakoli/fakoli-plugins). MIT licensed.
