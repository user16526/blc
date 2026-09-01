---
name: pipeline
description: The end-to-end team pipeline from idea to shipped feature. Use for any non-trivial feature or project where multiple roles and a build are involved.
---

# Pipeline: Idea → Spec → Plan → Build → Verify → Deploy

Run roles as subagents (see docs/ROLES.md). Two human approval gates: after Spec,
after Plan. Each phase writes a persistent artifact — never just chat.

## Phase 0 — Idea
You + Claude as sounding board. Output: rough spec v0 (what, why, for whom, risks).
Timebox ~30–60 min. Save as `…_v0.md` (timestamped — see artifact-versioning rule).

## Phase 0.5 — Research (before you commit to an approach)
Don't plan on stale training knowledge. For any real library/API/approach choice,
research the CURRENT state first (use `/research` or WebSearch/WebFetch + the repo).
Output a short brief: current options, tradeoffs for THIS project, a recommendation
with the date of the sources. For facts about OUR live systems, run
`scripts/check_live_state.py` instead (see `verify-external-state` rule). Skip this
phase only on the LOW row of the RISK MATRIX.

## Phase 1 — Spec
1. v0 → v1: expand to the full spec format (use the scope-and-spec skill for depth).
2. `business-analyst` reviews: completeness, ambiguity, missing acceptance criteria → v2.
3. `architect` reviews: NFRs, dependencies, risks → v3.
4. **GATE: I approve the spec v3 before any planning.**
Output: `spec_<date>_v3.md` (+ HTML version if sharing with a client).

## Phase 2 — Plan
One `plan-compiler` produces the plan. **Best-of-3** (3 plan-compilers →
`business-analyst` merges) is an ESCALATION for the DESTRUCTIVE/CRITICAL row or
genuinely ambiguous specs — not the default; each extra run costs real tokens.
Output: blocks, dependencies between blocks, list of files to create/change.
**GATE: I approve the plan before building.**

## Phase 3 — Build (verification-first)
**Define verification before implementation.** Pick the proof from this table —
don't invent it per task, and don't force a test where the proof is something else:

| Work type | Canonical proof (defined BEFORE building) |
|---|---|
| Business logic / algorithms | failing test first (TDD), then green — durable test value |
| UI / CSS / layout | before/after screenshots, mobile + desktop, key states |
| Infra / config / VPS | health check passes + config validation + rollback line tested |
| Content / copy | checklist vs the brief (claims, tone, CTA, legal) |
| Data migration | dry-run on a copy + row/entity counts match + rollback tested |
| One-off script | output on sample data shown + edge case demonstrated |
| Exploratory prototype | the question it answers, answered — then archive or promote |

Use TDD when the behavior is testable and the test has durable value; otherwise the
table's proof IS the verification. Then N `block-executor` subagents, one block
each, build until their proof is met. Keep each executor focused (small context).

## Phase 4 — Verify (risk-based, parallel)
Use the `orchestration` skill to pick reviewers by the risks the change touches
(per the RISK MATRIX row: one reviewer per touched risk). They run in parallel and independently:
- `functional-verifier` — smoke + critical paths + edge cases.
- `ui-ux-qa` — built UI vs mockup (spacing, colors, states, a11y, mobile).
- `security-reviewer` + `code-reviewer` — diff review (when those risks apply).
Then `verifier` (head) consolidates and either GREENs or sends back to Build with
findings (feedback loop). Show evidence at every layer.

## Phase 5 — Deploy
Use the `deploy` + `checkpoint` skills. local → dev → staging → prod, smoke at each.

## End of run — REQUIRED
Write a run report to `_reports/runs/` (template in `docs/RUN_REPORT_TEMPLATE.md`):
verdict GREEN/YELLOW/RED, inputs (spec + HEAD sha), phases, numbered findings,
decisions taken, next steps, artifact paths. That file is the single source of
truth for the run.

## Resuming after a context reset (long runs)
The artifacts ARE the checkpoint — a run survives a blown context. If the session
gets too long or you start fresh mid-task: open a new session and read, in order,
`.agent/state/current.md`, `_reports/runs/latest.json`, the active spec, then
`tasks/lessons.md`. Pick up from the last completed phase. Never restart from chat
memory — restart from the durable artifacts. (This is why every phase writes a file
instead of leaving state in chat.)
