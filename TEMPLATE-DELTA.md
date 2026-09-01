# Delta report — canonical template v8.3.14 vs `hermipro-vps` (v8.3.13)

Built 2026-09-01. Method: every file in the template compared to this project
**CR-stripped** (`tr -d '\r' | sha256sum`), per `UPGRADE.md` §2 — a raw byte hash
invents divergences on a Windows worktree and manufactures hand-merges.

**Result: 102 template files — 73 identical, 27 differ, 2 absent here.**

## The finding that matters

**A canonical template already existed, and it is NEWER than what this project
runs.** hermipro-vps is at `v8.3.13`; the canon is `v8.3.14`. So the correct base
for a new project is the canon — NOT a copy of this project. Three v8.3.14 files
are strictly better than ours and we simply do not have them yet:

| file | what v8.3.14 fixed that we lack |
|---|---|
| `scripts/pre-commit` | The `test-hooks.sh` scan exclusion is now narrowed and **suite-asserted** (a synthetic secret in any other file must still block). Ours is a bare one-line exclusion. Origin: BLC finding D1, 2026-09-01. |
| `.codex/hooks.json` | Correct feature flag (`features.hooks`, stable in codex-cli 0.147) and the Windows `bash`-on-PATH requirement. Ours still names the old `[features] codex_hooks = true`. |
| `.claude/rules/context-hygiene.md` | Version de-hardcoded — points at `config.json` instead of freezing "v8.2.0, runtime 4.2.4" in prose. Ours carries the stale literal. |

This is a real upgrade signal for hermipro-vps, separate from this staging job.

## What was carried OVER from hermipro-vps into this staged tree

Exactly one file, because exactly one project-owned addition is generic:

- **`.claude/rules/communication.md`** + the MY RULES bullet in `CLAUDE.md`
  rewritten to point at it. The canon keeps the ADHD style as three inline kernel
  lines; this project promoted it to a path-scoped rule carrying the actual
  formats plus the *final-first* and *advise-only-when-needed* policies. A rule
  file is the better home — it does not spend kernel lines.
  Re-verified after the edit: `check-core.sh` rc 0, `check-claude-md-size.sh` rc 0.

## What was deliberately NOT carried over

**Project-owned by definition** (`UPGRADE.md` §2 bucket 3 — never travels):
`.agent/state/*`, `tasks/*`, `_reports/*`, `specs/*`, `CLAUDE.md` PROJECT/STACK/
MY COMMANDS, `.claude/core.sha`, `TEMPLATE_VERSION`, `.claude/skills/deploy/SKILL.md`,
team composition (`devops-operator` active here / archived upstream; `ui-ux-qa`
archived here / active upstream), and every hermipro script — `corpus.py`,
`fact_retention.py`, `measure_corpus.py`, `probe_sections.py`, `score_digest.py`,
`accept_report.py`, `restart-hp-llm-test.sh`, `hermipro*.ps1`.

**Our local hardening that is NOT yet upstream** — left out of a blank template on
purpose, but it should be folded into the canon rather than lost:

| file | our addition | why it is not in a new project |
|---|---|---|
| `scripts/secret-patterns.sh` | +12 lines: WireGuard `PrivateKey`, wgcf `license_key`/`access_token`, Netscape cookie-file header + data-line shapes (spec 008/008b) | Earned by this project's YouTube-cookies and wgcf surface. Genuinely portable — a good candidate to propose upstream. |
| `scripts/test-hooks.sh` | 3 spec-008 assertions (ours 1107 lines vs canon 1151 — the canon is otherwise ahead) | Asserts the patterns above. Travels with them, not separately. |
| `scripts/quality-gate.sh` | +11 lines | Project gate specialization. |
| `.claude/rules/deploy.md` | +25 lines: merged-tree gate, "check what the target runs before deploying a branch", cold-session independent review, "a GREEN gate is not proof the deploy is safe" | All four earned the hard way on 2026-08-25. Strong upstream candidates, but they assume a deployed VPS surface. |
| `.claude/rules/model-selection.md` | +9 lines: escalate-to-Fable-5 on hard questions, Opus 5 working default | Owner rule for THIS project, dated 2026-08-21. A new project sets its own at onboarding. |
| `.claude/agents/security-reviewer.md` | +16 lines (app + infra merged, 2026-08-25) | Team-shape decision, re-made per project. |
| `AGENTS.md` | 388 lines vs canon's 62 — Independent Reviewer Mode and the cross-session review contract | Largely project procedure. |
| `docs/ROLES.md` | +36 lines | Role catalog extended for this team. |
| `scripts/vps_ssh.py`, `backup_to_github.py`, `rotate-credential.ps1`, `hermipro-tunnel*.ps1` | VPS plumbing | Copy manually IF the new project is VPS-hosted. |

## Recommended follow-ups (not done — each is its own task)

1. **Upgrade hermipro-vps v8.3.13 → v8.3.14** via `UPGRADE.md`. The gap carries
   CODE (`scripts/pre-commit`), so the cadence rule reads it as behind.
2. **Propose the `secret-patterns.sh` hardening upstream** so the next project
   gets it by default instead of re-earning it.
