# Template defects found during the BLC pre-v8 → v8.3.13 upgrade

Found: 2026-09-01, during the transplant documented in
`_reports/runs/template-upgrade-run_2026-09-01_1330.md`.
Both are defects in the **template**, not in BLC. Releases are build products — the
fix belongs in the canonical source tree + `build-release.py`, never in a zip or in a
project patched to match one. This file exists so the two do not get lost between
upgrades; re-check both at every upgrade and delete the entries that upstream fixes.

## D1 — the shipped `pre-commit` hook blocks the shipped test suite (BLOCKING)
**Severity: blocking.** No v8 project can make its first commit without hitting it.

`scripts/test-hooks.sh` must contain synthetic secret fixtures — `sk-…`, `sk-proj-…`,
`sk-ant-…`, `ghp_…`, `github_pat_…`, `xoxb-…` — as negative controls asserting
`guard.sh` returns exit 2. `scripts/pre-commit` scans the whole staged diff against
the same `SECRET_REGEX`, so staging the suite trips its own guard:

```
✋ COMMIT BLOCKED: a hardcoded secret appears in staged changes.
```

`setup.sh` hides the ordering: it installs the hook only when `.git` already exists,
so a project that runs `git init` afterwards meets the block on its first commit.

**Fix applied in BLC (a divergence, tracked in `decisions.md`):** exclude that one
path from the scan.
```bash
if git diff --cached -U0 -- . ':(exclude)scripts/test-hooks.sh' | grep -Eq "^\+.*$SECRET_REGEX"; then
```
Verified narrow — a planted `sk-proj-…` in `temp/` is still blocked (rc=1).

**Suggested upstream fix:** the same exclusion in `scripts/pre-commit`, plus an
assertion in `test-hooks.sh` that the hook still blocks a secret in any other path
(so the exclusion can never silently widen).

## D2 — `docs/RUN_REPORT_TEMPLATE.md` produces reports `quality-gate.sh` rejects
**Severity: cosmetic, but every project hits it.**

The template writes the verdict on the line AFTER the heading:
```markdown
## Verdict
GREEN ✅ / YELLOW 🟡 / RED 🔴
```
The gate greps the FIRST line containing "verdict" and looks for GREEN/YELLOW/RED on
that same line:
```bash
rv=$(grep -iEm1 'verdict' "$latest" | grep -oEi 'GREEN|YELLOW|RED' | head -1 ...)
```
`## Verdict` carries no value, so a report written exactly to the shipped template is
rejected as *"report has no parsable verdict value"* — the gate blocks on a correct
report. **Fix applied in BLC:** `## Verdict — GREEN ✅` (value on the heading line).

**Suggested upstream fix:** either change the template to `## Verdict — {VALUE}`, or
make the gate read the first GREEN/YELLOW/RED in the ~3 lines following the heading.
Pick one and assert it in `test-hooks.sh` against a report generated from the template.
