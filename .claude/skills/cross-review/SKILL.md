---
name: cross-review
description: External cross-vendor review (SHERIFF) of high-risk diffs, plus a single arbiter for deadlocks. Use on HIGH/DESTRUCTIVE tasks, on releases, or whenever the human calls the sheriff (sheriff / шериф / шер / шері / шері-мен).
---

# Cross-review: SHERIFF + ARBITER

Internal reviewers all run on the same base model — correlated blind spots
(see the orchestration skill, "honest limit of independence"). This skill adds
ONE external pass by a different-vendor model and ONE arbiter for deadlocks.
Insurance, not bureaucracy: three agents, and the third almost never fires.

## Pluggable — the PROJECT toggle
`CLAUDE.md → PROJECT → SHERIFF cross-review: on | off` (asked at onboarding,
default off).
- **on** — the skill fires automatically per "When SHERIFF fires" below.
- **off / empty** — the skill is dormant; nothing changes in normal flow.
  `/sheriff` on explicit human call still works — on-demand is always
  available — and trigger 3 ("On itself") still applies to template upgrades
  that touch the mechanism.
Flipping the toggle is a PROJECT-section edit: no CORE change, no re-baseline.

## Roles (roles are permanent; model names are dated pointers — see MAPPING)
- **AUTHOR** — whoever wrote the diff (normally Claude Code).
- **SHERIFF** — independent external reviewer, always a DIFFERENT VENDOR than
  the author. Human aliases: sheriff, шериф, шер, шері, шері-мен.
  Not to be confused with the internal `verifier` subagent: `verifier`
  consolidates evidence inside the team; SHERIFF is the outside check ON the team.
- **ARBITER** — strongest available model, fresh chat, zero project context.
- **OWNER** — the human. Rare, silent veto over everything.

## When SHERIFF fires
1. **Automatically** — any HIGH or DESTRUCTIVE row task (security,
   auth/permissions, DB & migrations, payments, prod config, deploy, releases,
   irreversible changes), AFTER the internal loop is GREEN and the gate passed.
   Sheriff reviews the finished diff, never work in progress.
2. **On demand** — the human names the sheriff and asks to check → run
   `/sheriff` on the current step regardless of the risk row.

3. **On itself** — any diff touching `.claude/skills/cross-review/**`,
   `.claude/commands/sheriff.md`, or `scripts/sheriff-review.sh` is
   automatically HIGH row and gets a sheriff pass, whatever it looks like.
   Not ceremony: three passes over this mechanism found 8 real defects, each
   one missed by the pass before (2026-08-30 — project-context loading; the
   CLI's own `-o` write; then, on the hardened wrapper itself, a protected root
   taken from the caller's cwd, symlink containment, a vendor denylist letting
   `ChatGPT`/`o3` through, and isolation assertions that only ran when a real
   CLI was installed). Its guarantees are exactly the kind nothing else checks.

Everything else: no external review. No ritual reviewers.

## Invocation — never by hand
`scripts/sheriff-review.sh` owns the entire external call: isolated scratch
dirs outside the repo, every isolation flag, the package assembly, and a hard
refusal if a package/findings path resolves inside the repo root or if the
author's vendor equals the sheriff's. Do not reconstruct that command line —
the boundaries are load-bearing and were each lost once already when they lived
as prose. Its static guarantees are asserted in `scripts/test-hooks.sh` (in the
gate); the behavioural proof is `scripts/integration/sheriff-isolation-live.sh`
(manual, live, out of the gate — a capability probe proves a flag EXISTS, never
that it BEHAVES). If the CLI is missing or lacks a required flag, automation
fails closed and the wrapper prints the manual package: the review still
happens, only its automation is gated.

`bash scripts/sheriff-review.sh --probe` answers "is automation available here?"
on its own — no author, no diff, same exit contract (0 / 5 / 6). Run it after an
install or a template merge. It reports what the CLI ADVERTISES, so pair it with
the live canary after a version bump: a flag that still exists but changed
meaning looks identical to the probe.

## The cycle — one pass
1. **Package**: finished diff + the task's acceptance criteria +
   `prompts/sheriff-review.md`. Sheriff sees ONLY this — no CLAUDE.md, no
   skills, no state files. Independence needs less context, not more.
2. **SHERIFF** returns ≤5 findings, critical/high only, numbered [1]–[5].
3. **AUTHOR** answers every finding, strictly one of:
   - `[N] ✅ fixed:` what changed — silently, no self-justification;
   - `[N] 🧪 test:` provable by a test → write the test; its result IS the answer;
   - `[N] ❌ disagree:` 1–2 sentences, a falsifiable reason. **Hard limit: ≤2 ❌
     per task.** Escalation costs the owner — ❌ is not a "dump it on the
     arbiter" button.
4. Run the full test suite. Anything testable is settled by tests, not argument.
5. A security-critical fix NOT covered by a test → show sheriff that ONE fix
   again (re-check mode in the prompt file). One finding, not a second round.
6. Remaining ❌ → ARBITER, one anonymous batch. The verdict closes the cycle:
   no appeals, no comments.
7. The run report gets `cross_review: closed | n/a` + a one-line findings summary.

**One-liner:** author → high-risk? → SHERIFF ≤5 findings → ✅ fix / 🧪 test /
❌ (≤2) → unresolved ❌ anonymously → ARBITER → done. Owner veto: rare, silent.

## Arbitration
- OWNER rewrites both positions in their own words (raw model text deanonymizes
  by style) and pastes `prompts/arbiter.md` into a FRESH arbiter chat.
- Test > arbiter, always. The arbiter refuses testable disputes by design.
- The verdict is final among models. The owner veto exists and is never debated.

## MAPPING — staleness protection
Model names decay (`.claude/rules/model-selection.md`). This file names ROLES
only; the role→model mapping is a dated entry in `.agent/state/decisions.md`,
re-checked at every devops audit. Swapping a model = editing that one dated
line; this skill never changes.
- Keep the ARBITER the strongest model available, not the cheapest: it fires
  rarely, so its token cost is ~zero. Economize on author/reviewer models
  instead, never on the judge.
- If author and sheriff ever land on the same vendor, rotate one —
  cross-vendor is the entire point.

## Reviewer package = state, not transcript (v8.3.16)
The reviewer (Codex/sheriff) receives: original task + `.agent/state/current.json`
+ git diff + relevant files + tests/gate evidence — and NEVER the Claude
transcript, so it inherits no stale reasoning or failed hypotheses (that
independence is where the accuracy gain lives). Findings do not touch the state
directly: reviewer emits a finding → Claude fixes → the GATE confirms → only
then `state-patch` flips it open → resolved. Transcript fragments stay
available on-demand from `_reports/` for arbitration/postmortem — the one case
where history itself is the subject — never by default.
