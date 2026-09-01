---
name: team-proposal
description: Propose a concrete starting team of subagents during onboarding (or re-onboarding). Use when initializing a project or when scope changes materially.
---

# Team Proposal (principal-agent during onboarding)

Act as a practitioner who has done every role (BA + Team Lead + CTO + CMO). Don't
hand me the full catalog — recommend the SPECIFIC team this project needs, with a
one-line reason each, then let me edit before you create the files.

## How to propose
1. From project type + goal, pick the smallest team that still self-checks. A
   project always has ≥2–3 perspectives — solo is never truly one agent.
2. Always include an independent `verifier` (the head check). Never propose a team
   that only builds and never reviews.
3. Name builders AND reviewers, and which risks the reviewers cover (see the
   orchestration skill).
4. State the shared skills the whole team will use (token economy — see below).

## Starting-team templates (adapt, don't paste blindly)
- **Vibe-coding MVP**: `business-analyst` (spec), `block-executor` (build),
  `test-designer` (TDD), `functional-verifier`, `verifier`. Add `security-reviewer`
  once there's auth/payments/data.
- **Agency — landing / campaign**: `business-analyst` (brief→spec), `ui-ux-qa`
  (visual + mockup match), `functional-verifier` (forms + tracking fires),
  `verifier`. Add a content/brand check if copy is involved.
- **VPS / infra**: `architect` (plan + risks), `block-executor`, `security-reviewer`
  (hardening, secrets), `verifier`. Treat every change as data/infra risk.

## Token economy — shared vs per-agent
- **Shared skills** (every agent reads): the team's definition-of-done, the report
  format, `orchestration`, `artifact-versioning`. Put common rules ONCE here, not
  copied into each agent — fewer tokens, one source of truth.
- **Per-agent**: only what's unique to that role (its checklist, its output shape).
- Keep each agent file lean; if two agents repeat the same paragraph, extract it to
  a shared skill.
- **Model choice (cost lever):** agents default to `opus` for quality (time >
  tokens). If THIS project's token cost matters more than reviewer depth, set
  `model: sonnet` in the frontmatter of the non-high-risk roles (e.g. `ui-ux-qa`,
  `code-reviewer`, `plan-compiler`); keep `opus` on `security-reviewer`,
  `architect`, and anything touching data/infra. One line per file, easy to revert.

## Output of this skill
A short proposed roster: `role — why — risks covered`, plus shared skills, plus
default reviewer count (2). On my OK, create/activate only the agreed roles; move
any core role this project won't use to `.claude/agents/_archive/`. Record the
active team in CLAUDE.md → PROJECT.

## Domain roles to RECOMMEND (don't create files until needed)
Core agents already exist as files (BA, plan-compiler, architect, test-designer,
block-executor, code-reviewer, functional-verifier, security-reviewer, ui-ux-qa,
verifier). For domain work, recommend these by NAME during onboarding and create a
file only when the project actually needs it:
- **Agency / marketing**: `content-strategist`, `tracking-analytics-verifier`,
  `conversion-reviewer`.
- **VPS / infra**: `devops-operator`, `infra-security-reviewer`, `release-manager`,
  `incident-responder`.
Keep the active set small — even some core roles can go "on leave" to `_archive/`
if this project doesn't need them. Don't overload the project.
