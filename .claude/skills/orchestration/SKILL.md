---
name: orchestration
description: How the orchestrator picks reviewers and runs the self-checking loop. Use whenever coordinating subagents to verify a result before it's considered done.
---

# Orchestration: risk-based review + feedback loop

The goal: results come back already verified, so I don't have to chase "did QA
check this, did someone check QA". You (orchestrator) own that chain.

## Step 1 — Map the risk of the change
Before assigning reviewers, name which risk types the change actually touches:
- **visual** — UI appearance, layout, responsive, states
- **functional** — behavior, logic, data flow, edge cases
- **security** — auth, input, secrets, OWASP, permissions
- **data** — schema, migrations, money, irreversible writes
- **infra** — deploy, VPS, config, services
- **content** — copy, brand voice, claims, consent/legal

## Step 2 — Agent count comes from the RISK MATRIX row (CLAUDE.md)
LOW: no reviewers. NORMAL: `verifier` at the end; a specialist ONLY if their risk
is touched. HIGH: one independent reviewer per touched risk + `verifier`.
DESTRUCTIVE: full pipeline, best-of-N planning allowed. Never review risks the
change doesn't touch; never spawn ritual agents.

| Task example | Risks | Reviewers (typical) |
|---|---|---|
| Tweak spacing/color on a page | visual | `ui-ux-qa` (1) |
| Edit existing component behavior | visual + functional | `ui-ux-qa` + `functional-verifier` (2) |
| New page with business logic | functional + security + (data) | `functional-verifier` + `security-reviewer` (+`architect`/devops if data/infra) |
| Auth / payments / migration | security + data + functional | `security-reviewer` + `functional-verifier` + `architect` (3) |
| Marketing landing + tracking | visual + content + functional | `ui-ux-qa` + `functional-verifier` (+content check) |
| Release / deploy | whatever shipped + infra | 3, always incl. `security-reviewer` |

If a task doesn't fit the table, fall back to the principle: one reviewer per risk
present, minimum one independent, escalate to 3 for releases or irreversible actions.

## Step 3 — Run reviewers in PARALLEL and INDEPENDENTLY
Each reviewer sees the RESULT and its EVIDENCE, in its own fresh context. They do
NOT see each other's verdicts — independence is what prevents rubber-stamping.
Each returns: findings (severity-tagged) + PASS/NEEDS-FIX + evidence checked.

**Honest limit of "independence":** all reviewers run on the same base model, so
they are CORRELATED — a blind spot one has, the others may share. Fresh context
reduces rubber-stamping; it does not give you truly independent judges. So: for
genuinely high-stakes/irreversible work, the human is the real independent reviewer
— don't treat 3 green subagents as a substitute. (On Codex, "sequential passes"
are weaker still: same weights, same session — closer to one opinion than three.)
When the lead runs a different model than the reviewers (e.g. a Fable 5.1 lead with
`opus` reviewers) the correlation is partial, not total — still not a substitute for
the human on irreversible work.

**Model cost (tunable):** reviewers default to `opus` for max quality (time >
tokens). If a project's token budget matters more, downgrade the non-high-risk
reviewers to `sonnet` in their agent files; keep `opus` for security/data/infra.

## Step 4 — `verifier` is the head; it closes the loop
`verifier` consolidates all reviewer reports against the spec and decides:
- All PASS with real evidence → GREEN. Proceed per the RISK MATRIX row.
- Any NEEDS-FIX, any RED, or any claim without evidence → **send the task back to
  the builder with the specific findings** (feedback loop), then re-review only what
  changed. Repeat until GREEN or until it hits me.
- Never upgrade a verdict to pass a claim that has no proof. "Looks done" ≠ done.

## Escalation to the human — verifier is the FILTER, not a relay
Raw reviewer verdicts never go to the human. Order of operations:
1. Disagreement that a rework can plausibly resolve → send back to the builder
   with the specific findings (normal feedback loop). Re-review only what changed.
2. Only a MATERIAL disagreement that SURVIVES the rework loop (typically security/
   data RED vs another reviewer's GREEN, or a conflict that is really a business
   decision) escalates — as ONE structured table:

| Reviewer | Verdict | Key argument | What would clear their objection |
|---|---|---|---|

   ...plus the verifier's own recommendation + why. The human decides in one pass.
3. Automode never applies here: an escalated disagreement always waits for the human.

## Stop conditions (override the matrix row)
Stop and ask me on: any RED that can't be auto-fixed in ≤2 loops, anything
irreversible (data/infra/spend), a security finding, or scope drift from the spec.
