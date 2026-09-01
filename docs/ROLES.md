# Roles → Subagents (CATALOG)

This is the full catalog of available roles — NOT the active team. The active team
is the subset chosen during onboarding (see the `team-proposal` skill) and recorded
in CLAUDE.md → PROJECT → Active team. Reviewer selection per task is risk-based (see
the `orchestration` skill). Archived roles live in `.claude/agents/_archive/`.

Each human role = one focused subagent: one job, its own clean context. You don't
hire people, you formalize a *perspective*. Spin up only the roles a task needs.

| Role | Subagent | Does | In → Out |
|---|---|---|---|
| Business Analyst | `business-analyst` | Turns an idea into a spec; checks acceptance criteria are complete; catches ambiguity. | idea → spec v1 + gaps list |
| Data Analyst | `data-analyst` | Defines success metrics; checks logs can measure them; designs the dashboard. | spec → metrics spec, log needs |
| UX Designer | `ux-designer` | User flows, text/markdown wireframes; ensures every state is covered (empty/loading/error). | spec → flow + wireframe spec |
| UI Designer | `ui-designer` | HTML mockups, components, colors, spacing. | wireframes → mockup + component spec |
| Architect | `architect` | Reviews for scalability, dependencies, tech debt, NFRs. | spec + plans → arch review + risks |
| Tech Lead | `plan-compiler` (×3) | Breaks spec into execution blocks; best-of-3 plans. | spec → plans P1..PN |
| Test Designer | `test-designer` | Reads spec + AC, writes failing tests (unit/integration/E2E) for TDD. | spec → failing test suite |
| Developer | `block-executor` (×N) | Implements one block; writes code to turn tests green. | plan + tests → code + green tests |
| QA (manual) | `functional-verifier` | Runs smoke + critical paths; hunts edge cases. | built code → pass/fail report |
| SDET | `test-writer` | Adds extra unit/integration/E2E tests on top. | code → test files |
| UI/UX QA | `ui-ux-qa` | Compares built UI to mockup: spacing, colors, hover/focus, dark mode, a11y, mobile. | mockup + UI → conformance report |
| Code Reviewer | `code-reviewer` | Diff review: readability, dead code, patterns, simplicity, deps. | diff → review comments |
| Security | `security-reviewer` | SQLi, XSS, secrets, auth bypass, OWASP Top 10. | diff → security findings |
| Final check | `verifier` | Independent pass: does it meet the spec, with evidence? | result + spec → PASS / NEEDS-FIX |

## Project-created roles (BLC)
These two are this project's own, not part of the shipped catalog. They are the
DEFAULT owners of any product / marketing / UX task here — see CLAUDE.md → PROJECT.

| Role | Subagent | Does | Use when |
|---|---|---|---|
| Gaming Product Owner | `gaming-product-owner` | CS2/Rust/Dota2 skin-economy domain, feature prioritization (RICE/MoSCoW), GMV/conversion/churn KPIs, marketing channels, influencer & community growth, retention and referral mechanics. | the question is *what to build or what to prioritize* |
| Gaming UX Strategist | `gaming-ux-strategist` | Case-opening UI, browsing filters, trust signals, payment-flow UX, FOMO mechanics, onboarding friction, GA4 funnel analysis, Clarity session/heatmap reading, ad creative, A/B test design. | the question is *how it looks or converts* |

Run BOTH in parallel when a task spans both dimensions (e.g. "redesign the Case
Battles page" = UX analysis + product strategy at once).

## How to use
- Start small: most tasks need only `business-analyst` → `block-executor` →
  `verifier`. Add roles as scope grows.
- One task per subagent keeps each context clean (the whole point).
- Create a subagent file in `.claude/agents/<name>.md` only when you actually use
  that role repeatedly — don't pre-build all 14. `verifier` is already included.
- Each role writes its output to a persistent file (`_reports/` or the spec), not
  just chat.

## External (not subagents)
- **SHERIFF** — independent cross-vendor reviewer of high-risk diffs (a different
  vendor's model, e.g. Codex). Not a `.claude/agents/` file and not the internal
  `verifier`: see `.claude/skills/cross-review/SKILL.md`. Pluggable via
  CLAUDE.md → PROJECT → "SHERIFF cross-review"; on-demand via `/sheriff`.
