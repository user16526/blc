# Template upgrade run — 2026-09-01 23:20

## Verdict: GREEN ✅

## Inputs
- Procedure: `UPGRADE.md` §0–5 (merge route), routed from
  `D:\claude\1-claude-templates\update-new.txt`
- Artifact: `D:\claude\1-claude-templates\template-v8.3.19-all-in-one.zip`
  → canonical build `release/v8_3_19.zip`,
  sha256 `de4e823ee474381f66b5c43f79fbf1209bc6c3e270d2998b92e381d21d317ced`
  — matches the shipped `release/v8_3_19.sha256`
- Old side for the three-way compare: `old-templates-dont-touch/template-v8.3.16-all-in-one.zip`
- FROM → TO: **v8.3.16 → v8.3.19** (`TEMPLATE_VERSION`, not recollection)
- HEAD at start: `07e6615` (branch `main`, the checkpoint commit carrying the
  same-day devops audit) · upgrade branch `template-upgrade-v8.3.19`
- Rollback line, stated before starting: `git switch main` → `07e6615`

## Phases
- **Route**: same major, every v8 marker present, `CLAUDE.md` identical upstream
  between FROM and TO → merge, not transplant. **No CORE change, no Kernel Change
  Rationale, no re-baseline** (gate: "CORE matches baseline").
- **Intent read**: v8.3.17 = BLC's own D3/D4 closed at source. v8.3.18 = START-HERE
  version literal de-rotted (docs only). v8.3.19 = `scripts/release-check.sh`, the
  release gate that verifies from the built artifact.
- **Classification** (96 template files, CR-stripped, three-way old/new/ours):
  89 identical upstream · 6 replaced · 1 new · **0 hand-merges** · 13 project-owned
  skipped (one upstream line appended to `tasks/lessons.md`).
- **Build**: copy, then `setup.sh`, then `git add --renormalize .`.
- **Verify**: probe, suite, self-tests, Context Guard, gate (below).

## Findings (numbered, severity-tagged)
1. 🟢 **D3 closed on this tree.** `python3 scripts/state-patch.py --self-test` is
   GREEN under the default console, under `PYTHONIOENCODING=utf-8` and under
   `PYTHONIOENCODING=cp1252`. The v8.3.16 workaround note is retired.
2. 🟢 **D4 class fix holds in v8.3.19.** The wrapper's `template-v8.3.19/` folder
   ships no stray env file and no empty `.claude/handoffs/`; the only file present
   upstream in v8.3.16 and absent in v8.3.19 is that stray env file itself.
3. 🟢 **`release-check.sh` and `build-release.py` are maintainer-tree tools.** They
   exit 2 ("not the canonical tree") in a project by design; their change is taken
   for fidelity but not exercised here. Exec bit set in the index (100755).
4. 🟡 **Survival test pending, not waived.** Executable bytes changed
   (`state-patch.py`), so the §5 waiver does not apply. The self-test exercises the
   changed code; the survival task is the next BLC product task the owner gives.
5. 🟡 **Sheriff pass owed by policy, toggle off.** UPDATE POLICY says an additive
   delta still owes a sheriff pass; the PROJECT toggle is off, so only `--probe`
   ran (OK). Same treatment as the v8.3.16 run.

## Evidence
- `bash scripts/sheriff-review.sh --probe` → OK, automation available
- `bash scripts/test-hooks.sh` → PASS 146 / FAIL 0
- `state-patch.py --self-test` → GREEN ×3 (default, utf-8, cp1252)
- `python3 ~/.claude/context-guard/verify-install.py --project .` → GREEN 4.2.4
- `./scripts/quality-gate.sh` → GREEN on the merge commit (see `latest.json`)

## Decisions taken mid-run
- Merge, not transplant; nothing hand-merged; project-owned bucket untouched except
  the one appended lessons line.
- The devops audit's proposed edits F9-F14 stay pending the owner's resolution —
  not folded into this upgrade (`docs/model-audit-recommendations_2026-09-01_2301_v1.md`).
- `temp/template-new/` and `temp/template-old/` left for the owner to delete: the
  guard blocks recursive deletes from the agent session.

## Next steps
- [ ] Owner: `rm -rf temp/template-new temp/template-old` (gitignored scratch)
- [ ] Survival test = next BLC task end-to-end under v8.3.19
- [ ] Owner resolves F9-F14 (apply / veto)

## Artifacts
- `_reports/runs/template-upgrade-v8.3.19_2026-09-01.md` (this report)
- `.agent/state/decisions.md` (dated entry)
- `tasks/lessons.md` (+1 upstream [release] line)
- `TEMPLATE_VERSION` = v8.3.19
