# UPGRADE.md — migrate THIS project to a newer template version

Trigger: I drop a newer template into `temp/template-new/` (unzipped) and say
**"upgrade template"**. You run this procedure. It is HIGH-row work in the RISK MATRIX: plan →
my approval → execute. Never upgrade silently.
<!-- For projects too old to have this file: the human pastes this file's
     content as a message — the procedure works the same. -->

## UPDATE POLICY (the standing rules; the numbered steps below are the mechanics)
- **Installed version is a file, not a memory:** `TEMPLATE_VERSION` at the repo
  root. Standup writes it; step 5 of every upgrade rewrites it. FROM comes from
  here, never from recollection.
- **Releases are build products.** Zips come from the canonical source tree
  (`build-release.py`); nobody ever edits a zip or a project to "match" one.
  **Release gate (v8.3.19): `bash scripts/release-check.sh` on the canonical
  tree — it builds, then verifies INSIDE the unpacked artifact (strays, CG leak,
  rot-able version literals, suites, sha). RED = do not ship. A working-tree
  check is never the release verification (lesson [release]).
  Keep all release zips in ONE shared folder on this machine (recommended:
  `D:\claude\template-releases\`) so every project upgrades from the same
  artifact.
- **Release semantics:** patch (x.y.Z) — fixes, mechanical merge; minor (x.Y.0)
  — new capabilities, which always ship **OFF by default** (a new project
  behaves exactly like before until a toggle is flipped — the sheriff is the
  model case); major (X.0.0) — structural, takes the transplant route
  (section T). Any CORE change, at any level, still needs my explicit OK +
  re-baseline.
- **Cadence:** upgrades are pull-based, checked at every `devops` audit
  (default 35 days): compare `TEMPLATE_VERSION` against the newest release in
  the shared folder. A bare version gap is NOT "behind": open the newer
  template's CHANGELOG and check whether any entry between FROM and newest
  carries CODE (docs-only entries say "No code changes" in their first lines).
  Code in the gap → propose the upgrade, my call. Docs-only gap → log it and do
  nothing; the corrected records apply automatically at the next code upgrade.
  A security-relevant release is the exception — propose it immediately.
- **An additive upstream delta is still a diff, and still owes a sheriff pass.**
  Earned in sheriff round 5: a one-line "additive, relaxes nothing" portability
  fix introduced a second spelling of the reviewer CLI and a probe/review split.
  "Additive" is a merge rule, not a review waiver.
- **Rollback is pre-paid:** step 0's checkpoint branch IS the rollback; an
  upgrade that can't state its rollback line doesn't start.
- **One project first.** A new release lands in ONE project, survives its gate
  + one normal task, and only then fans out to the rest.

## 0. Checkpoint first
Run the `checkpoint` skill: clean commit, branch `template-upgrade-<TO>`,
state the rollback line. No upgrade on a dirty tree.

## 1. Determine FROM → TO, read the intent
- FROM = this project's `TEMPLATE_VERSION` file (older projects without it:
  top version in this project's `CHANGELOG.md`); TO = the new template's
  `TEMPLATE_VERSION`. (Neither present → say so, fall back to
  file-by-file diff.)
- Read every changelog entry between FROM and TO. That narrated INTENT is what
  you apply; raw file diffs only confirm it.
- **Route:** same major → steps 2–5 (merge). Major gap, or the project lacks
  the v8 markers (CORE sentinel in CLAUDE.md, `.claude/core.sha`,
  `.agent/state/`) → section T (transplant). Steps 0 and 5 apply to both.

## 2. Classify every template file — three buckets
Compare files CR-STRIPPED (e.g. hash `tr -d '\r' < file`), never raw bytes:
`.gitattributes` pins only `*.sh`/`*.py` to LF and leaves `* text=auto`, so a
Windows worktree checks `.md` out as CRLF while release zips are uniformly LF —
a raw hash sweep invents divergences that do not exist and manufactures hand-
merges (field project B, 2026-08-31). Line-ending-only difference == identical.
- **Template-owned, unmodified here** (byte-identical to the old template /
  never touched): replace with the new version. Typical: `scripts/*`,
  `.claude/commands/*`, `docs/ROLES.md`, unedited template skills/rules.
- **Template-owned, modified here**: do NOT overwrite. Show a 3-way diff
  (old template / new template / ours), propose a merge. My veto per file.
- **Project-owned — NEVER touch:** `.agent/state/*`, `tasks/*`, `_reports/*`,
  `specs/*`, real `.env*`, project-created skills/agents/rules, `temp/`.

## 3. CLAUDE.md and settings are a MERGE, never a replace
- PROJECT / STACK / MY COMMANDS / MY RULES: preserved verbatim.
- Non-CORE structural changes: propose as a diff.
- CORE block: only with my explicit OK + a Kernel Change Rationale, then
  re-baseline via `./scripts/core-baseline.sh`.
- `.claude/settings.json`: merge (I may have added permissions/hooks).

## 4. Adapt, don't just copy
The new version may assume a different model era than this project's config.
After the file merge, run the `devops` skill (fresh audit against the CURRENT
vendor guides, not the ones frozen in the new template): crutches the new
changelog says to cut, cut here too — my veto, then a survival test.

## 5. Verify + record + clean up
- `bash scripts/test-hooks.sh` → GREEN; `./scripts/quality-gate.sh --trivial`.
- Context Guard is NOT part of the project payload and has no project test: it is
  one shared runtime at `~/.claude/context-guard/`, upgraded from its own release
  artifact (`context-guard-<version>.zip`) with
  `python3 scripts/install-context-guard.py --project <this project>`. Prove it with
  `python3 ~/.claude/context-guard/verify-install.py --project .` → GREEN. **Never
  copy a Context Guard runtime into the project**: a project-local copy makes the
  shared runtime stand down and Context Guard goes silently INACTIVE. The only
  Context Guard file this project owns is `.claude/context-guard/config.json`; if the
  old version left `hooks/`, `statusline/`, `version.json`, `state-dir.sh`,
  `analyze-telemetry.py` or `verify-install.py` under `.claude/context-guard/`, or
  context-guard hook/statusLine entries in `.claude/settings.json`, delete them in
  this upgrade — the installer refuses to run until they are gone.
- One normal task end-to-end (survival test). WAIVER: if the upgrade changes
  ZERO executable bytes in the project, the survival task may be waived with my
  explicit OK, recorded in the run report; the suite and (if the sheriff toggle
  is on) the live canary still run on the post-merge tree.
- Overwrite `TEMPLATE_VERSION` with TO — this file is what the next upgrade and
  the devops-audit freshness check read.
- Append to `.agent/state/decisions.md`: `upgraded template vFROM→vTO, <date>,
  notable merges/vetoes`. If step 4 ran, update `Last audited:` in
  `.agent/state/model-audit.md`.
- Delete `temp/template-new/`. Merge the branch only after my OK.

## T. Major-version gap (e.g. v7 → v8) — transplant, don't merge
Across majors the layouts differ too much to patch, and FROM-era instructions
were tuned for FROM-era models. Direction reverses: don't pull the new template
INTO the old project — stand up the new skeleton and carry the project's
KNOWLEDGE into it. On the checkpoint branch:
1. **Inventory the old project into two piles**, written to
   `_reports/migration-<FROM>-<TO>_<date>.md`. Nothing is dropped silently;
   anything you can't classify goes on a quarantine list for me:
   - *Project knowledge (transplants):* project facts, stack, commands, my
     rules, decisions, lessons, risks, open loops, specs, tasks, reports,
     project-created skills/agents, real `.env*`, deploy configs.
   - *Old template machinery (dies with FROM):* its rules, hooks, scripts,
     skills, commands — the new machinery wins wholesale, no merging.
2. **Stand up the new skeleton clean** (copy the TO template onto the branch),
   then pour knowledge into its homes per the `memory-router` skill: facts →
   CLAUDE.md PROJECT/STACK/MY COMMANDS; my rules → MY RULES; decisions/
   lessons/risks/open loops → `.agent/state/` + `tasks/lessons.md`; specs/
   tasks/reports → their folders.
3. **Every transplanted instruction passes the devops audit BEFORE entering
   the kernel.** Old MY RULES are prime crutch candidates — triage them
   against the CURRENT vendor guides; my veto per rule. Project-created
   skills transplant, but get the same audit (often too prescriptive for
   current models).
4. CORE comes verbatim from TO, then `./scripts/core-baseline.sh`.
5. Close with step 5 as usual. The survival task doubles as a behavior
   comparison against the old branch — which stays as the rollback. Record
   `migrated <FROM>→<TO> by transplant` in decisions.md and link the
   inventory report.

Rollback = the checkpoint branch on both paths. Anything ambiguous → my
decision format (question / options / pros-cons / recommendation). Upgrading
is HIGH/DESTRUCTIVE-row work: it touches every future session of this project.
