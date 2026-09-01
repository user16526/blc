# Model & Instruction Audit — state
<!-- Read by scripts/state-freshness.sh (deterministic banner) and the `devops` skill.
     Keep the two fields below machine-greppable: `Last audited: YYYY-MM-DD`,
     `Cadence days: N`. Append one log line per audit; never rewrite history. -->

Last audited: 2026-09-01
Cadence days: 35

Audited against (a POINTER — re-check live on every audit, per model-selection.md):
- Anthropic: Claude Fable 5.1 (released 2026-09-01; the user's default; $10/$50,
  cache read $0.25; adaptive thinking always on, effort default `high` and the
  primary cost lever; fewer progress updates, less chat formatting, whole-file
  rewrite tendency; refusal fallback: Opus 4.8 or Opus 5). Guide: platform docs →
  "Prompting Claude Fable 5.1" + "What's new in Claude Fable 5.1".
- Anthropic: Claude Opus 5 ($5/$25, alias `opus` — every reviewer agent),
  Sonnet 5 ($2/$10, alias `sonnet`), Haiku 4.5, Opus 4.8 (fallback only).
- OpenAI: GPT-5.4 / GPT-5.5 exist; "GPT-5.2 Prompting Guide" is still the last
  full guide, plus a Codex prompting guide in the cookbook. Sheriff vendor set
  (`gpt*`) covers them.

## Log (append-only)
- 2026-09-01 — audit vs the Fable 5.1 guide (model changed today) + template
  freshness (v8.3.19 available, not security). Verdict YELLOW: F9-F14 proposed,
  none CORE; F5 (July) closed by F13. Harness 146/0, gate GREEN. Awaiting the
  owner's resolution: `docs/model-audit-recommendations_2026-09-01_2301_v1.md`.
- 2026-08-18 — RESOLUTION of the 2026-07-28 findings (human-approved, decisions 1-9):
  F1 verifier-reflex → matrix-conditional (LOW: none) [applied, CORE re-baselined];
  F2 subagent offloading → conditional, agents per matrix row [applied];
  F3 GOLDEN RULE / lanes / autonomy conflict → ONE RISK MATRIX + automode toggle,
  lanes+A/B/C deleted [applied]; F4 "agents must agree" → expose-disagreement +
  verifier filter + escalation table in orchestration skill [applied]; F6 emphasis
  trim + F7 size → CLAUDE.md 227→198 lines [applied]; F5 opus/sonnet cost table —
  still open, re-check on next audit. New rule: a YELLOW/RED audit must end in a
  resolution decision (apply / veto with reason), never only a doc in docs/.
- 2026-07-28 (2) — re-audited against the DEDICATED Fable 5 guide (user's primary
  model). New finding F8 + validations in the recommendations doc v1. Grep for
  reasoning-echo instructions (Fable refusal hazard): clean.
- 2026-07-28 — initial audit against Opus 5 / GPT-5.2 guides. Findings + proposed
  edits: `docs/model-audit-recommendations_2026-07-28_1500_v1.md`. Mechanism
  installed: `devops` skill, SessionStart staleness banner, this file, /devops-audit.
