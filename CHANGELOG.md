# Changelog

All notable changes to fakoli-claw are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions follow semver.

## [Unreleased]

### Added — the complete onboarding story (zero → wave)
- **`scripts/sglang-serve.sh`** — configurable SGLang Docker runner. Actions `up`/`down`/`restart`/
  `status`/`logs`/`print`; flags for model, port, context, max-running, mem-fraction, tensor-parallel,
  quantization, kv-cache dtype, served-name, image, shm, HF token, and `--extra` passthrough (env
  overrides via `FAKOLI_*`). `up` waits for the endpoint to answer; `down` frees the GPU for gaming.
  Defaults match the proven single-32GB-card config.
- **`scripts/openclaw-bootstrap.sh`** — general-audience helper that applies the fixes any
  small-context local model needs on OpenClaw (fakoli or not): the compaction fix
  (`reserveTokens=8192`, `reserveTokensFloor=0`), sane sub-agent caps, and optional provider
  registration for your OpenAI-compatible endpoint. Idempotent; backs up + validates config (restores
  on invalid); `--dry-run` previews; no gateway restart unless `--restart`.
- **`setup.sh`** — one-command orchestrator sequencing serve → bootstrap → install → state → smoke,
  with `--serve`, `--provider-url`, `--model`, `--served-name`, `--no-state`.
- **`docs/GETTING-STARTED.md`** — the four-move product walkthrough (serve a model, fix OpenClaw,
  install the crew, run a wave), including the no-GPU path and the gaming toggle. README install
  section reworked to front it.

## [0.1.0] — 2026-06-08

First end-to-end working release: the crew, the wave engine, the flow pipeline, durable state,
and style — all live and validated on SGLang (Qwen3.6-35B-A3B) + GPT-5.5.

### Added
- **Wave engine (Phase B).** `fakoli-orchestrator` drives dependency-ordered waves via
  `sessions_spawn` + `sessions_yield`, with a `fakoli-critic` gate after every code wave and a
  `fakoli-sentinel` evidence scorecard. Validated: 2 specialists on SGLang in parallel, critic
  PASS (re-runs verify) and BLOCK, sentinel `Final verdict: PASS`.
- **Orchestrator subagents config.** `subagents.allowAgents` (the 8 specialists) +
  `delegationMode: prefer`; limits (`maxSpawnDepth`, `maxConcurrent`, …) in
  `agents.defaults.subagents`. (Per-agent `subagents` accepts only `allowAgents` + `delegationMode`.)
- **Flow pipeline (Phase C).** Six OpenClaw skills — `flow-brainstorm/plan/execute/verify/finish/quick`
  — ported from fakoli-flow (`Agent(subagent_type=…)` → `sessions_spawn`). Plus `hooks/detect-context.sh`.
- **State MCP (Phase D).** `fakoli-state` FastMCP server registered under `mcp.servers.fakoli-state`;
  22 durable-state tools (PRD/plan/claim/review lifecycle) live on the crew. `install-state.sh` adds
  `uv` and warms the venv. Live round-trip verified from a SGLang-tier agent.
- **Style (Phase E).** `style-ops` skill + principles ledger (`data/principles.json`).
- **Plugin shell (Phase F).** `index.ts` registers `/crew` and `/flow` menu commands + a SessionStart
  context hook.
- **One-command install.** `scripts/install.sh` with preflight checks (SGLang reachable, gateway up,
  models present, uv) + auto config-validate + gateway restart.
- **Docs.** README quickstart, `docs/BRING-YOUR-OWN-MODEL.md`, compaction notes.

### Fixed
- **Compaction dead-lock on small-context local models** — `reserveTokens=8192`,
  `reserveTokensFloor=0` (global). Without it, a ~32K-context agent dead-locks on turn-1 compaction.
  Upstream report: issue #1.

### Known limitations
- `reserveTokensFloor` is global-only (no per-agent / percentage). Upstreaming proposed.
- `/crew` `/flow` slash commands are **live** — `openclaw plugins inspect fakoli-claw --runtime`
  shows `Commands: crew, flow`. (Resolved the earlier `register()` `undefined.trim()`: the command
  `handler` must return an object `{ text }`, NOT a bare string, and the non-standard `acceptsArgs`
  field must be dropped. Documented shape: `registerCommand({ name, description, handler: async () =>
  ({ text }) })` — see https://docs.openclaw.ai/plugins/sdk-entrypoints.)

## [0.0.1]
- Initial scaffold: plugin manifest, entry skeleton, port plan, Phase A crew agents.
