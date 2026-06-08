# Background & further reading

fakoli-claw is the **OpenClaw implementation of the Fakoli Style** — the operating model Sekou
Doumbouya describes in his writing. If the code here reads like it has a strong opinion, that's
because it does; the essays are the "why" behind every design choice in this repo.

Start here:

- **[The Fakoli Style: An Operating Model for Building With Agents](https://sekoudoumbouya.com/blog/the-fakoli-style)**
  — "Three plugins, four invariants, one principle. What I built isn't a toolkit — it's an operating
  model." The four invariants this repo preserves end-to-end: **intent over recipe**, **specialist over
  generalist**, **evidence over claim**, **durability over chat**.

How each piece of fakoli-claw maps to the writing:

| fakoli-claw component | The idea, in Sekou's words |
|---|---|
| The 9-agent crew (`agents/`, tier-routed) | [Teaching AI Agents to Work Like a Team (Not a Crowd)](https://sekoudoumbouya.com/blog/fakoli-crew-agent-archetypes) — specialist archetypes that coordinate through file ownership, waves, and structured handoffs. |
| The wave engine + flow skills (`skills/flow-*`) | [From Pressing Buttons to Intent-Driven Flow](https://sekoudoumbouya.com/blog/intent-driven-agentic-flow) — describe what you want and walk away, instead of hand-managing context windows. |
| The `fakoli-state` MCP (`state/`, 22 tools) | [Plan, Claim, Apply: Building fakoli-state](https://sekoudoumbouya.com/blog/building-fakoli-state) and [State Is the Product](https://sekoudoumbouya.com/blog/state-is-the-product) — the durable state layer that breaks first in real multi-agent work, and almost nobody builds. |
| Local-first, tier-routed execution (SGLang on the GPU; frontier model for planning/review) | [From Cloud Infrastructure to AI Infrastructure](https://sekoudoumbouya.com/blog/infrastructure-engineer-to-ai-architect) — what transfers from twenty years of platform engineering into AI infra. |
| `style-ops` + the principles ledger | [The Fakoli Style](https://sekoudoumbouya.com/blog/the-fakoli-style) — the operating model made into a versioned, validated ledger of principles. |

The Claude Code / Codex originals live in [fakoli-plugins](https://github.com/fakoli/fakoli-plugins);
fakoli-claw is the third target (`.openclaw`-native), built so the same operating model runs on a
**local-first** stack: high-volume specialist work on your own GPU, planning and review on a frontier
model. More writing and talks: [sekoudoumbouya.com/writing](https://sekoudoumbouya.com/writing).
