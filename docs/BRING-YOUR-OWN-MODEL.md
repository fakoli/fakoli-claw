# Bring your own model

fakoli-claw's tier routing is pure config. You can swap the local model, the cloud model, or
point the local tier at a different OpenAI-compatible endpoint (vLLM, Ollama, LM Studio, another
SGLang box) without touching any agent prompt or skill.

## The two tiers

| Tier | Default model id | Who runs there |
|---|---|---|
| Cloud | `openai/gpt-5.5` | orchestrator, guido, critic, sentinel |
| Local | `sglang/qwen3.6-35b-a3b-local` | welder, smith, scout, herald, keeper |

## Swap models at install time

```bash
FAKOLI_CLOUD_MODEL="openai/gpt-5.5" \
FAKOLI_LOCAL_MODEL="sglang/my-other-local-model" \
bash scripts/install.sh
```

The installer assigns these per agent in `agents.list[].model`.

## Point the local tier at a different endpoint

The local model id (`sglang/<model>`) resolves to a provider defined in `~/.openclaw/openclaw.json`
under `models.providers`. To use a different OpenAI-compatible server, add/edit a provider:

```bash
# provider api MUST be "openai-completions" (the valid OpenAI-compatible *chat* option;
# "openai-compatible" is INVALID in OpenClaw).
openclaw config set "models.providers.sglang.models[0].api" openai-completions
openclaw config set "models.providers.sglang.baseUrl" "http://<host>:<port>/v1"
```

Common endpoints: vLLM and SGLang serve `/v1` OpenAI-compatible; Ollama uses the `ollama` provider
api; LM Studio serves `/v1` (use `openai-completions`).

## Right-size for the model's context window

Small-context local models (≈32K) need the compaction fix, already applied by the installer:

```bash
openclaw config set agents.defaults.compaction.reserveTokens 8192
openclaw config set agents.defaults.compaction.reserveTokensFloor 0
```

If your local model has a larger window (e.g. 128K), you can raise `reserveTokens`; the threshold
auto-scales as `contextWindow - reserveTokens`. `reserveTokensFloor` is global-only — there is no
per-agent or percentage form today (tracked upstream as fakoli-claw issue #1).

## Concurrency

The orchestrator's `agents.defaults.subagents.maxConcurrent` (default 5) caps parallel sub-agents.
Match it to your server's concurrency budget — a 32GB GPU serving a 35B model comfortably handles
~3 concurrent specialists. Lower it if you see queueing or OOM.

## Verify after a swap

```bash
openclaw agent --agent fakoli-welder -m "Reply with exactly: OK"   # local tier smoke
openclaw agents list                                                # confirm model ids
```
