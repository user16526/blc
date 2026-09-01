---
paths:
  - "scripts/**"
  - "docs/**"
  - "**/*deploy*"
  - "**/*config*"
  - "**/*.tf"
  - "**/*.env.example"
---

# Verify External-System State Before Concluding

Most "we already fixed this — why is it back?" loops and version conflicts come from
ONE habit: trusting a note about a live system instead of checking the live system.
This rule breaks that habit.

## The rule
For any claim about an EXTERNAL system's state — a deployed version or git SHA in
production, a published config (feature flags, CDN, analytics container), an external
API / DB / queue, provider / cloud / DNS config — the LIVE system is the source of
truth, not a note in the repo. A note (`current.md`, a doc, a past report, a
screenshot, even a skill you wrote) is a POINTER, not evidence. Re-pull the live state
before you:
- conclude what is "currently" true,
- make a recommendation that depends on it, or
- write it into a durable artifact (a skill, CLAUDE.md, current.md, a plan).

Use this project's read-only checker (`scripts/check_live_state.py` — implement it for
your stack) so "I should check" becomes one command.

## Published version numbers are the #1 stale fact
A documented version (deploy build, published container, schema version) goes stale the
moment something ships and the note isn't updated. Never cite a version from
`current.md` or CLAUDE.md — confirm the live published version first, then act.

## Validate breadth, not one example
When a conclusion generalises across many items, test it across many items, and look
hardest at the items most likely to break the pattern. One green example is the most
common way a wrong generalisation sneaks through.

## Don't re-fix on a stale basis (anti-loop)
If something was "already fixed" and is back, do NOT re-apply a fix blind. First read
`tasks/lessons.md` for the prior attempt(s), then verify the LIVE state. A bug "fixed"
repeatedly almost always means the wrong layer is being patched, or the verification
used stale data — stop and question the approach instead of patching again.

## Don't bake an unverified claim into a durable artifact
A skill / CLAUDE.md line / `current.md` entry stating a live-system fact must either
cite a live check with a date, or be marked "verify before relying." Procedures are
durable; facts about live systems decay — an unverified claim becomes self-reinforcing
the next time it is read.

## current.md provenance convention
Tag external-state facts inline like `[verified <date> via <tool>]`. Anything older than
about 7 days, or any fact a production / irreversible action depends on, gets re-pulled
live before use. Bump `Last updated:` whenever you edit `current.md`.

## Gate before an external / irreversible action
Before recommending OR taking an action that changes a production external config
(swapping a feed, altering a provider / DNS / cloud setting, modifying production data),
run the live read-only checker first and show its output. Treat the diagnosis behind
such an action with the same proof standard as built code. This holds at every matrix row and automode
level.
