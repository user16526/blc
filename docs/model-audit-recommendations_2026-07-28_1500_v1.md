# Model & Instruction Audit — v8.1.8 vs Opus 5 / GPT-5.2 guidance
Date: 2026-07-28 · Audited against: Anthropic "Prompting Claude Opus 5",
Anthropic "Prompting Claude Fable 5", OpenAI "GPT-5.2 Prompting Guide", and the telegra.ph revision checklist.
Verdict: **YELLOW** — architecture is ahead of the article, but 8 findings
now work against the current models. Nothing here is auto-applied; items marked
[CORE] need a Kernel Change Rationale + `./scripts/core-baseline.sh` re-baseline.

## Already covered (no action)
- 250-line hard limit + hook; path-scoped rules; kernel/memory routing — this IS
  the article's "keep it a memo, split the rest" done as machinery.
- `model-selection.md` (v8.1.8) already treats the lineup as decaying state.
- `verify-external-state.md` / `state-freshness.sh` — notes-decay discipline.
- Skill prune clause in `skill-extraction.md` — partial self-revision.
- No pasted API docs, no per-file repo maps, no dependency versions in the kernel.
- Reviewer prompts do NOT say "only high-severity" — matches Opus 5 review advice.
- What was missing — a cadence for auditing the instruction files themselves —
  is added in this draft (devops skill + SessionStart banner + model-audit.md).

## Findings (proposed edits, my triage — you hold the veto)

**F1 [CORE, CLAUDE.md:74] — the verifier reflex is now a double-verification tax.**
"DONE MEANS PROOF" ends with: after non-trivial work, *use the verifier subagent
to check the result*. Opus 5 verifies its own work unprompted; Anthropic's guide
says explicit "verify / use a subagent to verify" instructions cause
over-verification and wasted tokens with no quality gain. The deterministic gate
(`quality-gate.sh`) should stay — a script can't be skipped by model mood — but
the blanket subagent reflex should become lane-conditional.
Proposed rewrite of that sentence:
> On the full lane, close with the `verifier` subagent per the orchestration
> skill; on the fast lane the gate + one shown proof is enough — do not add
> extra self-verification passes on top.

