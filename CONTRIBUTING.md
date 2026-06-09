# Contributing to fakoli-claw

## Docs and CHANGELOG ship with every change

Every change updates the relevant documentation **and** `CHANGELOG.md` (the `[Unreleased]` section)
as part of the same PR or commit — never ship a feature or fix without them. A change that alters
behavior but leaves docs or the changelog stale is incomplete.

When a change touches routing or skills, also keep `docs/ROUTING.md` and the matching `SKILL.md`
(e.g. `skills/fakoli-claw-router/SKILL.md`) in sync.
