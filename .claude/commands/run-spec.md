---
description: Run an approved spec end to end — one plan OK, then the queue works through the spec's steps until the end or the first stop.
---
`/run-spec <spec path>` — a spec shaped like `docs/SPEC_TEMPLATE.md` (usually
`specs/NNN-slug/spec.md`). Running it again on the same spec resumes it.

Read `.claude/rules/automode-queue.md` first: the claim, the budget and THE stop list
live there. Automode may be on or off — the approved plan is the go-ahead here.

0. **Preflight — fail on the first miss, before anything else.** `TEMPLATE_VERSION` is
   v8.3.26 or later (`sort -V`); the spec path exists; `docs/SPEC_TEMPLATE.md` exists.
   Name the miss, stop. (An older template has no `/run-spec` contract to hold a run to.)
1. **Check the spec.** It needs numbered steps, each with an exact Deliverable, a `DoD:`
   naming the proof, and a Row; Non-goals; Stop conditions. A `Spec format: 2` spec also
   needs `Kind:` on every step (the gate lints it; see `plan-compiler`). Anything missing →
   say what, stop.
2. **Roster** — `orchestration` skill, step 0.
3. **Resume?** If `tasks/board.md` already holds this spec's approval marker (step 5):
   - recompute the plan hash — `tr -d '\r' < <spec> | sha256sum | cut -c1-12` — and
     compare it with the marker's `plan:`. Equal → the recorded OK holds, in this session
     or a new one (`.claude/rules/go-ahead-scope.md`): go to step 6, no second OK.
   - different, or the marker carries no `plan:` (written before v8.3.27) → that OK is
     void: show the spec's changes since the approved hash (`git log -p -- <spec>`) and
     the remaining steps with their rows, ask for a one-line OK; on OK re-run step 4 and,
     in ONE commit, rewrite every step line that is not `[done]`, the marker's step range
     and its `plan:` (the current hash) — the queued lines must match the spec the hash
     attests to — then go to step 6. No OK → stop.
4. **Compile.** Run `plan-compiler` on the spec. It returns the execution blocks and one
   board line per step (format below). It writes nothing.
5. **Plan OK — the one pause.** Show the steps with their rows and DoD, the reviewers each
   row brings, the spec's stop conditions, and the budget (= the steps listed). Wait for
   the owner's OK. This pause happens even with automode on — it IS the approval, and it
   covers each step up to the row the plan declares for it. No OK → nothing is written.
   When `/write-spec` led here, the spec's open questions stand above the plan and are
   answered in the same reply; the answers go into the spec and are committed BEFORE the
   hash below is taken.
   On OK: append under `## Active` in `tasks/board.md` the marker
   `<!-- spec:<id> — plan approved <date>; steps S01–S<NN>; plan:<sha12> -->`
   — `<sha12>` = the step-3 hash of the spec file as committed (the recorded OK holds for
   exactly that file) — and then
   one line per step, in step order — plan-compiler's lines verbatim. A step it could not
   queue (row DESTRUCTIVE, or no DoD) is written in its place as a stop line without
   `@auto`: `- [review] S<NN> <deliverable> @spec:<id> — STOPPED: <reason>`. Commit that
   change alone.
6. **Run the queue — strictly in step order.** Take the next line of this spec among the
   steps the marker lists (a `@spec:<id>` line whose step is not listed there is never
   taken):
   - `[done]` → skip it;
   - `[todo]` → claim it (`[doing]`, commit) → do the step at its row: build; NORMAL →
     `verifier`; HIGH → one reviewer per touched risk + `verifier`; SHERIFF on →
     cross-review after GREEN → append the step's section to the spec's run report
     `_reports/runs/<spec-id>_<date>.md` — its verdict heading is
     `### Verdict — run <run_id>`, `<run_id>` exactly the `run_id` written to `latest.json`
     for this step (suggest `<spec-id>-S<NN>`) — flip the line to
     `- [done] … → <report path>`, and commit work + report + tick TOGETHER — the commit
     that records the step's proof ticks its line, never a later sweep → write `latest.json`
     bound to that commit (`spec` = the spec path, `report` = the spec's run report) → the
     step's gate (`quality-gate.sh`; `--trivial` only for a LOW step) on it. The gate
     needs a clean tree and a report bound to HEAD, which is why the commit comes first;
     a BLOCKED gate reverts the tick in the fix commit — the step is not done;
   - anything else (`[doing]`, `[review]`) → stop and report it. A `[doing]` line may belong
     to another session; a `[review]` line waits for the owner to flip it to `[todo]` or
     `[done]`. Later steps are never taken past it.
7. **Stop** on anything in the automode-queue stop list, on any of the spec's own stop
   conditions, and when a step would touch files outside its Deliverable (scope drift).
   Flip that step to `- [review] … — STOPPED: <reason>`, commit, and report: which step,
   why, what is needed from the owner.
8. **End of spec.** When every listed step is `[done]`, close the run report: steps done,
   stops, `decision_sheriff: <calls> calls, <tokens> tokens`
   (`.claude/rules/decision-sheriff.md`; `0 calls` when the sheriff is off),
   `research: {choice_steps: <n>, briefs: <n>, owner_trips: <n>}` (`owner_trips` must be 0 —
   a trip is the owner carrying research into the session), and the
   verifier's consolidated verdict (a plain line, not a `Verdict` heading — the gate reads
   only the heading that names the current `run_id`). Then stop — never continue into board items outside
   this spec.

Board line — one per step, written in step 5 from plan-compiler's output:

    - [todo] S03 <exact deliverable> @auto @spec:<id> row:NORMAL DoD: <the proof that closes it>

A compaction mid-run continues the run (same session). After `/clear`, a restart or a
pause it resumes only from an explicit `/run-spec <spec>` — never by itself; the recorded
plan OK holds while the spec hashes as approved (step 3), a changed spec asks again.
