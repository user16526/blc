# Model & Instruction Audit — v8.3.16 vs Claude Fable 5.1 guidance
Date: 2026-09-01 · Trigger: cadence overdue (35d) AND model change (Fable 5 → Fable 5.1,
released 2026-09-01, set as default this session).
Audited against (live, fetched today): Anthropic "Prompting Claude Fable 5.1",
"What's new in Claude Fable 5.1", "Claude Fable 5.1 overview"; OpenAI cookbook
index (GPT-5.4 / GPT-5.5 exist; "GPT-5.2 Prompting Guide" still the last full guide,
plus a Codex prompting guide).
Verdict: **YELLOW** — nothing RED; six small findings work against Fable 5.1's
documented behavior. Nothing here is auto-applied (owner veto per `devops` skill).
None of the proposed edits touch CORE → no Kernel Change Rationale, no re-baseline.

## Live lineup (POINTER — decays; re-pull on next audit)
| Model | Price in/out per MTok | Notes |
|---|---|---|
| Claude Fable 5.1 (`claude-fable-5-1`) | $10 / $50, cache read $0.25 | 1M ctx, adaptive thinking always on, effort default `high`; fallback on refusal: Opus 4.8 or Opus 5 |
| Claude Opus 5 (alias `opus`) | $5 / $25 | what every `model: opus` agent file resolves to |
| Claude Sonnet 5 (alias `sonnet`) | $2 / $10 | `block-executor`, `team-proposal` |
| Claude Haiku 4.5 | $1 / $5 | unused here |
| OpenAI GPT-5.4 / 5.5 | — | sheriff side; vendor closed set already matches `gpt*` |

Fable 5.1 behaviors that matter for this config (from the guide): fewer progress
updates between tool calls; may issue one tool call per turn in agent loops; denser
prose; LESS chat formatting than earlier models; may rewrite whole files for small
edits; may stop to ask permission for already-requested work; at `low` effort
answers from memory more often.

## Already covered (no action)
- "Finish the whole task / don't ask permission for requested work" → already
  `no-confirmation-prompts.md` + automode.
- "Keep changes and tests to what the task asks" → MY RULES: bounded, no polish
  rounds after GREEN.
- "Recognizing a name ≠ knowing its current state" → `verify-external-state.md`.
- Anti-formatting rules (the guide says remove them): none found — `communication.md`
  is pro-structure (bullets, tables when faster). No cut.
- Emphasis: no instruction file carries more than 3 ALWAYS/NEVER/MUST/IMPORTANT
  tokens (F6 from 2026-07-28 held). CLAUDE.md = 213 lines (<250).
- Hardcoded model IDs: none; only the `opus`/`sonnet` aliases, both still live.
- Verification crutches in reviewer/verifier prompts: none (`verifier.md`,
  `ui-ux-qa.md` are matrix-conditional, evidence-based — fine).
- Harness: `test-hooks.sh` PASS 146 / FAIL 0; `quality-gate.sh --trivial` GREEN
  at 3a84df6. `temp/`: nothing older than 14 days.
- Not measured: which skills never fired since the last audit — no firing telemetry
  exists; prune review deferred, not done.

## Findings (proposed edits — you hold the veto)

**F9 [agents] — self-verification checklists are a Fable-era tax.**
`gaming-product-owner.md` §"Self-Verification Checklist" (7 items) and
`gaming-ux-strategist.md` §"Self-Verification Checklist" (6 items). Cut-list item 1:
the current model self-verifies; a pre-delivery checklist adds tokens and a
ritual pass. Proposed: delete both sections (≈17 lines). The "Output Format" /
"Output Standards" sections already state what a good answer contains.

**F10 [agent] — "ask clarifying questions" conflicts with two rules.**
`gaming-product-owner.md` §Behavioral Guidelines: "When information is ambiguous,
ask clarifying questions: What game(s)…, current conversion rate…, demographic…".
Conflicts with `no-confirmation-prompts.md` and with the Fable 5.1 guidance
(the model already tends to stop and ask). The answers live in
`.agent/capsules/bloodycase-product.md`. Proposed rewrite:
> When something is ambiguous, take the answer from the capsules and state the
> assumption; ask only when two readings lead to materially different deliverables.

