# fakoli-claw — Phase A status: COMPLETE

## Done
- Repo scaffolded (plugin manifest, entry skeleton, port plan).
- **All 8 crew specialists ported** to OpenClaw agents (`agents/fakoli-*/AGENTS.md`, extracted from the canonical fakoli-crew prompts via `scripts/build-prompts.sh`), plus a `fakoli-orchestrator` wave-engine prompt.
- Tier-routed config (`config/fakoli-claw.agents.json5`): orchestrator / guido / critic / sentinel → `openai/gpt-5.5`; welder / smith / scout / herald / keeper → `sglang/qwen3.6-35b-a3b-local`.
- `scripts/install.sh` registers all 9 agents on a gateway (per-agent workspaces + prompts + bundled crew-ops references + compaction fix + restart).
- All 9 agents installed + tier-routed on the live gateway.

## Compaction blocker — RESOLVED
- Local SGLang agent runs previously failed on turn 1: `CLI transcript compaction failed: Already compacted`. Root cause: `reserveTokens` floor of 20000 is too large for a 32K window → premature turn-1 compaction. **Fixed** with `agents.defaults.compaction.reserveTokens: 8192` + `reserveTokensFloor: 0` (shipped in the config + installer). Upstream bug: **issue #1**. Limitation + rationale: `docs/NOTES-compaction.md`.

## Validation
- `fakoli-welder` (SGLang): produced its facade integration pattern + backward-compat rationale; `WELD-OK` on a minimal turn.
- `fakoli-smith` (SGLang): `SMITH-OK` — confirms the fix generalizes across local specialists.
- `fakoli-welder` on `gpt-5.5`: full facade output — agent machinery proven on the cloud tier too.

## Next (Phase B+)
- Orchestrator wave dispatch: wire `subagents.allowAgents` (already in the config snippet) + validate a real `sessions_spawn` wave with a critic gate.
- Port `fakoli-flow` (pipeline skills + `/flow` commands + hooks) and `fakoli-state` (MCP + tier routing).
- Optional: a real OpenClaw plugin shell (`index.ts`) registering `/crew` and `/flow` commands.
