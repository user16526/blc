# Loops & Watchers — polling economics (always on)
<!-- No paths: frontmatter on purpose: this governs ANY recurring/monitoring work. -->

`/loop` and cron tasks are **session-scoped**: every fire re-runs inside the
current conversation and pays for its ENTIRE context. A 5-minute loop inside a
large working session is the single most expensive mistake available here
(observed: ~772k tokens/run, 54.8M total). All sessions share one usage limit.

## NEVER use /loop for completion-waiting
Build completion, systemd jobs, queue completion, file appearance, deploy
completion, long-running corpus jobs — none of these belong in a polling loop.

## Pick the right tier instead
1. **In-session live watching** (dev server, test run, build you're iterating on):
   the **Monitor** tool — streams background-script output line by line, no
   polling. Note: monitors die with the session and are not restored on resume.
2. **Events that can push themselves** (CI, webhooks): **Channels** — the event
   lands in the session directly.
3. **Cross-session external state** (VPS jobs, long corpus runs, deploys):
   the **transition watcher** — `scripts/watch-transition.sh`. Deterministic
   shell check costs 0 LLM tokens; Claude wakes ONLY on a state TRANSITION
   (RUNNING→SUCCESS/FAILED/ATTENTION), in a fresh bounded `claude -p` session.
   Never wake Claude merely because a logfile changed — progress is not a
   transition.
4. **Recurring maintenance on a schedule**: Desktop scheduled tasks / Routines
   (each run = fresh session), or a `/loop` in a DEDICATED clean session that
   does nothing else (~10k/run instead of ~772k).

## Watcher safety contract
Unattended `claude -p` runs are analysis-only: `--max-turns` bounded, default
permission mode (NEVER `--permission-mode acceptEdits` unattended — RISK MATRIX
applies to machines too), output goes to a report file; any code change goes
through a normal supervised session. The watcher itself must be transition-only,
idempotent across restarts, cooldown-limited, and have a daily wake budget plus
a max-quiet timeout so a hung RUNNING state still surfaces once.

Emergency stop for all loops/scheduled tasks: `CLAUDE_CODE_DISABLE_CRON=1`.
