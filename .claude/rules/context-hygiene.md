# Context Hygiene — what to clear, and when (always on)
<!-- No `paths:` frontmatter on purpose: this governs /clear and /compact timing for
     ANY work, not work on a specific file, so it must always be loaded. -->

The context window is a working set, not a trash can. Clearing the wrong thing is as
costly as never clearing — part of the value is the design↔code synthesis that lives
in no file and exists only while everything is in context together.

## Precondition (always): durable first
Before any `/clear`, route every DURABLE thing to memory: decisions → `decisions.md`,
current state → `current.md`, lessons → `lessons.md`, run facts → the run report
(use the `memory-router` skill). If it's written, a reset loses nothing.

## When TO clear / compact
- ✅ A real topic change.
- ✅ Crossing a pipeline PHASE boundary (research → spec → build → verify → deploy).
- ✅ Context is getting huge or answers start degrading (context rot) — even mid-task:
  first harvest the durable conclusions to memory, THEN clear.

## When NOT to clear
- ❌ After every micro-task. Cold-reloading memory each time costs more than the warm
  cache, and it destroys the in-context synthesis. Within ONE coherent task, keep the
  context warm — it is often cheaper in tokens than fine-slicing, not just faster.

## The catch (don't over-trust context either)
Synthesis "lives only in context" is exactly what a clear destroys — so keep it warm
WHILE the task is coherent, but harvest its durable CONCLUSIONS into `decisions.md` as
you go. Context is the workbench, not the only home for anything that matters.

## Prefer /compact over /clear mid-task
If a coherent task outgrows the window, `/compact` (summarize, keep the thread) beats a
hard `/clear`. Use `/clear` at true boundaries. (Project-root CLAUDE.md and these rules
survive `/compact` — they're re-read from disk — so the discipline stays active.)

## Context Guard owns the thresholds (runtime version: .claude/context-guard/config.json)
**Where it lives:** ONE shared runtime at `~/.claude/context-guard/`, registered once
in `~/.claude/settings.json`. This project owns exactly one Context Guard file —
`.claude/context-guard/config.json`, the opt-in switch and the threshold source. A
project that carries its own copy of the runtime makes the shared one stand down and
Context Guard goes silently INACTIVE, so never vendor it. Install and opt in with
`python3 <context-guard-release>/scripts/install-context-guard.py --project .`; prove
it with `python3 ~/.claude/context-guard/verify-install.py --project .`.

The judgment above stays yours; the NUMBERS are automated. Context Guard's
advisory ladder (1M profile: 200k "work compactly" → 300k write/update the task
handoff → 400k final handoff refresh → ~450k auto-compaction → automatic resume
from the handoff) fires as one-shot hints; nothing blocks. After `/clear` the
active handoff is only announced — restoring it requires an explicit
`/continue-work` (a `/clear` may mean "different task now"). A RUNAWAY backstop
(~600k) exists solely for the case where auto-compaction physically failed.
Thresholds are a starting point, not truth: run
`python3 ~/.claude/context-guard/analyze-telemetry.py` after ~10-20 long tasks and
move them where the success/rework data says. Recurring/monitoring work has its
own economics: `.claude/rules/loops-and-watchers.md`.

## Hybrid state runtime (v8.3.16): warm transcript + authoritative state
The rules above govern WHEN to drop the transcript. What makes the drop safe at
ANY moment is the continuous execution state: `.agent/state/current.json`,
merged only via `scripts/state-patch.py` at semantic events (skill
`state-patch`). State maintenance is no longer an end-of-session emergency —
the handoff is built FROM the state at rotation points, and Context Guard's
ladder becomes the LAST safety net, not the primary economy mechanism. The
warm-cache guidance stands: short coherent stretches stay conversational;
the state runs alongside, not instead.
