# Template upgrade run — 2026-09-02 02:25

## Verdict: GREEN ✅

## Inputs
- Procedure: `UPGRADE.md` §0–5 (merge route), routed from
  `D:\claude\1-claude-templates\update-new.txt`; owner asked to run to the end
  unattended ("continue to the end … auto mode").
- Artifact: `D:\claude\1-claude-templates\v8_3_21.zip` (canonical form; the
  all-in-one wrapper is retired as of v8.3.20). sha256 computed here:
  `c93041a8e9d95d3502022b9d146b4aae2b07b9487c88a41b23eb63cdb852d1a1`.
  **No `.sha256` companion was shipped beside the zip** — the hash could not be
  verified against a published value (see finding 4).
- Old side for the three-way compare: `old-templates-dont-touch/v8_3_19.zip`,
  sha256 `de4e823e…` — matches its shipped `v8_3_19.sha256`.
- FROM → TO: **v8.3.19 → v8.3.21** (`TEMPLATE_VERSION`, not recollection).
- HEAD at start: `3ad6e4e` (branch `main`, clean) · upgrade branch
  `template-upgrade-v8.3.21`.
- Rollback line, stated before starting: `git switch main` → `3ad6e4e`
  (branch kept for rollback after the merge).

## Phases
- **Route**: same major, every v8 marker present, `CLAUDE.md` byte-identical
  upstream between FROM and TO → merge, not transplant. **No CORE change, no
  Kernel Change Rationale, no re-baseline** (`.claude/core.sha` = `ec9f3774…`,
  unchanged).
- **Intent read**: v8.3.20 = distribution collapsed to ONE zip = ONE folder;
  docs + release-side `release-check.sh` only ("No project-runtime code
  changed"). v8.3.21 = no field project named anywhere in the template
  (A/B/C aliases); every touched script line is a comment, plus the
  release-side blankness gate and one build exclude. **Zero behavior change
  in the project runtime** — confirmed by diffing the non-comment lines of
  every replaced script (only `build-release.py` / `release-check.sh`, which
  exit 2 inside a project, carry code).
- **Classification** (108 template files, CR-stripped, three-way old/new/ours):
  78 identical upstream · **13 replaced** · 0 new · **0 hand-merges** ·
  16 kept ours (template unchanged, BLC-modified) · 1 project-owned 3-way
  (`.agent/state/decisions.md`, preserved) · **1 deletion** (`TEMPLATE-DELTA.md`,
  byte-identical to the old template here, deleted upstream).
- **Build**: copy 13, `git rm TEMPLATE-DELTA.md`, `bash setup.sh` (re-installed
  the git hook: `.git/hooks/pre-commit` == `scripts/pre-commit`), then
  `git add --renormalize .` (no line-ending churn).
- **Verify**: probe, suite, self-test, Context Guard, gate (below).

## Findings (numbered, severity-tagged)
1. 🟢 **Replaced set is comments + release-side gate only.** `scripts/pre-commit`,
   `quality-gate.sh`, `test-hooks.sh`, `state-patch.py`,
   `sheriff-isolation-live.sh`: field-project names → A/B/C in comments, no
   code lines changed. `build-release.py`: +1 exclude (`release-blocklist.txt`).
   `release-check.sh`: blankness sweep from the blocklist, rot check covers
   `CLAUDE.md = N lines`; exits 2 here ("not the canonical tree") by design.
2. 🟢 **Kept ours on 16 files, all with the template side unchanged FROM→TO**
   (`CLAUDE.md`, `.claude/settings.json`, `.gitignore`, `.env.example`,
   `docs/ROLES.md`, `tasks/*`, `.agent/state/*`, `communication.md`,
   `orchestration/SKILL.md`, both sheriff files). Sheriff files: the BLC-local
   prompt divergence is recorded canonical in `decisions.md`; the template's
   copies did not move, so nothing new to reconcile.
3. 🟡 **`decisions.md` seed line still names a field project.** The template's
   own `decisions.md` renamed its 2026-08-30 seed line ("… copy from
   hermipro-vps" → "field project A"). Our copy is project-owned
   (preserve/append only) and BLC is itself one of the referenced field
   projects, so the line was left as is. Cosmetic; owner's call whether to
   apply the alias inside a field project.
4. 🟡 **No `.sha256` companion for `v8_3_21.zip`.** `update-new.txt` step 1
   says to verify it before unpacking; none exists in the release folder. The
   hash computed here is recorded above so the owner can compare it against
   the canonical tree's `release-check.sh` output. Upgrade proceeded because
   the zip's content matches the v8.3.21 CHANGELOG exactly (file-level diff).
5. 🟢 **UPGRADE.md §4 devops audit — satisfied by the 2026-09-01 audit, not
   re-run.** The audit is 1 day old against the current Fable 5.1 guide, the
   delta names no crutches to cut, and no instruction text changed in the
   project. Re-running would be ritual. `model-audit.md` `Last audited:`
   therefore NOT bumped.
6. 🟢 **§5 survival-test waiver applies.** ZERO executable bytes changed in the
   project runtime (finding 1). Owner's unattended "continue to the end" is
   taken as the explicit OK to waive; recorded here as the waiver. The suite
   and the probe still ran on the post-merge tree.
7. 🟡 **Sheriff pass owed by policy, toggle off.** "Additive is a merge rule,
   not a review waiver" — toggle is off, so only `--probe` ran (OK). Same
   treatment as the v8.3.16 and v8.3.19 runs.

## Evidence
- `bash setup.sh` → exit 0
- `bash scripts/sheriff-review.sh --probe` → OK, automation available
  (codex-cli 0.151.0-alpha.7.2, all required flags present)
- `bash scripts/test-hooks.sh` → PASS 146 / FAIL 0, HOOKS: GREEN
- `python3 scripts/state-patch.py --self-test` → GREEN
- `python3 ~/.claude/context-guard/verify-install.py --project .` → GREEN 4.2.4
- `bash scripts/release-check.sh` → exit 2 "not the canonical tree" (expected)
- `./scripts/quality-gate.sh` → GREEN on the merge commit (see `latest.json`)
- Sheriff live canary: skipped — PROJECT toggle is off.

## Decisions taken mid-run
- Merge, not transplant; nothing hand-merged; project-owned bucket untouched
  except the appended `decisions.md` entry and the state patch.
- Deleted `TEMPLATE-DELTA.md` (the template deleted it; our copy was
  byte-identical to the old template, so no project content was lost). Its
  one open follow-up (secret-patterns hardening candidate) lives in the
  v8.3.21 CHANGELOG entry now carried in this repo.
- `temp/template-new/` and `temp/template-old/` left for the owner to delete:
  the guard blocks recursive deletes from the agent session.
- Merged to `main` in the same run on the owner's unattended go-ahead; the
  upgrade branch is kept as the rollback point.

## Next steps
- [ ] Owner: delete the two gitignored scratch folders `temp/template-new`
      and `temp/template-old` (recursive delete, agent-blocked by the guard)
- [ ] Owner: publish/compare a `.sha256` for `v8_3_21.zip` (finding 4)
- [ ] Owner: decide on the `decisions.md` seed-line alias (finding 3)
- [ ] Next devops audit (cadence 35d, last 2026-09-01) re-checks the lineup

## Artifacts
- `_reports/runs/template-upgrade-v8.3.21_2026-09-02.md` (this report)
- `.agent/state/decisions.md` (dated entry)
- `.agent/state/current.json` / `current.md` (state patch)
- `TEMPLATE_VERSION` = v8.3.21
- `CHANGELOG.md` (v8.3.20 + v8.3.21 entries now in-repo)
