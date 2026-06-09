# Getting started — zero to a working crew

You have a GPU sitting in a machine that mostly plays games. This gets a local-first agent crew
running on it in about fifteen minutes, and lets you hand the GPU back to your games when you're
done. If you don't have a GPU, you can still run the crew — point it at any OpenAI-compatible
endpoint and skip the first step.

There are four moves: **serve a model, fix OpenClaw for it, install the crew, run a wave.** You can
run them one at a time, or let `setup.sh` sequence them.

## What you need

- **OpenClaw** installed, with the `openclaw` CLI on your PATH.
- **Node 22+**, **jq**, **python3** (for the installer, the plugin build, and the state server).
- For the local tier: an **NVIDIA GPU + Docker** (Linux native, or Windows/WSL with Docker Desktop).
  No GPU? Skip step 1 and bring any OpenAI-compatible endpoint.
- `uv` is installed for you by the state step if it's missing.

```bash
git clone https://github.com/fakoli/fakoli-claw && cd fakoli-claw
```

## One command (if you want the whole thing)

```bash
# With a local GPU — serve a model, fix OpenClaw, install the crew, smoke-test it:
bash setup.sh --serve --model unsloth/Qwen3.6-35B-A3B-NVFP4

# Or point at an endpoint you already run (no --serve):
bash setup.sh --provider-url http://localhost:30000/v1 --served-name my-local-model
```

Prefer to understand each step? Run them yourself.

## Step 1 — serve a model

`sglang-serve.sh` runs the SGLang inference server in Docker with whatever model and limits you
give it. The defaults are tuned for a single 32GB card.

```bash
bash scripts/sglang-serve.sh up \
  --model unsloth/Qwen3.6-35B-A3B-NVFP4 \
  --ctx 32768 --max-running 3 --mem-fraction 0.82
```

It waits until the endpoint answers, then prints the URL. Useful actions: `status`, `logs`,
`print` (show the docker command without running it), and `down` (stop the container and **hand the
GPU back to your games**). Multi-GPU? add `--tp 2`. Hitting OOM? lower `--mem-fraction`. Gated model?
`--hf-token <tok>`.

> No GPU: skip this step and use your own endpoint in step 2.

## Step 2 — make OpenClaw work with a small local model

This is the step people miss, and it's why a local model "doesn't work" on OpenClaw out of the box. A
~32K-context model dead-locks on turn-1 compaction under the default token reserve. `openclaw-bootstrap.sh`
fixes that (and sets sane sub-agent caps), and optionally registers your endpoint as a provider.

```bash
bash scripts/openclaw-bootstrap.sh \
  --provider-url http://localhost:30000/v1 \
  --model qwen3.6-35b-a3b-local
```

It backs up your config, validates after, and does not restart the gateway unless you pass
`--restart`. Run it with `--dry-run` first if you want to see the changes. This helper is
general-purpose — it's worth running on any OpenClaw box that talks to a small local model, fakoli
or not.

## Step 3 — install the crew

```bash
bash scripts/install.sh          # 9 tier-routed agents + flow/style/router skills + compaction + restart
bash scripts/install-state.sh    # durable state MCP (installs uv, registers the server)
```

`install.sh` runs preflight checks (is SGLang reachable? gateway up? models present?), wires the
orchestrator's sub-agent allowlist, and restarts the gateway. It also installs the flow, style, and
**`fakoli-claw-router`** skills into the `main` and `fakoli-orchestrator` workspaces — the router
decides when a request should stay native vs. enter a flow (see [ROUTING.md](ROUTING.md)). Edit the
tier split with `FAKOLI_CLOUD_MODEL` / `FAKOLI_LOCAL_MODEL` — see [BRING-YOUR-OWN-MODEL.md](BRING-YOUR-OWN-MODEL.md).

## Step 4 — run a wave

Write an intent-driven plan (each task = intent, acceptance criteria, scope, agent, verify command,
`Depends on:`), then hand it to the orchestrator with a fresh session key:

```bash
openclaw agent --agent fakoli-orchestrator --session-key agent:fakoli-orchestrator:run1 \
  -m "Execute the plan at /abs/path/plan.md using your wave-engine protocol; end with WAVE-OK or WAVE-BLOCKED."
```

The call returns after the first dispatch; the wave continues asynchronously. **Poll** the run's
scratch dir (`.fakoli/runs/<run>/`) for `sentinel-final.status` — don't read it immediately.

## Verify

```bash
bash evals/health-smoke.sh                 # SGLang + gateway + agents + state MCP + a live round-trip
bash evals/eval-harness.sh --compare       # score local vs cloud on the same coding tasks
```

## When you want your GPU back

```bash
bash scripts/sglang-serve.sh down          # stop SGLang; the crew falls back to its cloud tier
```

## Where to go next

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — why it's built this way.
- **[HARDENING.md](HARDENING.md)** — running an autonomous crew safely.
- **[ROUTING.md](ROUTING.md)** — when to stay native vs. enter a flow (the `fakoli-claw-router` skill's policy).
- **[BRING-YOUR-OWN-MODEL.md](BRING-YOUR-OWN-MODEL.md)** — swap the model or endpoint.
