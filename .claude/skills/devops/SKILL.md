---
name: devops
description: Treat the agent's own configuration as infrastructure that decays. Run the periodic model-and-instruction audit (CLAUDE.md, rules, skills, agents vs the CURRENT model lineup and vendor prompting guides), keep the hook harness healthy, and activate infra roles when live-ops work appears. Use on the ⚑ audit banner at session start, after any model change, or when I say "devops audit".
---

# DevOps — config is infrastructure, and it decays like dependencies

The instruction files were tuned for the model that existed when they were written.
Models change; the crutches stay. This skill is the maintenance loop that keeps
CLAUDE.md / rules / skills / agents matched to the model actually running them.

## When to run
- The SessionStart banner says the audit is older than the cadence (default 35 days,
  set in `.agent/state/model-audit.md` → `Cadence days:`).
- The model or lineup changed (new default in `/model`, a new release, a project
  switched tiers) — don't wait for the cadence.
- A vendor published a new "prompting <model>" guide.
- I say **"devops audit"** (or run `/devops-audit`).

## A. Lineup check (live, never from memory)
1. Read `.agent/state/model-audit.md` — what we last audited against, and when.
2. Check the CURRENT lineup live: `/model` list + the vendors' model/prompting docs
   (Anthropic platform docs → "Prompting <latest>"; OpenAI cookbook/model pages).
   URLs move — search for the current guide, don't trust a saved link blindly.
3. **temp/ hygiene (same cadence):** list temp/ entries older than 14 days for
   a sweep — scratch logs and one-shot scripts delete freely (reproducible or
   already in run reports). EXCEPTION: sheriff-export*/provenance trees are
   evidence — zip them into docs/ (dated archive) before any deletion. The
   guard still blocks recursive deletes from the agent session; list the
   commands for the owner to run manually.
4. **Template freshness (same cadence):** compare this project's
   `TEMPLATE_VERSION` against the newest release in the shared releases folder
   (see UPGRADE.md → UPDATE POLICY). Newer available → propose "upgrade
   template", the human decides. Security-relevant release → propose immediately.
5. Same lineup, fresh audit on record → log "no change" and stop. Anything moved →
   run B in full. This is `model-selection.md` + `verify-external-state.md`
   applied to our own config.

## B. Instruction audit (the procedure)
1. **Fetch the current vendor guides first.** The cut-list below is a starting
   point frozen at the last audit — the live guide wins over this file.
2. **Read CLAUDE.md + always-on rules + agent files as a newcomer**, not as the
   author who remembers why each line exists.
3. **Triage against the cut-list.** Candidates to cut or rewrite:
   - self-verification crutches ("double-check", "add a final verification step",
     "use a subagent to verify") where the current model self-verifies;
   - "be conservative / only report high-severity" in reviewer prompts — current
     models follow it literally and under-report; report all, filter later;
   - unconditional subagent offloading — current models over-delegate; delegation
     needs a size/independence condition;
   - self-evident advice (clean code, best practices) and pasted public docs;
   - emphasis (CAPS / ALWAYS / NEVER / repeats) not tied to safety or money;
   - stale model/cost tables (tier names, "X for quality, Y for cost") — the
     effort/reasoning knob may now be the cheaper lever than switching tiers;
   - rules that contradict each other — name the conflict, pick one owner.
4. **I hold the veto.** You do triage; you did not see the battle a crutch was
   patched for. Present proposed cuts/edits as a diff, wait for my OK. CORE
   changes additionally need a Kernel Change Rationale + `core-baseline.sh`.
5. **Survival test.** After approved cuts, run one normal task end-to-end.
   A removed line whose problem returns goes back in; the rest stays out.
6. **Record.** Update `.agent/state/model-audit.md` (`Last audited:`, `Audited
   against:`, one log line) and write a dated report per artifact-versioning.

## C. Harness health (every audit)
- `bash scripts/test-hooks.sh` — hooks still enforce what the rules only guide.
- `./scripts/quality-gate.sh --trivial` smoke.
- Skills/rules that never fired since the last audit → prune candidates
  (see `skill-extraction.md`); every always-on line costs tokens each session.

## D. Live infrastructure (out of scope here — activate roles)
This skill maintains the CONFIG. For real infra work (SSH, Docker, releases,
incidents) activate the archived roles via `team-proposal`: `devops-operator`,
`infra-security-reviewer`, `release-manager`, `incident-responder`, and run the
`deploy` + `checkpoint` skills. Don't fold live ops into the audit.