**F11 [skill prompt] — sheriff "Critical/high severity only" under-reports.**
`.claude/skills/cross-review/prompts/sheriff-review.md` line 9. Cut-list item 2:
current models follow a severity floor literally and drop real findings. The
"Maximum 5 findings" cap already bounds cost. Proposed rewrite of that bullet:
> Report every functional bug, logic error, security issue, data-loss/corruption
> risk or real-impact performance problem you are confident in, severity-tagged,
> most severe first. The cap below bounds the size; severity is filtered downstream.
Keep the 5-finding cap and the "No critical/high findings." sentinel (rename the
sentinel to "No findings." only if `sheriff-review.sh` does not match on it —
check before editing).

**F12 [rule] — one narration-suppressing line, on a model that already goes quiet.**
`communication.md:71` "Don't narrate the internal process or every shell/tool step."
The guide: "audit your prompt for instructions that suppress narration… remove
lines like that before adding anything." The same file already defines the wanted
update (Found/Next). Proposed rewrite:
> Don't narrate every shell/tool step. Do give one opening line on any task longer
> than a few tool calls, a Found/Next line at each phase change, and a closing recap.

**F13 [skill, record-only] — closes F5 (July): the opus/sonnet cost paragraph holds.**
`orchestration/SKILL.md` §"Model cost (tunable)": aliases resolve (Opus 5 / Sonnet 5),
prices above. New fact worth ONE sentence: with the lead on Fable 5.1 and reviewers
on Opus 5, reviewers are now a different model from the builder, so the
"all reviewers share the lead's blind spots" caveat weakens (not disappears).
Proposed add after the caveat paragraph:
> When the lead runs a different model than the reviewers (e.g. Fable 5.1 lead,
> `opus` reviewers) the correlation is partial, not total — still not a substitute
> for the human on irreversible work.
No tier change. Effort per agent is the cheaper lever than a tier switch; the
harness exposes it in the agent definition — check the exact frontmatter key in
the Claude Code docs before relying on it.

**F14 [capsule, ADD] — whole-file rewrites hit the mockups hardest.**
Fable 5.1 "is more likely to rewrite an entire text file rather than make a
targeted edit". `mockups/main002/index*.html` are large single files; a rewrite
costs output tokens and produces an unreviewable diff. Proposed one line in
`.agent/capsules/mockups-design-system.md` (conventions section):
> Edit mockups with targeted edits on the exact lines (Edit tool or sed); do not
> regenerate an `index*.html` wholesale — output cost and an unreviewable diff.

## Template freshness (same cadence)
`TEMPLATE_VERSION` = v8.3.16. Newest release: **v8.3.19** (2026-09-01 21:11):
- v8.3.17 — D3 (utf-8 self-test) + D4 (wrapper built FROM the artifact) — our own reports.
- v8.3.18 — START-HERE version literal de-rotted (docs only).
- v8.3.19 — `scripts/release-check.sh`: release gate verifies from the artifact.
None security-relevant → normal cadence. The open loop "take v8.3.17" is superseded
by "take v8.3.19"; merge scope grows by `scripts/release-check.sh` (new),
`START-HERE.md`, `UPGRADE.md`, a `[release]` lessons line and the
`build-release.py` docstring. sha256 companion ships inside the wrapper zip
(`release/v8_3_19.sha256`). Owner decides when.

## Resolution table (owner fills the last column)
| # | Where | Type | Recommend | Decision |
|---|---|---|---|---|
| F9 | 2 agent files | cut ≈17 lines | apply | |
| F10 | gaming-product-owner.md | rewrite 1 bullet | apply | |
| F11 | sheriff-review.md | rewrite 1 bullet (+sentinel check) | apply | |
| F12 | communication.md:71 | rewrite 1 line | apply | |
| F13 | orchestration/SKILL.md | add 1 sentence | apply (record-only otherwise) | |
| F14 | mockups capsule | add 1 line | apply | |
| — | template v8.3.19 | upgrade (HIGH row, own task) | queue as next task | |

Survival test after approved edits: the v8.3.19 upgrade itself is the natural
end-to-end task — a removed line whose problem returns goes back in.
