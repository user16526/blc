# Template upgrade run — 2026-09-01 13:30

## Verdict — GREEN ✅
<!-- The value must sit on the heading line: quality-gate.sh greps the FIRST line
     containing 'verdict' and looks for GREEN/YELLOW/RED on it, so the
     'heading then value on the next line' shape in docs/RUN_REPORT_TEMPLATE.md
     does not parse. Template mismatch, logged as finding 6. -->

## Inputs
- Spec: `D:\claude\1-claude-templates\update-new.txt` → `UPGRADE.md` **section T** (transplant)
- Template: `D:\claude\1-claude-templates\v8_3_13-cg4.zip` → `TEMPLATE_VERSION` = v8.3.13
- FROM: pre-v8, unversioned in-house BLC framework (seeded 2026-04-21)
- Inventory: `_reports/migration-pre-v8-to-v8.3.13_2026-09-01.md`
- HEAD: cc77d5b (branch `template-upgrade-v8.3.13`)

## Phases
- **Checkpoint** — the project was not a git repo at all. `git init`, full baseline
  commit `863ef05` on `main`, work branch `template-upgrade-v8.3.13`.
  Rollback line: `git checkout main` → `863ef05`.
- **Route** — transplant, not merge: no CORE sentinel, no `.claude/core.sha`, no
  `.agent/state/`, no `TEMPLATE_VERSION`. The old framework was a different lineage.
- **Inventory** — every file classified into project-knowledge vs old-machinery.
  Quarantine list: empty.
- **Skeleton** — v8.3.13 stood up clean; knowledge poured into its homes per the
  `memory-router` skill (2 capsules, `current.md`, `decisions.md`, `open-loops.md`,
  `tasks/lessons.md`, `docs/ROLES.md`, CLAUDE.md PROJECT / STACK / MY COMMANDS / MY RULES).
- **Audit of transplanted instructions** — `memory: project` dropped and the 30-entry
  `tools:` dump trimmed on both gaming agents; `model: sonnet` deliberately untouched.
- **Verify** — below.
- **Survival task** — a real BLC-shaped task: serve `mockups/main002` on :8099 and
  screenshot `index4.html` at 1440×900, the project's own declared "verified means".

## Findings (numbered, severity-tagged)
1. 🟡 **The template's `pre-commit` hook blocks the template's own test suite.**
   `scripts/test-hooks.sh` must contain synthetic `sk-…` / `ghp_…` / `xoxb-…`
   fixtures as negative controls proving `guard.sh` exits 2; the shipped hook scans
   every staged file and refuses the commit. No v8 project can make its first commit
   without hitting this. Fixed here by excluding that one path from the scan
   (owner-approved). Negative control run afterwards: a planted `sk-proj-…` in
   `temp/` is still blocked, rc=1. **Owed upstream — this is a template defect.**
2. 🟢 **Trust-pill copy conflict — RESOLVED.** The old design system said "From $0.06",
   `index4.html` ships "From $0.39", and the live site's cheapest case is $0.11
   [verified 2026-09-01 via WebFetch]. All three are snapshots of a moving number, so
   none of them is "the approved copy". Resolution: the pill is LIVE DATA, not a design
   token — the capsule now states the invariant (*the pill equals the cheapest case
   price displayed on that same page*), which makes `index4.html` correct as-is
   ($0.39 pill, $0.39 cheapest card). No mockup edited. Lesson appended.
3. 🟢 `.claude/rules/local-first.md` (SQLite→cloud migration) had no referent in this
   project at all — BLC holds no database and no application code. Retired, not merged.
4. 🟢 `manifest.md` / `repo_access=private-solo` pointed at two scripts that never
   existed here (`switch-repo-access.sh`, `migrate.sh`). Retired.
5. 🟢 `index4.html` logs one console error: `favicon.ico` 404. Pre-existing, cosmetic,
   unrelated to the upgrade.
