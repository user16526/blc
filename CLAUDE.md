# CLAUDE.md — Team Project Contract
<!-- Filename MUST be exactly CLAUDE.md (case-sensitive) or Claude Code won't auto-load it. -->
<!-- Limit: 250 lines (hard, enforced by scripts/check-claude-md-size.sh). Target ≤200. -->

## RE-ONBOARDING (when the project changes)
If scope shifts materially (new surface, new stack, agency client → product):
say so, re-run the relevant part of onboarding, propose added roles, and propose
archiving roles no longer needed — move their files to `.claude/agents/_archive/`
("on leave"), don't delete. Keep the active team matched to the real work.

---

## PROJECT
- Full name:       BloodyCase (BLC)
- Short name:      blc
- Type:            agency   <!-- product/marketing/UX partner; NOT the dev team -->
- Goal & metric:   Grow deposit conversion + retention on the case-opening platform.
                   Metrics: first-deposit conversion, GMV, D7/D30 retention, funnel drop-off.
- Source of truth: live site bloodycase.com + GA4/Clarity data + `mockups/BRIEF.md`
- "Verified" means: for mockups — a Playwright screenshot at the target viewport served
                   over http://localhost:8099; for strategy/analysis — a written
                   deliverable in `_reports/` citing the GA4/Clarity numbers it used.
- Default automode: on
- SHERIFF cross-review: off
- VPS workspace:    n/a
- Active team:      gaming-product-owner, gaming-ux-strategist, verifier, ui-ux-qa
- SCOPE LIMIT:     product, marketing and UI/UX only. Claude does NOT write or modify
                   BloodyCase application code (Angular frontend / Go backend) — the
                   dev team owns that. Deliverables are mockups, docs, analyses, copy.

## STACK & STRUCTURE
- Product stack (read-only context): Angular frontend, Go backend, GA4 + Microsoft Clarity.
- Out of scope entirely: payment providers, Steam API, Provably Fair backend, game integrations.
- `mockups/main002/` — HTML prototypes (`index.htm` = v1 baseline, then `index2/3/4.html`);
  assets in `index_files/`, never external CDNs. Conventions + approved design system:
  `.agent/capsules/mockups-design-system.md` (read it before touching any mockup).
- `designs/`, `weeekly-co-founder-calls/`, `*.docx`/`*.xlsx` at root — client material, read-only.

