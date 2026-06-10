# Cloud-first operating model (default) + SGLang on-demand

fakoli-claw runs **cloud-first by default**. The flat-rate OpenAI **Pro / OAuth** path is the primary
model; the local **SGLang** tier is **optional and on-demand**, not a default dependency.

## Default routing
- `agents.defaults.model.primary = openai/gpt-5.5` (OAuth / Pro — flat-rate, no per-token billing).
- `agents.defaults.model.fallbacks = [openai/gpt-5.4-mini]` (also OAuth flat-rate; cheap worker tier).
- Crew tiering (set by `scripts/install.sh`):
  - thinking agents — orchestrator, guido, critic, sentinel -> `FAKOLI_CLOUD_MODEL` (default `openai/gpt-5.5`).
  - worker specialists — welder, smith, scout, herald, keeper -> `FAKOLI_LOCAL_MODEL` (default `openai/gpt-5.4-mini`).
- `FAKOLI_LOCAL_MODEL` is the **cheap worker tier** and despite the name defaults to a **cloud** mini
  model. Point it at `sglang/...` only if you want the optional local tier.

## Why cloud-first
- Predictable cost: flat-rate Pro/OAuth has no per-token billing on the default path.
- No GPU dependency: the gateway serves with the local box off (GPU free for gaming).
- Per-token API providers (Anthropic, Gemini, OpenRouter, Perplexity) are **opt-in tiers**, never default.

## SGLang: optional, on-demand, off by default
SGLang is no longer auto-started. To use the local tier:
1. Start it on the GPU box: `scripts/sglang-serve.sh up` (or `SGLang-ON.bat` on Windows).
2. Route to it explicitly: set `FAKOLI_LOCAL_MODEL=sglang/qwen3.6-35b-a3b-local` before `install.sh`,
   or invoke `sglang/...` model refs directly.
3. Free the GPU: `scripts/sglang-serve.sh down` (or `SGLang-OFF-Gaming.bat`).

On the reference rig, auto-start was decommissioned **reversibly**: Docker `--restart no` + container
stopped, and the watchdog + host-metrics scheduled tasks disabled. Re-enable = the toggle script +
`Enable-ScheduledTask`.

### On-demand remote start (design)
The toggle scripts are the entry point; to trigger them from OpenClaw/remotely:
- **Preferred — OpenClaw node exec:** the GPU box runs the OpenClaw Windows Companion as a paired
  node; an operator/skill dispatches `cmd /c <path>\SGLang-ON.bat` to that node (requires the
  companion online).
- **Alternative — SSH:** once the gateway host's key is in the GPU box's
  `administrators_authorized_keys`, `ssh dark "C:/Users/<you>/sglang/SGLang-ON.bat"`.
- Until one is wired, the manual toggle (`SGLang-ON.bat`) is the on-demand control.

## Cost-safety guardrails (voice / search / models)
- **TTS:** auto-TTS stays **off**; default provider is **microsoft** (free Edge neural). **ElevenLabs
  is opt-in only** (`/tts provider elevenlabs` + `/tts audio`) — never the default.
- **STT:** **Whisper** is the default (API skill + local CLI). **Deepgram is opt-in** (per-minute).
- **Web search:** **brave** is the selected provider (free tier). Perplexity is enabled but opt-in.
- **Per-token LLMs** (Anthropic/Gemini/OpenRouter/Perplexity) are available providers, kept **out of
  `agents.defaults.model` primary/fallbacks**.
- All provider/voice/search keys are **file-provider SecretRefs** (`~/.openclaw/secrets.json`), never
  plaintext in committed config.
