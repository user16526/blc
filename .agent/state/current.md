# Current State
<!-- The ONLY human-readable "what's true now". Mutable. Keep ≤250 lines. -->
<!-- Compact aggressively: stale lines move to decisions.md / lessons.md / _reports. -->
<!-- LIVE-SYSTEM FACTS DECAY. Notes here are POINTERS, not evidence. Before acting on any
     live fact (deployed/published version, external API, provider/cloud config), re-pull it
     live (scripts/check_live_state.py) and tag it [verified <date> via <tool>]. Newest dated
     entry wins. See .claude/rules/verify-external-state.md. -->

Last updated: 2026-09-01

## Now working on
- Nothing active. The project was migrated from its pre-v8 framework to template
  v8.3.13 (transplant route) and every open decision from that upgrade is closed.
  Next real task starts fresh under the v8 kernel.

## Recently decided (1-liners; full reasoning → decisions.md)
- 2026-09-01 — migrated pre-v8 → v8.3.13 by transplant; old rules/hooks/skills
  retired wholesale, project knowledge moved into `.agent/` capsules + state.
- 2026-09-01 — `git init` done here for the first time; branch `main` holds the
  pre-upgrade baseline (863ef05) as the rollback.
- 2026-09-01 — trust-pill price is live data, not a design token; `index4.html` is
  correct as-is and no mockup was edited.
- 2026-09-01 — both gaming agents: model sonnet → opus; personas trimmed ~55% by
  cutting a dead agent-memory instruction block.
- 2026-05-18 — approved design system for all BLC mockups locked in
  (`.agent/capsules/mockups-design-system.md`).

## Don't forget / pending my approval
- Context Guard IS active here: `.claude/context-guard/config.json` (schema 1,
  min_runtime 4.2.0) is the opt-in switch, and the shared runtime at
  `~/.claude/context-guard/` is 4.2.4. Verified 2026-09-01:
  `python3 ~/.claude/context-guard/verify-install.py --project .` → GREEN.
  No runtime is copied into this project, and none must be.
- The state of `mockups/main002/index4.html` vs. what the client last saw is not
  recorded anywhere — confirm before iterating further.
- Two template (not BLC) defects are owed upstream:
  `docs/template-defects-owed-upstream_2026-09-01_v1.md`. One of them is why
  `scripts/pre-commit` here diverges by one line (risk R1).
