# Making OpenClaw smarter and safer

Let me be blunt about the central tension before listing knobs: an autonomous coding crew needs to
run commands, and most of OpenClaw's safety controls work by *stopping* commands. If I set exec
approvals to `allowlist` and walk away, the crew stalls on the first `pytest` waiting for a human who
is asleep. So "safer" here cannot mean "gate every exec." It has to mean: make the crew trustworthy
by design, and reserve the hard gates for the contexts that are not the crew.

That is not a dodge. It is the actual security model of an agent that builds things.

## Safety that does not break the build (this is most of it)

The strongest safety in fakoli-claw is not a config flag. It is the operating model.

- **Evidence over claim is a safety control.** The critic re-runs the verify command and the sentinel
  refuses to pass a criterion without command output. A gate that runs the command is what stops
  broken work from shipping unattended. During the build the sentinel caught a real failure the
  text-only critic had passed. That is the safety net working.
- **Bounded refinement is a safety control.** Every fix loop is capped (critic cycle max 3, welder
  fix max 2) and escalates to a human at the ceiling. There is no open-ended "keep trying" loop to run
  away with cost or time.
- **One owner per file per wave is a safety control.** It is the agent version of not letting two
  engineers edit the same module at once — it prevents the corrupt-merge class of failure entirely.
- **Durable, replayable state is a safety control.** Work survives a crash; a dead agent's claim is
  reaped back to the pool; evidence is a typed event log, not a transcript you hope to parse.

If you do nothing else, keep those four. They are why the crew can run while you sleep.

## OpenClaw knobs — and the tradeoff each one costs

These are real and documented. I am listing what each *costs the crew* so the choice is honest.

- **Exec approvals (`exec.security` = deny / allowlist / full; `exec.ask`).** The right guardrail for
  *interactive* or *untrusted* agents. Cost for the crew: `allowlist`/`ask` will block the
  specialists' `tsc`/`pytest`/`cargo` calls mid-wave. Use it for the human-facing `main` agent, not
  the autonomous builders — or pre-seed an allowlist of the verify binaries you actually use.
- **`tools.exec.strictInlineEval`.** Defense-in-depth that forces `python -c`, `node -e`, etc. to
  require approval. Cost: it breaks the eval harness and any verify that uses `python -c`. Good for a
  locked-down assistant; wrong for the crew. Know which agent you are hardening.
- **Sandboxing.** Run agents against a sandboxed workspace so a bad command cannot reach the whole
  host. This is the right heavy hammer for untrusted input. Cost: setup, and the crew needs real
  filesystem access to the project it is building.
- **`plugins.allow` / `plugins.deny`.** `allow` is an *exclusive* allowlist — and this gateway has 72
  plugins enabled, so an allowlist is impractical and one missed id silently disables a channel or
  memory. The honest recommendation here is the opposite of the usual advice: prefer `plugins.deny`
  for specific untrusted ids and keep `plugins.load.paths` tight, rather than a 72-entry allow. The
  recurring "plugins.allow is empty" advisory is a *nudge*, not a wound — treat it as a reminder to
  audit `plugins.load.paths`, not a reason to risk the daily driver.
- **Sub-agent limits (`agents.defaults.subagents`).** `maxConcurrent`, `maxChildrenPerAgent`,
  `runTimeoutSeconds`, `maxSpawnDepth` cap blast radius and runaway spawning. These are pure upside —
  set them to match your GPU's real concurrency (~3 for a 35B model on 32GB). Already set here.
- **Tool-loop detection + thinking levels.** Loop detection catches an agent stuck repeating a tool;
  thinking levels let you spend reasoning where it matters. Both are smarter-not-just-safer.

## Smarter

- **Tier routing** is the cheapest intelligence multiplier: spend the frontier model only on planning
  and the gates, run everything else free and parallel on the local GPU.
- **The eval harness is a regression gate.** `evals/eval-harness.sh --compare` gives a repeatable
  per-tier score; gate model or config swaps on it instead of vibes. (Today: local 6/6 in 92s vs
  cloud 6/6 in 134s — local matched cloud and was faster on scoped tasks.)
- **Memory is how the gateway learns to build like this.** The durable knowledge file
  (`~/.openclaw/workspace/memory/fakoli-claw.md`) teaches the `main` agent the operating model, the
  crew commands, and the gotchas, so it runs real work as a wave instead of one big turn.

## Recommended actions (these change security config — run them yourself)

I did not apply these, because changing a security boundary on a daily-driver gateway is your call,
not mine. When you want them:

```
# Cap sub-agent blast radius if you ever raise concurrency (already conservative today):
openclaw config set agents.defaults.subagents.maxConcurrent 3

# Audit what can auto-load, then deny anything you do not trust:
openclaw plugins list --enabled
openclaw config set plugins.deny '["<untrusted-id>"]'

# Harden the human-facing main agent's exec WITHOUT touching the crew:
#   set exec approvals to allowlist/ask for `main` only, via the Control UI → Nodes → Exec approvals,
#   or ~/.openclaw/exec-approvals.json under agents.main.
```

The principle underneath all of it: safety for an autonomous builder is not a wall around the
commands. It is a gate that proves each step and a loop that knows when to stop. Build that, and the
flags become fine-tuning instead of the only thing standing between you and a bad morning.

---

Sources: OpenClaw [Exec Approvals](https://docs.openclaw.ai/tools/exec-approvals),
[Security](https://docs.openclaw.ai/gateway/security),
[Plugins](https://docs.openclaw.ai/tools/plugin), [Sub-Agents](https://docs.openclaw.ai/tools/subagents).
