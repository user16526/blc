# START HERE — stand up a new project from this template

Canonical source: the release zip whose name matches `TEMPLATE_VERSION` in
this folder (`v8_3_N.zip`, artifact name = version, no suffix — no version
literal is written here on purpose, so this line cannot rot). Lineage and
per-release changes: `CHANGELOG.md`; the one addition carried over from a
field project at staging time: `TEMPLATE-DELTA.md`.

This tree is BLANK on purpose: every `.agent/state/*`, `tasks/*`, `_reports/*`
file is a stub, and `CLAUDE.md` still holds its FIRST RUN placeholders. Nothing
about hermipro, video-digest or the VPS is in here.

## Standup, in order

1. **Copy, don't move.** `cp -r temp/new-project-template D:\claude\<new-project>`
   (leave this staging copy alone so it can be re-used).
2. `cd` there, then `bash setup.sh` — sets the execute bits, seeds `.env` from
   `.env.example`. Nothing works before this: the hooks in `.claude/settings.json`
   fail silently without the exec bit.
3. `git init && ./scripts/install-git-hooks.sh` — the pre-commit secret scan is
   the only agent-agnostic enforcement; hooks in the agent config are best-effort.
4. `bash scripts/test-hooks.sh` → expect GREEN. This proves the harness, not the
   project.
5. **Context Guard is machine-level and OPTIONAL.** Never copy a runtime into the
   project — a project-local copy makes the shared runtime stand down and Context
   Guard goes silently INACTIVE. From the Context Guard release tree:
   `python3 scripts/install-context-guard.py --project <new-project>`, then
   `python3 ~/.claude/context-guard/verify-install.py --project .` → GREEN.
   The project owns exactly one CG file: `.claude/context-guard/config.json`.
6. In Claude Code: **"Run the FIRST RUN onboarding interview from CLAUDE.md."**
   Do NOT use `/init` — `CLAUDE.md` already exists and its CORE block is
   hash-protected. The interview fills PROJECT / STACK / MY COMMANDS, sets the
   automode default and the SHERIFF toggle, and proposes the starting team.
7. After editing CLAUDE.md's CORE block (only with an explicit Kernel Change
   Rationale): `./scripts/core-baseline.sh` to re-baseline `.claude/core.sha`.

## Two defaults worth setting deliberately at step 6

- **SHERIFF cross-review** ships **off**. hermipro-vps is the pilot install; turn
  it on only where an external cross-vendor pass is worth its cost.
- **automode** — hermipro-vps runs it **off**, so the NORMAL row still shows a
  plan. On makes NORMAL behave like LOW. The DESTRUCTIVE row never shifts.

## Verified in this staged copy
- `scripts/check-core.sh` → rc 0 (CORE hash matches the shipped `core.sha`,
  including the one MY RULES edit — MY RULES sits outside CORE).
- `scripts/check-claude-md-size.sh` → rc 0 (`CLAUDE.md` = 221 lines, limit 250).
