# Current State
<!-- The ONLY human-readable "what's true now". Mutable. Keep ≤250 lines. -->
<!-- Compact aggressively: stale lines move to decisions.md / lessons.md / _reports. -->
<!-- LIVE-SYSTEM FACTS DECAY. Notes here are POINTERS, not evidence. Before acting on any
     live fact (deployed/published version, external API, provider/cloud config), re-pull it
     live (scripts/check_live_state.py) and tag it [verified <date> via <tool>]. Newest dated
     entry wins. See .claude/rules/verify-external-state.md. -->

Last updated: 2026-09-01

## Now working on
- Nothing active. The project was just migrated from its pre-v8 framework to
  template v8.3.13 (transplant route). Next real task starts fresh under the v8 kernel.

## Recently decided (1-liners; full reasoning → decisions.md)
- 2026-09-01 — migrated pre-v8 → v8.3.13 by transplant; old rules/hooks/skills
  retired wholesale, project knowledge moved into `.agent/` capsules + state.
- 2026-09-01 — `git init` done here for the first time; branch `main` holds the
  pre-upgrade baseline (863ef05) as the rollback.
- 2026-05-18 — approved design system for all BLC mockups locked in
  (`.agent/capsules/mockups-design-system.md`).

## Don't forget / pending my approval
- Context Guard is NOT yet opted in for this project (`.claude/context-guard/config.json`
  is shipped but the installer has not been run here). Run
  `python3 <context-guard release>/scripts/install-context-guard.py --project .`
  when you want it active, then `verify-install.py --project .` → GREEN.
- The state of `mockups/main002/index4.html` vs. what the client last saw is not
  recorded anywhere — confirm before iterating further.
