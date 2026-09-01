# Model & Instruction Audit — state
<!-- Read by scripts/state-freshness.sh (deterministic banner) and the `devops` skill.
     Keep the two fields below machine-greppable: `Last audited: YYYY-MM-DD`,
     `Cadence days: N`. Append one log line per audit; never rewrite history. -->

Last audited: 2026-07-28
Cadence days: 35

Audited against (a POINTER — re-check live on every audit, per model-selection.md):
- Anthropic: Claude Fable 5 (top tier above Opus; adaptive thinking, effort is the
  primary cost lever, safety classifiers can refuse cyber/bio/reasoning-extraction —
  official fallback: Opus 4.8). Guide: platform docs → "Prompting Claude Fable 5".
- Anthropic: Claude Opus 5 (thinking on by default, effort knob, built-in
  self-verification and self-correction), Sonnet 5, Opus 4.8. Guide:
  platform.claude.com → docs → prompt-engineering → "Prompting Claude Opus 5".
- OpenAI: GPT-5.x line — 5.2 prompting guide (Dec 2025) is the last full guide;
  newer 5.4 / 5.6 exist, re-check their pages on the next audit. Guide:
  developers.openai.com → cookbook → gpt-5 → "GPT-5.2 Prompting Guide".

## Log (append-only)
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
