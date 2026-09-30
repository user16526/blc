---
description: Turn one owner paragraph into a /run-spec spec — reads the board, the run reports and the lessons, writes specs/NNN-slug/spec.md, commits it, and hands over to /run-spec up to its plan OK.
---
`/write-spec <one paragraph>` — the ask, in the owner's words. No paragraph → ask for it
in one line, stop. The spec is written by this session (the `business-analyst` role has
no Write tool; its checklist is step 3 — no subagent writes it; step 2a's researchers
only read).

0. **Preflight.** `docs/SPEC_TEMPLATE.md` exists, `TEMPLATE_VERSION` is v8.3.26 or later
   (`sort -V`), the cwd is this project's repo root. Any miss → name it, stop.
1. **Read the context, in this order.** `tasks/board.md` — what is `[doing]` and `[done]`:
   a step that repeats a `[done]` line, or collides with a `[doing]` one, is named in Open
   questions, not written. `pre-existing` lines (`… — pre-existing, P1|P2|P3, …`) that
   touch the ask's Deliverable paths are listed FIRST under `## Open questions`, one line
   each: "include or leave?" with your recommended answer. `_reports/runs/latest.json` and the newest reports in
   `_reports/runs/` — the last verdict, its open findings, and the proof types this project
   actually produces (those are the DoD vocabulary). `tasks/lessons.md` — every lesson
   touching the ask becomes a stop condition or a DoD clause, so it is not re-learned. The
   PROJECT block of `AGENTS.md` for the source of truth and what "verified" means here.
2. **Ground every step.** Deliverables are paths, not topics. `Touches` comes from a grep
   of each Deliverable path's callers and consumers, and the grep is recorded beside it.
   A DoD is a command with its expected output, or a named test — never "works". Row from
   the RISK MATRIX, highest risk touched. Any step that deletes or overwrites fills
   `Persist before act`. Context taken from a log is the real line, verbatim.
2a. **Research the design choices — `choice` steps only.** Classify each step's `Kind`
   while drafting (`docs/SPEC_TEMPLATE.md`): the triggers are checkable, not a judgement
   call. `fix` and `build` are never researched. More than 2 `choice` steps → stop with
   "split: design spec first". For each `choice` step dispatch ONE fresh-context subagent
   (the built-in `general-purpose` agent), prompted read-only: WebSearch, WebFetch, Read,
   Grep, Bash only for read-only measurement — never write, never install. Evidence order:
   1 measure in this repo if a ≤10-min read-only experiment decides it; 2 primary sources
   (official docs, source code, papers, changelogs); 3 blogs/forums as leads only — a claim
   resting on them alone is `unverified`. Box: ≤8 searches, ≤5 fetches, ≤1 experiment;
   exhausted → the brief with what exists, `Confidence: low`, never a loop. It returns
   ≤40 lines shaped like `docs/RESEARCH_BRIEF_TEMPLATE.md`; save them as
   `specs/NNN-slug/research/Sxx.md`. Write the recommendation INTO the step's
   Deliverable / DoD and add its `- **Research:**` line. A decision packet (format and
   evidence rule: `.claude/rules/communication.md`) goes to the owner ONLY if confidence is
   low AND the step's Row is HIGH, or the options differ in money / irreversibility — max
   1 per spec, shown above the plan with the open questions (step 6).
3. **Ambiguities are questions, never guesses** (the `business-analyst` checklist: goal,
   out-of-scope, states to handle, acceptance criteria, how it is verified). Two readings
   with different outcomes, a fact only the owner has, a missing decision → one line each
   under `## Open questions`, with your recommended answer. Zero questions is fine; an
   invented answer is not.
4. **Write the spec** to `specs/NNN-slug/spec.md`, NNN = the next free three-digit number
   in `specs/` (`001` when empty), slug from the ask. Every `<…>` of the template filled;
   its stock stop conditions and allowlist kept as written. The step-2a briefs sit beside
   it in `specs/NNN-slug/research/`.
5. **Commit the spec and its research briefs alone** — `spec(NNN-slug): <title>`. Nothing
   else in that commit.
6. **Hand over to `/run-spec specs/NNN-slug/spec.md`** and stop where its step-5 pause
   stops — that pause is the one pause for spec and plan together. Open questions go ABOVE
   the plan in that message; the owner's one reply answers them and OKs the plan. Write
   the answers into the steps, delete the section, commit the spec again, and only then
   let `/run-spec` write its marker: the plan hash is over the spec as committed. An answer
   that changes a step's Deliverable, DoD or Row → recompile and show the plan again; that
   second pause is the new fact, not the rule.

Never: install anything, run the steps, write outside `specs/NNN-slug/` before the OK.
Research happens here only, never during `/run-spec`: after the plan hash it is scope
drift → STOP.
