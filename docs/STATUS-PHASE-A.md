# fakoli-claw — Phase A status

## Done
- Repo scaffolded (plugin manifest, entry skeleton, port plan).
- Agents config (`config/fakoli-claw.agents.json5`): 8 specialists + orchestrator, tier-routed (cloud GPT-5.5 vs local SGLang).
- **welder** ported (`agents/fakoli-welder/AGENTS.md`) and installed on the live gateway as agent `fakoli-welder` (model `sglang/qwen3.6-35b-a3b-local`).

## Validation
- **welder works end-to-end through the OpenClaw agent loop** — verified on `openai/gpt-5.5`: given an integration task it produced a correct facade (`RetryingHttpClient implements HttpClient`, delegating each method through a `RetryPolicy`) and explained the backward-compatibility choice ("implements the same public API … unchanged call signatures"). The port (prompt + agent machinery) is proven.

## Known blocker — local SGLang agent runs
- Running the full agent loop on the **local SGLang** model fails with:
  `CLI transcript compaction failed for sglang/qwen3.6-35b-a3b-local: Already compacted`
- Root cause: SGLang is configured as an `openai-completions` provider (the valid OpenAI-compatible chat option in OpenClaw — alternatives are Responses / Ollama / Anthropic / Google / Bedrock). OpenClaw represents `openai-completions` transcripts as a flat "CLI transcript" with a `cli_budget`; on turn 1 the context exceeds the budget, auto-compaction runs once (`compactionCount=1`), a second compaction is blocked by the `already_compacted_recently` guard, and that block is treated as a hard failure (`postCompactionGuard` / `postCompactionMaxChars` / `truncateAfterCompaction`).
- Single-shot inference on SGLang works fine (`openclaw infer model run --model sglang/...` → ok). Only the multi-turn agent loop is affected. GPT-5.5 (Responses API) is unaffected.
- Fix direction (TODO): raise `postCompactionMaxChars` / relax `postCompactionGuard` for the sglang provider (parent config path TBD), or disable CLI-transcript compaction for it; failing that, file upstream. Until then specialists validate on GPT-5.5; local-model agent runs pend this fix.

## Next
- Port the remaining 7 specialists (guido / critic / scout / smith / herald / keeper / sentinel) + the orchestrator prompt.
- `scripts/install.sh` — create per-agent workspaces, copy prompts, patch config.
- Resolve the SGLang compaction blocker, then re-validate a specialist on the local node.
- Phase B — orchestrator wave dispatch (`sessions_spawn` + `sessions_yield` + critic gate).