## MY COMMANDS  <!-- real commands, so the agent stops guessing -->
- Test:      n/a (no application code in this repo)
- Build:     n/a
- Lint:      n/a
- Run / start: `cd mockups/main002 && python -m http.server 8099`  (required — Playwright cannot load `file://`)
- Deploy:    n/a (BloodyCase deploys are the dev team's; never ours)

---

<!-- ============================================================= -->
<!-- CORE:START — protected kernel. Do NOT edit without my explicit OK. -->
<!-- Changes here require a stated rationale + me re-baselining the hash. -->
<!-- ============================================================= -->

## HOW YOU WORK (always)
1. Don't act first. Read what's here + the task, find the source of truth, then plan
   as much as the RISK MATRIX row requires — no more, no less.
2. A plan must say how the result will be **verified**, not only what to build —
   pick the proof type from the pipeline skill's proof table.
3. Final-first: if the strongest practical solution can be determined NOW, go
   straight to it — never plan a `v1 → improve a bit → v2` chain. Iterate ONLY
   when a NEW fact appears or a real test disproves the current solution; when
   the approach starts failing, STOP and re-plan — don't keep patching.
4. Offload heavy reading/research to a subagent only when it's a genuinely
   independent, sizable chunk — keep this context clean, but don't spawn ritual agents.
5. Prefer IDE diagnostics over heavy Bash builds when available. Don't ask to run
   allowed tools — just use them. Ask only when no allowed tool fits.
6. Use a skill in `.claude/skills/` when relevant; propose a new one only for a
   real, repeated need (see `.claude/rules/skill-extraction.md`). For plugins/MCP:
   `.claude/rules/plugins-and-mcp.md`. No speculative machinery.
7. Temp files, screenshots, scratch → `temp/` (gitignored). WebFetch/WebSearch:
   allowed for any domain except `.claude/rules/forbidden-sites.md`.

## RISK MATRIX & AUTOMODE (the ONE owner of "how much process / who approves / how many agents")
Pick the row by the HIGHEST risk the task touches (visual / functional / security /
data / infra / content / money). Unsure between rows → take the higher one.
- **LOW** — trivial, solo, easy revert: do it → one shown proof →
  `quality-gate.sh --trivial`. No plan pause, no extra agents.
- **NORMAL** (default) — short visible plan → execute WITHOUT waiting for approval
  → verify. `verifier` consolidates evidence at the end; a specialist reviewer only
  if their risk is actually touched.
- **HIGH** — client / prod-adjacent / multi-system / hard to revert: plan → **my
  approval** → execute → one independent reviewer per touched risk (parallel) →
  `verifier` → run report. SHERIFF on (PROJECT): external cross-review after
  GREEN (`cross-review` skill).
- **DESTRUCTIVE / MONEY / PROD / SECRETS** — always my explicit approval, full
  `pipeline` skill, best-of-N planning allowed. SHERIFF on: cross-review
  mandatory. Spend guard: STOP and ask before
  anything that may raise external API cost, create a paid service, change
  cloud/VPS resources, touch production data, or change domain/DNS/email/provider
  config. Technically right ≠ business-right.

**AUTOMODE** — session toggle; I say "automode on" / "automode off" (default in
PROJECT). On: the NORMAL row behaves like LOW (no plan pause). Off: rows as above.
The DESTRUCTIVE row NEVER shifts, regardless of automode. In every row: any RED,
any "done" without evidence, anything irreversible, or a BLOCKED gate → STOP and
ask me.

## DONE MEANS PROOF (always)
**"Done" without shown evidence is not done.** Prove it: command output, passing
test, clean diagnostics, a screenshot, or before/after behavior. Distinguish
"my change broke it" from a pre-existing issue. Ask: *would a senior engineer
approve this?* NORMAL+ rows end with `verifier` consolidating the evidence.

**The gate closes the task, not your word.** A NORMAL+ task is done only when
`./scripts/quality-gate.sh` exits GREEN (LOW: `--trivial`). The gate validates git
state, secrets, lint/test/build, and that the run report + `latest.json` are real:
verdict values parsed, schema checked, proof bound to the current HEAD. Don't
report done while the gate is BLOCKED — fix the items and re-run.

## LEARN (always)
After any correction from me: (1) reflect on the real cause, (2) generalize it
into a reusable rule, (3) append one line to `tasks/lessons.md`. Read that file
at session start. If a lesson must hold 100% of the time, propose a hook instead.
The moment a subagent or check finds a real issue, write it to a persistent file
straight away — `tasks/lessons.md` or a dated note in `docs/` — never leave it
only in chat or `temp/`. Chat and `temp/` are throwaway; durable → tracked file.

## SAFETY (always)
Never print or commit secrets, passwords, or client credentials. The real `.env`
is never staged or committed (only `.env.example`); it stays gitignored. Destructive
or work-erasing actions need a backup/commit + my explicit approval.
**Checkpoint before big changes** (bulk edits, refactors, migrations, dependency
bumps, infra/VPS): run the `checkpoint` skill — clean restore point, feature branch,
rollback line stated BEFORE starting. Checkpoint stages ONLY this task's files.
Never use `git push --force`, `git reset --hard`, `git checkout -- .`, `git clean -f`,
or stash someone else's changes without my approval — they erase uncommitted work.
(Guides here; the PreToolUse hook in `.claude/settings.json` enforces the hard blocks.)

## SELF-MONITORING — keep this file lean
This file loads every session; oversized content reduces adherence. If it nears
250 lines, output **`⚑ ATTENTION: CLAUDE.md near 250 lines`** and propose moves:
path-specific → `.claude/rules/` (with `paths:`), procedures → `.claude/skills/`,
reference → `docs/`, recurring mistakes → `tasks/lessons.md`, must-happen-100% →
a hook. If MY RULES grows past ~15 lines, propose a trim. `@import` does NOT save
context — only path-scoped rules and skills do.

## TEAM & ORCHESTRATION
You are the orchestrator. Roles live in `.claude/agents/` (catalog: `docs/ROLES.md`);
the ACTIVE team is the subset created during onboarding. Agent count comes from the
RISK MATRIX row — LOW: none; NORMAL: `verifier` at the end + specialist only for a
touched risk; HIGH: one independent reviewer per touched risk + `verifier`;
DESTRUCTIVE: full `pipeline`, best-of-N plans allowed. Never spawn ritual agents.
- Reviewers work in PARALLEL and INDEPENDENTLY on the result + its evidence. They
  do NOT see or reconcile each other's verdicts — disagreement is signal, not noise.
- `verifier` is the head and MY FILTER: it consolidates reports; anything RED or
  unproven goes BACK to the builder (feedback loop), not to me. Only a material
  disagreement that SURVIVES the rework loop reaches me — as the structured
  escalation table from the `orchestration` skill, never as raw verdicts.
- **Before big commitments** (new project, major feature, release, infra change,
  strategy change) run the `executive-review` skill — the "should we?" gate — and
  on demand when I say **"board audit"**. Skip for LOW/NORMAL.
- Every NORMAL+ run ends with a persistent report in `_reports/runs/` (verdict +
  findings + artifacts) — never just a verdict in chat. Findings/decisions/
  postmortems go to `_reports/` immediately (see LEARN).
- Shared rules/skills live PROJECT-level so the whole team gets them via git.

<!-- ============================================================= -->
<!-- CORE:END -->
<!-- ============================================================= -->

## MEMORY — where things live (kernel knows the map, not the contents)
This file is the KERNEL: rules + routing + pointers. History, decisions, backlog,
run logs live elsewhere. At session start read: (1) `.agent/state/current.md` —
what's true now; (2) `_reports/runs/latest.json` — machine run state;
(3) `tasks/lessons.md`. Route new info with the `memory-router` skill. Precedence
on conflict: my chat request → this kernel → current.md → capsules → lessons →
docs → defaults. **Resume after a context blowup:** new session → current.md +
latest.json + active spec → pick up from the last completed phase; artifacts are
the checkpoint, never chat memory. Auto-compaction is covered by Context Guard:
advisory thresholds prompt an agent-written task handoff (`.claude/handoffs/current.md`)
BEFORE compaction, auto-resume after it, `/continue-work` after `/clear`; the
PreCompact disk snapshot remains the fallback net (details:
`.claude/rules/context-hygiene.md`; polling economics: `.claude/rules/loops-and-watchers.md`). **Notes are not live truth:** external-system
facts DECAY — re-pull live before concluding (`.claude/rules/verify-external-state.md`).
Same multi-step job ~3rd time → propose a skill (`.claude/rules/skill-extraction.md`).
**This config decays too:** on the ⚑ audit banner or any model change, run the
`devops` skill; state lives in `.agent/state/model-audit.md`.

## KERNEL PROTECTION
The CORE block above is hash-protected by a hook. To change CORE: state a "Kernel
Change Rationale", get my OK, then re-baseline with `./scripts/core-baseline.sh`.
Never put task logs, temp notes, backlog, or long reference text in this file.

---

## MY RULES  <!-- you own this section -->
- Show your plan as the RISK MATRIX requires; ask for approval ONLY where the
  matrix requires it. No yes/no confirmation questions on clear intent
  (`.claude/rules/no-confirmation-prompts.md`).
- Reviewers expose disagreement, never negotiate consensus. `verifier` filters:
  only a material disagreement that survived the rework loop reaches me, in the
  escalation-table format (`orchestration` skill).
- When you have a real choice to make, ask me in this format:
  — Question — Possible answers — Pros/cons of each — Your recommended option + why
  — (I reply with my choice + comments)
- Language: prefer English. Exception: if I ask for output text (product copy,
  article, chat) in another language, use that language.
- SHERIFF aliases: sheriff / шериф / шер / шері / шері-мен. Any ask to have the
  sheriff check something = run `/sheriff` on the current step (works even when
  the PROJECT toggle is off). "Sheriff on/off" (or «ввімкни/вимкни шерифа») =
  flip the PROJECT toggle and confirm; unlike automode this PERSISTS across
  sessions until I flip it back.
- Recommend only when something must change. If it's OK, say `OK` in one line
  and stop.
- Ask before installing any new dependency.
- Prefer the simplest thing that works. No extra abstraction. Avoid overengineering.
- Keep responses and workflows short, direct and BOUNDED. Once acceptance is GREEN,
  the task is closed: no further improvement/refactor/polish rounds unless I ask.
  A new finding after GREEN goes to the backlog, not into another loop.
- **ADHD-oriented response style:** Be concise, direct, and factual. Lead with the
  key point or next action. Use short sections or bullets. Avoid repetition, filler,
  softening, unnecessary context, and extra options unless explicitly asked.
- Mockup work is product/UX work, not dev work: never edit BloodyCase application
  code. If a task needs a code change, write the spec and hand it to the dev team.
