# Pause & resume — what "continue later" actually means (always on)

Triggers: *remember this*, *pause*, *continue later*, *resume later*, *stop here*, and
their equivalents in any language the owner writes in.

A pause is not a `/clear` and not a compaction. Those drop the context and the work goes
on. **A pause means the human is leaving: the conversation stops, and only work that was
deliberately detached keeps running.**

## Semantics, in order
**persist state → stop the observers → leave detached jobs alone → stop interacting**

1. **Persist.** Patch the execution state (`state-patch` skill), then write the handoff
   (`handoff` skill). This overrides that skill's "do not stop working" step: on an
   explicit pause, stopping is the instruction.
2. **Stop the observers.** Every monitor, watcher, polling loop and background tail this
   session armed. They re-pay the whole session context per fire and die on resume
   anyway (`.claude/rules/loops-and-watchers.md`).
3. **Leave detached work running.** Systemd units, cron jobs, anything launched to
   outlive the session, and the transition watcher. Pausing a conversation is not
   stopping a job — never "tidy up" a running job on the way out.
4. **Stop interacting.** No further status lines, no ETAs, no progress notes.

## The two prohibitions
- **Never keep an interactive session alive to watch something.** If a result genuinely
  must be chased, hand it to the transition watcher *before* going quiet. That is the
  only mechanism that survives the session.
- **Never promise a proactive update.** "I'll tell you the moment it finishes" is a
  promise a closed session cannot keep: it emits no events and can start no message.
  Say where the answer will be instead, and how to read it.

## What the handoff must carry when a job is still running
Unit or job name · how to check its status · log path · result path · status at the
moment of the pause · cleanup owed when it finishes · anything that must NOT be changed
while it runs.

Without the cleanup line, a resource the job holds is never released. Without the
"do not change" line, the next session edits under a running job.

## Resume
Next session: read the saved state FIRST, then inspect the real job — the notes are
pointers, the live system is the evidence (`.claude/rules/verify-external-state.md`).
Continue from what you find, not from what the note predicted. After a `/clear` the
restore is explicit: `/continue-work`.