6. 🟢 **`docs/RUN_REPORT_TEMPLATE.md` does not satisfy `quality-gate.sh`.** The template
   puts the verdict on the line AFTER the `## Verdict` heading; the gate greps the first
   line containing "verdict" and looks for GREEN/YELLOW/RED on that same line, so a report
   written to the shipped template is rejected as "no parsable verdict value". This report
   uses `## Verdict — GREEN ✅`. Cosmetic, but every project hits it. Owed upstream.

## Decisions taken after the first gate (owner: "fix all of your own decisions")
- **Trust-pill price** — not "pick $0.06 or $0.39": the number tracks a live value, so
  it stops being a design token and becomes an invariant. index4 unchanged.
- **Model** — both gaming agents sonnet → opus. `model-selection.md` gives the strongest
  model to judgment work, and with no code in this project every task they run IS
  judgment work; the shipped roster puts every analyst/reviewer on opus and only
  `block-executor` on sonnet.
- **Persona trim** — the ~120-line tail of each agent instructed it to write to
  `.claude/agent-memory/<agent>/`, retired hours earlier. Dead instruction aimed at a
  nonexistent path that would have rebuilt the store the workspace contract forbids.
  Cut and replaced with real v8 routing; all domain expertise kept verbatim.
- **Template defects** — written up in `docs/template-defects-owed-upstream_2026-09-01_v1.md`
  and logged as risk R1, since they cannot be fixed from inside this project.

## Decisions taken mid-run
- Transplant over merge — no v8 markers present (see decisions.md).
- Retire the 7 pre-v8 rules rather than merge them: each guarantee is now owned by a
  named v8 mechanism.
- Retire `.claude/agent-memory/`: the workspace contract and `memory-router` both
  replace it with `.agent/` + `tasks/lessons.md`.
- KEPT OURS on `scripts/pre-commit` (finding 1) — owner chose this over `--no-verify`.
- `QG_ALLOW_NO_CHECKS=1` set in `.claude/settings.json`: BLC is a genuinely non-code
  project (product/marketing/UX only), so there is no lint/test/build to define.

## Next steps
- [x] Trust-pill price — resolved as live data (finding 2).
- [x] Model choice — both gaming agents moved sonnet → opus, stated not silent.
- [x] Persona trim — done (233→109, 235→113 lines).
- [x] Merge `template-upgrade-v8.3.13` into `main`.
- [ ] Report template defects D1/D2 upstream at the next template build
      (`docs/template-defects-owed-upstream_2026-09-01_v1.md`). Not actionable from
      inside this project; tracked as risk R1 + one open loop.

## Artifacts
- `_reports/migration-pre-v8-to-v8.3.13_2026-09-01.md` — the two-pile inventory
- `_reports/survival-index4-1440_2026-09-01.png` — survival-task screenshot
- `.agent/capsules/bloodycase-product.md`, `.agent/capsules/mockups-design-system.md`
- commit `cc77d5b` — the migration itself

## Evidence
```
bash setup.sh                     → 6/6 scripts executable, pre-commit installed
bash scripts/sheriff-review.sh --probe → OK (codex-cli 0.147.0-alpha.6.6); toggle is OFF
bash scripts/test-hooks.sh        → PASS: 143  FAIL: 0  — HOOKS: GREEN ✅
sha256(CORE block)                → ec9f3774…72d11b == .claude/core.sha (no kernel change)
curl :8099/index4.html            → HTTP 200, 77529 bytes
curl :8099/index_files/fantaicon.woff2?v=1 → HTTP 200, 38796 bytes
playwright 1440×900 screenshot    → renders: fantaicon nav glyphs, logo SVG, real
                                    weapon/case art, "DEPOSIT +25%", trust pills
pre-commit negative control       → planted sk-proj-… in temp/ still BLOCKED (rc=1)
verify-install.py --project .     → GREEN, Context Guard 4.2.4 (config schema 1,
                                    min_runtime 4.2.0; no runtime copied into the project)
```
