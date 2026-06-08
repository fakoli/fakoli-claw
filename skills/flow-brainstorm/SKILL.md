---
name: flow-brainstorm
description: Design phase — refine an idea into an approved spec through structured one-question-at-a-time dialogue, propose 2-3 approaches, present the design section by section, write the spec, and hand off to flow:plan. Works headless over any channel.
---

# flow:brainstorm — Design Phase (OpenClaw)

Turn an idea into a fully-formed spec through structured dialogue, then hand off to `flow:plan`.

<HARD-GATE>
Do NOT invoke flow:plan, write code, scaffold files, or take any implementation action until
the spec is written, self-reviewed, and the user has explicitly approved it.
</HARD-GATE>

## Process
1. **Explore context.** Read `CLAUDE.md` (conventions, spec output path — that path always wins),
   key project files, and `git log --oneline -10`.
2. **Assess scope BEFORE details.** If the request names multiple independent subsystems, stop and
   help decompose into sub-projects; brainstorm the first one. Don't ask detail questions about a
   project that needs decomposition.
3. **Clarifying questions — one per message**, multiple-choice preferred (2–4 options + a default).
   Focus on purpose, users, constraints, success criteria. 3–5 questions is usually enough.
4. **Propose 2–3 approaches.** Lead with your recommendation + one-sentence why; state trade-offs.
   Don't present unequal options as equal.
5. **Present the design section by section** (architecture, data model/interfaces, data flow, error
   handling, testing). Scale each to its complexity. After each: "Does this section look right?"
6. **Write the spec** to the CLAUDE.md path or `docs/specs/<YYYY-MM-DD>-<topic>.md`. Include goal,
   context, decisions, data model, behaviors, error handling, acceptance criteria, out-of-scope.
7. **Self-review** (placeholder scan, internal consistency, scope, ambiguity). Fix inline.
8. **User review gate.** "Spec written to `<path>`. Review and tell me of any changes before
   planning." Wait for explicit approval; revise + re-review on request.
9. **Hand off** to flow:plan with the spec path.

## OpenClaw notes
- Works headless: all questions are text-first and route through whatever channel the session uses
  (CLI, Telegram, etc.). A visual companion is optional and additive, never required.
- This is a coordinator skill — it runs in the main agent, not a spawned specialist.

## When NOT to brainstorm
Use `flow:quick` for one-sentence changes under 3 files (bug fix, rename, typo, config value).
Use brainstorm for new features, architectural changes, or anything spanning multiple files.
