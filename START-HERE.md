# START HERE — stand up a new project from this template

Distribution: **ONE zip = ONE folder = ONE project.** The release zip is named
after `TEMPLATE_VERSION` in this folder (`v8_3_N.zip`, no suffix — no version
literal is written here on purpose, so this line cannot rot) and unpacks to a
single folder named by that version. That folder IS the new project: there is
no wrapper and no second folder to choose from. Lineage and per-release
changes: `CHANGELOG.md`.

This tree is BLANK on purpose: every `.agent/state/*`, `tasks/*`, `_reports/*`
file is a stub, and `CLAUDE.md` still holds its FIRST RUN placeholders. No
field project is named in any entry doc — the release gate asserts it.

## Standup, in order

1. **Unzip, then rename.** Unzip the release and rename the unpacked folder to
   the project (e.g. `D:\claude\<new-project>`). Keep the zip itself in the
   shared releases folder (`D:\claude\template-releases\`, see `UPGRADE.md`):
   every project upgrades from that same artifact. Never re-pack a worked-in
   tree as a release.
2. `cd` there, then `bash setup.sh` — sets the execute bits, seeds `.env` from
   `.env.example`. Nothing works before this: the hooks in `.claude/settings.json`
   fail silently without the exec bit.
3. `git init && ./scripts/install-git-hooks.sh` — the pre-commit secret scan is
   the only agent-agnostic enforcement; hooks in the agent config are best-effort.
4. `bash scripts/test-hooks.sh` → expect GREEN. This proves the harness, not the
   project.
5. **Context Guard is machine-level and OPTIONAL.** Never copy a runtime into the
   project — a project-local copy makes the shared runtime stand down and Context
   Guard goes silently INACTIVE. It ships as its own artifact
   (`context-guard-<version>.zip`), separately from this zip and only when the
   runtime changes; a machine that already has it installed needs nothing. From
   that release tree: `python3 scripts/install-context-guard.py --project
   <new-project>`, then `python3 ~/.claude/context-guard/verify-install.py
   --project .` → GREEN. The project owns exactly one CG file:
   `.claude/context-guard/config.json`.
6. In Claude Code: **"Run the FIRST RUN onboarding interview from CLAUDE.md."**
   Do NOT use `/init` — `CLAUDE.md` already exists and its CORE block is
   hash-protected. The interview fills PROJECT / STACK / MY COMMANDS, sets the
   automode default and the SHERIFF toggle, and proposes the starting team.
   The first SessionStart may print a ⚑ model-audit banner: the template's own
   audit date has aged out — that is the cadence working, run `/devops-audit`
   as part of onboarding.
7. After editing CLAUDE.md's CORE block (only with an explicit Kernel Change
   Rationale): `./scripts/core-baseline.sh` to re-baseline `.claude/core.sha`.

## Two defaults worth setting deliberately at step 6

- **SHERIFF cross-review** ships **off**. Turn it on only where an external
  cross-vendor pass is worth its cost — one project first, then fan out
  (`UPGRADE.md`, "One project first").
- **automode** ships **off**, so the NORMAL row still shows a plan. On makes
  NORMAL behave like LOW. The DESTRUCTIVE row never shifts.

## How this release was verified

Not by hand and not in a working tree: `scripts/release-check.sh` runs on the
canonical tree, builds, unpacks the RESULT and proves everything inside that
unpack — no strays, no Context Guard leak, no rot-able literals, no field-project
names in entry docs, CHANGELOG == TEMPLATE_VERSION, exec bits via `setup.sh`,
`test-hooks.sh`, `state-patch.py --self-test` (utf-8 and cp1252), sha256
companion, and that no artifact reuses an already-published name with different
bytes. The counts live in this version's CHANGELOG entry, not here — a
number written here would rot.
