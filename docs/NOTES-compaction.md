# Notes — compaction & local small-context models

## The fix we ship

`config/fakoli-claw.agents.json5` sets:

```json5
agents: { defaults: { compaction: { reserveTokens: 8192, reserveTokensFloor: 0 } } }
```

Without this, full agent runs on a ~32K-context local model (SGLang, `api: openai-completions`)
fail on **turn 1** with `CLI transcript compaction failed: Already compacted`. Root cause and
the upstream report: see the repo issue "reserveTokens floor too high for small-context models".

## Why a flat number (and not a percentage / per-model value)

We checked the OpenClaw config schema:

- **`reserveTokens` is `type: integer`** — an absolute token count. There is **no percentage / ratio** form.
- **`compaction` lives only under `agents.defaults`** — it is **not** present in the `agents.list[]`
  item schema (`defaults.compaction: true`, `list[].compaction: false`, while `list[].model: true`).
  So you **cannot** set a per-agent or per-model compaction/reserve today; one global block serves
  every agent.

## Why a single global value is OK anyway

The threshold is `contextTokens > contextWindow - reserveTokens`, and `contextWindow` **is**
per-model. A constant reserve therefore auto-scales the threshold to each model's window:

| model | contextWindow | reserveTokens | usable before compaction |
|-------|---------------|---------------|--------------------------|
| SGLang Qwen3.6 (local) | 32,768 | 8,192 | ~24,576 |
| GPT-5.5 (cloud) | 200,000+ | 8,192 | ~192,000 |

Pick a reserve `>=` your largest model's typical output (8192 = the local model's `maxTokens`)
and it behaves sensibly across the fleet. The 20,000 default was simply too large a *constant*
for a 32K window. The one compromise: it also applies to `main`/cloud agents (gives them *more*
usable context; OpenClaw's overflow-recovery covers a rare oversized turn).

## If you ever need proportional / per-model budgeting

Not available in core OpenClaw today. Options:

1. File / track the upstream feature request (percentage `reserveTokens`, or per-agent `compaction`).
2. Implement a custom **compaction provider** plugin (`registerCompactionProvider()`) and set it via
   `agents.defaults.compaction.provider` — it can apply whatever budgeting logic you want.
