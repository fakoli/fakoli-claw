# fakoli-claw

**The Fakoli plugin suite, ported to [OpenClaw](https://openclaw.ai).**

`fakoli-claw` brings the *Fakoli style* — a crew of specialist AI agents driven by intent, evidence, and durable state — to the OpenClaw multi-agent runtime. It is **local-first**: high-volume specialist work runs on your own GPU through an OpenAI-compatible endpoint (SGLang / vLLM / Ollama), while planning and review can route to a frontier model.

> **Status: early WIP.** Porting `fakoli-crew` (8 specialists) and `fakoli-flow` (wave orchestration) from Claude Code / Codex onto OpenClaw. See [`docs/PORT-PLAN.md`](docs/PORT-PLAN.md).

## What's inside (target)

- **The crew** — 8 specialist agents (architect, reviewer, researcher, plugin engineer, integration, docs, infra, QA) as OpenClaw `agents.list[]` definitions.
- **The orchestrator** — a wave engine that dispatches specialists in parallel via OpenClaw sub-agents (`sessions_spawn` + `sessions_yield`), with critic gates between waves.
- **Tier routing** — specialists run local on your GPU node; planner / critic / architect route to a frontier model. All config, trivially re-tunable.
- **Pipeline** — `/flow` commands for brainstorm → plan → execute → verify → finish, plus context-detection hooks.

## Philosophy — the Fakoli style

Four invariants: **intent over recipe**, **specialist over generalist**, **evidence over claim**, **durability over chat**. Smaller local models become genuinely useful when work is scoped into tight packets with evidence loops. fakoli-claw makes that pattern native to OpenClaw.

## Install

> Not yet published. Once released:
>
> ```
> openclaw plugins install fakoli-claw
> ```
>
> Agent configs (the crew) install into `agents.list[]`; see `config/`.

## Roadmap

- [ ] **Phase A** — crew specialists as OpenClaw agents (tier-routed)
- [ ] **Phase B** — orchestrator + wave engine (`sessions_spawn` + critic gate)
- [ ] **Phase C** — pipeline skills + `/flow` and `/crew` commands
- [ ] **Phase D** — context-detection hooks
- [ ] **Phase E** — end-to-end wave validation on a local GPU node

## Credits

By [Sekou Doumbouya](https://github.com/fakoli). Canonical agent prompts live in [fakoli-plugins](https://github.com/fakoli/fakoli-plugins). MIT licensed.
