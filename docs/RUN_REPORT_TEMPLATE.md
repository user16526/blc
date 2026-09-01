# Run Report Template (R5)

Copy this to `_reports/runs/{pipeline}-run_{YYYY-MM-DD}_{HHMM}.md` at the end of
every pipeline run. This file is the single source of truth for the run — not chat.

```markdown
# {Pipeline} run — {YYYY-MM-DD HH:MM}

## Verdict: GREEN ✅
<!-- one of: GREEN ✅ / YELLOW 🟡 / RED 🔴 — on the header line or the next;
     the gate reads both (D2 fix, 2026-09-01) -->

## Inputs
- Spec: {path, version}
- Mockup: {path, if any}
- HEAD: {git sha}

## Phases
- Spec: {what happened}
- Plan: {which plan chosen / merged}
- Build: {blocks done}
- Verify: {what each layer found}

## Findings (numbered, severity-tagged)
1. 🔴 {title} — {what} — {where} — {recommended fix}
2. 🟡 {…}
3. 🟢 {…}

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
