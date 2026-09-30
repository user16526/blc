# Run Report Template (R5)

Copy this to `_reports/runs/{pipeline}-run_{YYYY-MM-DD}_{HHMM}.md` at the end of
every pipeline run. This file is the single source of truth for the run — not chat.

Its machine-readable twin is `_reports/runs/latest.json` (skeleton:
`_reports/runs/latest.json.template`). **Row, Builder and Reviewers below must say the
same thing as `row`, `builder` and `reviewers` there.** The gate reads the JSON and
never this prose, so a report naming a reviewer the JSON does not name is a report
whose review the gate has not seen.

```markdown
# {Pipeline} run — {YYYY-MM-DD HH:MM}

## Verdict: GREEN ✅
<!-- One of GREEN ✅ / YELLOW 🟡 / RED 🔴, as the FIRST word after `Verdict` on the heading,
     or as the first word of the first plain line under it. Anything else there ("Not
     GREEN", a sentence) BLOCKS the gate; comments and code blocks are skipped. Write only
     the final value: a second one there (`~~GREEN~~ RED`, `GREEN → RED`) BLOCKS too. -->
<!-- A report appended to (one file, several runs) names the run on every Verdict
     heading — `## Verdict — run <run_id>: GREEN ✅`, `<run_id>` exactly latest.json's; the
     gate reads only the heading that names the current run. -->

## Inputs
- Spec: {path, version}
- Mockup: {path, if any}
- HEAD: {git sha}
- Row: {LOW | NORMAL | HIGH | DESTRUCTIVE — the RISK MATRIX row this run was gated at}
- Builder: {the agent that produced the change — an active agent in `.claude/agents/`,
  or `orchestrator` for the main session; e.g. block-executor}
- Reviewers: {the agents that reviewed it — none may be the Builder; on HIGH and
  DESTRUCTIVE, one distinct reviewer per touched risk}
- research: {choice_steps: <n>, briefs: <n>, owner_trips: <n>}
<!-- research: /run-spec runs only; owner_trips must be 0 — a trip is the owner carrying
     research into the session. Keep a comment on its own lines: the gate BLOCKS one that
     opens mid-line and closes on a later line. -->

## Phases
- Spec: {what happened}
- Plan: {which plan chosen / merged}
- Build: {blocks done}
- Verify: {what each layer found}

## Findings (numbered, severity- and origin-tagged)
<!-- origin: introduced = this diff caused it | pre-existing = there before this diff.
     The verdict counts `introduced` only; `pre-existing` go to tasks/board.md
     (`orchestration` skill, step 4). -->
1. 🔴 [introduced] {title} — {what} — {where} — {recommended fix}
2. 🟡 [pre-existing] {…}
3. 🟢 [introduced] {…}

## Decisions taken mid-run
- {decision + why}

## Next steps
- [ ] {action}

## Artifacts
- {path to plan}
- {path to reviews}
- {path to code / PR}
```

Findings also get copied to `_reports/lessons/` (one-offs) or `_reports/postmortem/`
(incidents) so they outlive this run.
