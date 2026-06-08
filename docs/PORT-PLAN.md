# fakoli-claw — Port Plan (crew + flow → OpenClaw)

**Goal:** port the Fakoli "trinity" orchestration (specialist crew + flow wave engine) onto OpenClaw, local-first. Specialists run on a local GPU node via an OpenAI-compatible endpoint (e.g. SGLang); planner/critic route to a frontier model.

## Source (Claude Code / Codex)

- **fakoli-crew** — 8 specialist agents (`guido` architect, `critic` reviewer, `scout` researcher, `smith` plugin engineer, `welder` integration, `herald` docs, `keeper` infra, `sentinel` QA). Each = a Claude `.md` (frontmatter: `name` / `description` with `<example>` triggers / `model` tier / `tools`; body = system prompt). Already dual-targeted with `.codex/agents/*.toml`.
- **fakoli-flow** — wave-engine orchestration. Pipeline brainstorm → plan → execute → verify → finish (+ `quick`). Per-stage skills, `/flow` command, hooks, and `references/wave-engine-ref.md` (dependency → wave assignment, parallel dispatch, critic gates).

## Target (OpenClaw)

- **Agents** in `agents.list[]` (+ `agents.defaults`): `id`, system prompt (AGENTS.md), `model`, `tools.profile`, `subagents`.
- **Sub-agents** via `sessions_spawn` (non-blocking) + `sessions_yield` (await); children **announce** back up. `maxSpawnDepth: 2` = main → orchestrator → worker specialists.
- **Tier routing seam:** per-agent `model` / `agents.list[].subagents.model` / explicit `sessions_spawn.model`.
- **Plugin** (this repo): TS package (`package.json` + `openclaw.plugin.json` + `index.ts`) registering commands / hooks / wave tooling.

## Mapping

| Fakoli (Claude `.md` / Codex `.toml`) | OpenClaw |
|---|---|
| crew agent `.md` | `agents.list[]` entry: id + AGENTS.md prompt + `model` (tier) + `tools.profile: "coding"` |
| `model: opus` | frontier model (e.g. `openai/gpt-5.5`) |
| `model: sonnet` / `haiku` | local model (e.g. `sglang/<model>`) |
| wave dispatch `Agent(subagent_type, model, prompt)` | `sessions_spawn(agentId, model, task)` + `sessions_yield` |
| orchestrator (flow `execute`) | `fakoli-orchestrator` agent (depth-1, `maxSpawnDepth: 2`, `subagents.allowAgents = specialists`) |
| `/crew`, `/flow:*` | OpenClaw slash commands (plugin `api.registerCommand`) |
| flow stage skills | OpenClaw skills |
| flow hooks (`detect-context.sh`, `hooks.json`) | OpenClaw hooks (`api.registerHook`) |
| critic gate | critic sub-agent spawn + gate logic in the orchestrator |

## Tier routing (default)

- **Frontier (cloud):** orchestrator/planner, `guido` (architecture), `critic` (review), `sentinel` (QA).
- **Local GPU node:** `welder`, `smith`, `scout`, `herald`, `keeper`.

## Phases

- **A** — crew specialists as OpenClaw agents + config snippet. Validate one `sessions_spawn` onto the local node.
- **B** — orchestrator + wave engine (waves from `Depends on:`, parallel `sessions_spawn`, `sessions_yield`, critic gate).
- **C** — pipeline skills + `/flow` / `/crew` commands.
- **D** — context-detection hooks.
- **E** — end-to-end wave validation (specialists local, planner/critic frontier).
