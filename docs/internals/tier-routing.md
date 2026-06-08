# Internals — tier routing

Tier routing is the single most consequential configuration choice in fakoli-claw, and it is one
field per agent. This is the model behind it.

## The split

| Tier | Model | Agents | Why here |
|---|---|---|---|
| Cloud | `openai/gpt-5.5` | orchestrator, guido, critic, sentinel | They set the quality ceiling for the whole wave |
| Local GPU | `sglang/qwen3.6-35b-a3b-local` | welder, smith, scout, herald, keeper | High-fan-out, repetitive, cheap to verify |

The reasoning is a tradeoff, stated as one. Planning, architecture, and the review gates decide
whether the entire run is good or garbage — that is worth frontier money. Implementation, research,
and docs are exactly the work a local model should do for free while the GPU is mine anyway. Get the
ceiling-setting roles right and the cheap roles can be cheap.

## How it is wired

Each agent carries a `model` field in `agents.list[]`. That is the whole mechanism — no routing
rules, no branching. The installer takes `FAKOLI_CLOUD_MODEL` / `FAKOLI_LOCAL_MODEL` env overrides so
the split is trivially re-tunable. If you disagree with where I drew the line, move one agent's
`model` and restart.

## Bring your own model

The local id (`sglang/<model>`) resolves to a provider in `models.providers`. Point it at any
OpenAI-compatible endpoint — vLLM, Ollama, LM Studio, another SGLang box. The provider `api` must be
`openai-completions` (the valid OpenAI-compatible *chat* option; `openai-compatible` is not a real
value and will be rejected). Full steps: `docs/BRING-YOUR-OWN-MODEL.md`.

## The compaction constraint (non-optional for local)

A small-context model needs the compaction fix or it does not run at all:

```
agents.defaults.compaction.reserveTokens     = 8192
agents.defaults.compaction.reserveTokensFloor = 0
```

The default floor (20000) on a ~32K window leaves ~12K usable, so the system prompt plus tool schemas
trip threshold compaction on turn 1 and the openai-completions transcript compaction dead-locks
(`Already compacted`). 8192 + floor 0 gives the local model ~24.5K usable and is harmless for big
cloud windows (the threshold auto-scales as `contextWindow - reserveTokens`). It is global-only —
no per-agent or percentage form yet (upstream candidate, fakoli-claw issue #1).

A related operational note that is really the same lesson: a fresh `--session-key` per agent run
keeps the local model's transcript from bloating across many calls and hitting the same compaction
wall. The eval harness and smoke test both set one.

## The economics

This is the payoff line. Once the cloud roles set a trustworthy ceiling, every local builder turn is
free and parallel on hardware already bought. "Run more agents" stops being a cloud invoice and
starts being a question of how many concurrent requests the 5090 will hold (about three for a 35B
model on 32GB). That is a capacity problem, not a billing problem — and capacity problems are the
good kind.