**F2 [CORE, HOW YOU WORK #5] — unconditional offloading meets a model that
over-delegates.** "Offload heavy reading/research to a subagent" has no size
condition. Opus 5 delegates more readily than prior models; vendor guidance is to
delegate only genuinely independent, sizeable tracks and never to spawn agents to
re-check your own work. Proposed:
> 5. Offload to a subagent only work that is sizeable AND independent (a wide
>    multi-file read, a research track). If you can finish it in a handful of
>    tool calls, do it in the main thread; never spawn a subagent just to
>    re-check your own work (the verifier flow in orchestration is the exception).

**F3 [MY RULES — internal contradiction, the article's "що суперечить одне
одному" test fails here].** GOLDEN RULE says *always* plan and submit for
approval; CORE #2 says trivial → just do it; `no-confirmation-prompts.md` says
act on clear intent; AUTONOMY B says run to the end. Four owners of one decision.
Precedence solves conflicts between layers, but GOLDEN RULE and CORE live in the
same file. Proposed (your section, your call): scope the GOLDEN RULE —
> Non-trivial work (full lane): step-by-step plan for approval first.
> Trivial / fast-lane: skip the plan gate; the SAFETY + spend guards still apply.

**F4 [MY RULES — two lines that pay rent on current models].** Both vendors now
say verbosity and scope must be pinned explicitly (Opus 5 answers longer by
default; GPT-5.2 wants explicit scope discipline). The template has neither.
Proposed additions (short, adapted from both guides):
> - Keep responses focused and concise; before the first tool call say in one
>   sentence what you're doing; update me only on findings or direction changes;
>   lead the final message with the outcome.
> - Deliver what was asked at the scope intended: no unrequested features or
>   embellishments; if a better approach exists, say so in one sentence and
>   continue as asked.
These two lines also replace "Agents must agree among themselves on the result as
ideal for me" — vague, near-zero informational content; cut it.

**F5 [orchestration + team-proposal — the cost table decayed].** "Reviewers
default to `opus`, downgrade to `sonnet` to save" predates the effort knob.
On Opus 5, review accuracy holds at lower effort, so the cheap lever is often
same-model-lower-effort, not a tier switch; and reviewer *count* is the bigger
multiplier now that the model self-verifies. Proposed: add one paragraph to
orchestration Step 2/3 —
> Cost levers, in order: (1) reviewer COUNT — on current self-verifying models,
> medium-risk default may drop to 1 reviewer + verifier; keep 3 for release /
> irreversible; (2) effort level — a low-effort pass first, high-effort for
> security/data; (3) model tier last. Re-check this table at every devops audit —
> it decays.
Same note in team-proposal's "Model choice" bullet. Best-of-3 `plan-compiler`
becomes full-lane-only (it already effectively is — say it explicitly).

**F6 [emphasis density — borderline, trim on next pass].** ~38 ALWAYS / NEVER /
MUST / STOP tokens in 220 lines. Most guard secrets, money, destructive commands
— the legitimate use per Anthropic. But every non-safety emphasis dilutes those.
When F1–F4 free lines, do one pass demoting non-safety emphasis to plain prose.
Survival-test each demotion (the article's rule: remove, run a task, only a
returning problem earns the line back).

**F7 [size — at the soft ceiling].** 220 lines exactly; the size hook itself
cites the >200-line adherence warning. F4 adds 2 net lines only if F3/F4 cuts
land; target ≤ 210 after this audit so the next addition has headroom.

**F8 [Fable 5 — the user's PRIMARY model has its own guide; deltas vs F1–F7].**
Audited additionally against "Prompting Claude Fable 5" (2026-07-28):
- The article's thesis is stated by the vendor about THIS model: skills written
  for prior models are often too prescriptive for Fable 5 and can degrade output;
  a capability jump is itself the cue to re-evaluate instructions and guardrails.
  The devops-audit cadence is therefore not optional hygiene — it's the vendor's
  own migration advice for the primary model.
- **F1 stands, with a twist that validates the lane-conditional fix:** for LONG
  runs Fable 5's guide recommends explicit fresh-context verifier subagents
  (they outperform self-critique), while Opus 5's guide says cut verification
  instructions. Lane-keyed verification serves both: full lane / long runs →
  verifier subagent (Fable-correct); fast lane → gate + one proof, no extra
  passes (Opus-correct). DONE MEANS PROOF is separately vendor-endorsed for
  Fable 5 ("audit each claim against a tool result") — keep it verbatim.
- **F2 stands:** Fable 5 also dispatches subagents readily; keep the
  independence/size condition, prefer async orchestrator↔subagent communication.
- **Reasoning-echo audit: CLEAN.** Instructions to transcribe internal reasoning
  can trigger Fable 5's reasoning-extraction refusals. Grepped the template —
  none found (LEARN's "reflect on the real cause" asks for cause analysis, not
  a reasoning transcript; safe). Keep this grep in every future devops audit.
- **Classifier routing (new, per-project decision):** Fable 5 can refuse
  offensive-cyber-adjacent work, and benign security tasks may also trigger;
  the official fallback is Opus 4.8. `security-reviewer` /
  `infra-security-reviewer` / exploit-adjacent debugging should be routed to
  Opus 4.8 (or Opus 5 after evaluation) DELIBERATELY, not discovered via
  mid-run refusals. Record the role→model mapping in `decisions.md`, dated.
- **Validation:** the template's memory architecture (lessons.md, .agent/state,
  capsules) matches Fable 5's recommended memory-system pattern — keep as is.

## Mechanism installed in this draft (additive, CORE untouched)
- `.claude/skills/devops/SKILL.md` — the audit procedure (lineup check → triage
  against live vendor guides → human veto → survival test → record) + harness
  health + pointer to archived infra roles for live ops.
- `scripts/state-freshness.sh` §3 — deterministic, zero-network staleness banner:
  `Last audited:` older than `Cadence days:` (default 35) → ⚑ ATTENTION at
  session start. A rule would be a hope; the hook makes the cadence enforced.
- `.agent/state/model-audit.md` — the dated record (pointer, not truth).
- `.claude/commands/devops-audit.md` — on-demand run.
- CLAUDE.md: +2 pointer lines in MEMORY (non-CORE, v8.1.7 pattern); AGENTS.md:
  devops added to the reading list + Codex note (no SessionStart there — check
  the audit age manually at session start).

## Order of application
1. Ship the mechanism (already in this draft) — zero risk, CORE hash unchanged.
2. Apply F3–F5 (non-CORE) after your edit/veto.
3. Apply F1–F2 with a Kernel Change Rationale + re-baseline in one commit.
4. Survival test: one normal full-lane task; then log the audit in model-audit.md.
