---
name: flow-finish
description: Ship phase — re-run fresh tests, then present exactly four options (merge locally, push+PR, keep as-is, discard) and execute only the explicit choice. Never auto-merge, auto-push, or discard without the typed word discard.
---

# flow:finish — Ship Phase (OpenClaw)

Ship work only after fresh verification. Present options, wait for an explicit choice, execute it.

<HARD-GATE>
Never auto-merge or auto-push. Present the 4 options and wait. Per the OpenClaw safety model,
pushing, PR creation, and branch deletion are side-effectful — the user must choose explicitly,
and irreversible deletion requires the exact typed word `discard`.
</HARD-GATE>

## Steps
1. **Re-run tests now** (fresh; the verify step's results are stale by definition). Detect language
   and run: TS `npx tsc --noEmit && bun test`; Py `ruff check . && mypy . && pytest`; Rust
   `cargo check && cargo test`. If tests fail → STOP, show full output, return control.
2. **Determine base branch.** `git branch --show-current`; prefer `main`, else `master`, else ask.
3. **Present exactly 4 options** (verbatim, no recommendation, no 5th option):
   ```
   Tests pass. What would you like to do with this branch?
   1. Merge back to <base> locally
   2. Push and create a Pull Request
   3. Keep the branch as-is
   4. Discard this work
   ```
4. **Execute the choice:**
   - **1 Merge:** checkout base, pull, merge feature; re-run tests on the merge; on pass
     `git branch -d`; on fail keep branch + report.
   - **2 PR:** `git push -u origin <branch>` then `gh pr create` with summary from the plan Goal +
     test results. Report the PR URL. (Push/PR require this explicit option — see safety model.)
   - **3 Keep:** report, change nothing.
   - **4 Discard:** show `git log <base>..HEAD --oneline`, require the user to type exactly
     `discard` (reject "yes"/"ok"); then checkout base + `git branch -D`. Irreversible.
5. **Worktree cleanup:** for Merge/Discard, `git worktree remove` if one exists; for PR/Keep, leave it.

## Never
Merge without fresh tests · push without option 2 · delete without the typed `discard` ·
force-push unless explicitly requested · proceed with failing tests.
