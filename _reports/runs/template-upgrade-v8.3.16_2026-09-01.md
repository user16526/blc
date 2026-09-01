# Template upgrade run — 2026-09-01 20:20

## Verdict: GREEN ✅

## Inputs
- Procedure: `UPGRADE.md` §0–5 (merge route), routed from
  `D:\claude\1-claude-templates\update-new.txt`
- Artifact: `D:\claude\1-claude-templates\template-v8.3.16-all-in-one.zip`
  → canonical build `release/v8_3_16.zip`,
  sha256 `b967869dc274a938b1b6c5144a4b3bd46d00ffd6c5a632356782c1f4138f2fd4`
  — matches the shipped `.sha256`
- FROM → TO: **v8.3.13 → v8.3.16** (`TEMPLATE_VERSION`, not recollection)
- HEAD at start: `2b0cd2d` (branch `main`) · upgrade branch `template-upgrade-v8.3.16`
- Rollback line, stated before starting: `git checkout main` → `2b0cd2d`

## Phases
- **Route**: same major and the project carries every v8 marker → merge (steps 2–5),
  not transplant. `.claude/core.sha` is byte-identical on both sides
  (`ec9f3774f581b09c572c5f2312b3abe03765c305cd86f3fe6aaada1a9272d11b`) →
  **no CORE change, no Kernel Change Rationale, no re-baseline**.
- **Intent read**: every CHANGELOG entry between FROM and TO.
  v8.3.14 = the fixes for BLC's own findings D1/D2. v8.3.15 = versioning policy
  (suffix retired) + `communication.md` + `START-HERE.md`. v8.3.16 = hybrid
  execution state.
- **Classification** (109 template files, compared CR-stripped per §2):
  80 identical · 18 taken from the template · 2 hand-merged · 9 kept ours.
- **Build**: copy + two hand-merges, then `setup.sh`.
- **Verify**: suite, self-test, probe, gate (below).

## Findings (numbered, severity-tagged)
1. 🟢 **D1 and D2 are closed at the source.** v8.3.14 shipped both fixes that this
   project reported in `docs/template-defects-owed-upstream_2026-09-01_v1.md`.
   `scripts/pre-commit` now carries the `test-hooks.sh` exclusion **and** a suite
   assertion that it stays narrow; `scripts/quality-gate.sh` reads the `## Verdict`
   header line *and* the next one. Both local workarounds were dropped for the
   shipped versions. **Risk R1 dissolves** and the only open loop from the previous
   upgrade closes. Proved live: this branch's first commit staged
   `scripts/test-hooks.sh` with its synthetic secrets and was **allowed**.
2. 🟡 **D3, new, owed upstream — `scripts/state-patch.py --self-test` crashes on a
   default Windows console.** `print("✓ …")` raises `UnicodeEncodeError` under
   cp1252; the run dies at the first assertion. Suggested upstream fix: wrap
   `sys.stdout` with `errors="replace"` (or use ASCII `[ok]`/`[FAIL]` markers) at
   the top of `self_test()`. Workaround here: `PYTHONIOENCODING=utf-8`, under which
   the suite is 9/9 GREEN. Cosmetic in effect, but it makes the release's own
   stated verification step unusable out of the box on this platform.
3. 🟡 **Shipped folder ≠ canonical build (minor hygiene, upstream).**
   `template-v8.3.16/` in the all-in-one zip contains a stray `.env` that the
   canonical `release/v8_3_16.zip` does not (109 vs 108 files). It is a byte-copy of
   `.env.example` left behind by a `setup.sh` run in the staging tree — no real
   values — but a template folder that ships a `.env` is one careless `cp -r` away
   from a project committing one. Not copied here.
4. 🟢 **`TEMPLATE-DELTA.md` is a hermipro-vps delta report**, shipped as payload in
   the canonical build. Taken as-is for fidelity; it describes another project, so
   it is release provenance here, not BLC state.

## Decisions taken mid-run
- **Merge, not transplant** — same major, all v8 markers present, CORE identical.
- **Took the template verbatim** for `scripts/{pre-commit,quality-gate.sh,build-release.py,state-freshness.sh,test-hooks.sh,state-patch.py}`,
  `docs/RUN_REPORT_TEMPLATE.md`, `.claude/rules/{context-hygiene,communication}.md`,
  `.claude/skills/{cross-review,handoff,state-patch}/SKILL.md`,
  `.agent/state/state-schema.json`, `CHANGELOG.md`, `START-HERE.md`,
  `TEMPLATE-DELTA.md`, `temp/.gitkeep`, `TEMPLATE_VERSION`.
- **Kept ours** where the template portion was unchanged and only BLC lines were
  added — a template overwrite would have silently deleted project content:
  `.gitignore`, `docs/ROLES.md`, `.claude/settings.json`, and all of
  `.agent/state/*`, `tasks/*`, `.agent/capsules/*`, `.claude/agents/*`.
- **Hand-merged two files.** `CLAUDE.md`: MY RULES' ADHD bullet replaced by the
  template's pointer to the new `.claude/rules/communication.md`, BLC's scope-limit
  rule kept; the FIRST RUN block stays deleted (onboarding is done here).
  `.agent/state/context-index.md`: took the new `current.json`-authoritative and
  `state-schema.json` lines, kept the BLC capsule/mockup/client-material pointers.
- **Adopted the new execution state rather than merely installing it.** Two patches
  seeded `current.json` from the previous `current.md`, so nothing was lost when
  `current.md` became a rendered view — including the unresolved
  `index4.html`-vs-client question, which survives as an open loop.
- **Survival test waived** under the §5 WAIVER: this upgrade changes zero
  BloodyCase deliverable bytes (no mockup, capsule or client file touched), and the
  executable change is the template's own machinery, which the 146-assertion suite
  and the gate exercise directly on the post-merge tree.
- **`devops` skill (step 4) not run**: the audit is 35 days old and due, but it is a
  model/vendor-guide audit, not part of this merge — it is a separate task and is
  recorded as such rather than folded in silently.

## Next steps
- [ ] Report D3 (and the stray `.env`) upstream at the next template build.
- [ ] Run the `devops` audit — flagged overdue by the SessionStart hook, unrelated
      to this upgrade.
- [ ] Merge `template-upgrade-v8.3.16` into `main` after owner OK (UPGRADE.md §5).

## Artifacts
- Procedure: `UPGRADE.md`
- Upgrade commit: `99163af` on `template-upgrade-v8.3.16`
- Previous defect write-up, now closed upstream:
  `docs/template-defects-owed-upstream_2026-09-01_v1.md`
- Execution state: `.agent/state/current.json` (+ rendered `.agent/state/current.md`)

## Evidence
```
release zip sha256    b967869d…  == shipped .sha256                 MATCH
core.sha ours vs TO   ec9f3774…  == ec9f3774…                       IDENTICAL
bash setup.sh                                                       rc=0
bash scripts/check-core.sh                                          rc=0
bash scripts/check-claude-md-size.sh   CLAUDE.md 213 / cap 250       rc=0
bash scripts/sheriff-review.sh --probe  codex-cli 0.147.0-alpha.6.6  OK
python3 scripts/state-patch.py --self-test      9/9                  GREEN
bash scripts/test-hooks.sh              PASS 146  FAIL 0             GREEN
first commit staging test-hooks.sh (D1 live proof)                   ALLOWED
./scripts/quality-gate.sh                                            GREEN
```
