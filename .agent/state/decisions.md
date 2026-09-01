# Decisions (append-only)
<!-- Never rewrite. Each: date — decision — why — (supersedes?) -->

<!-- - 2026-05-30 — use pnpm — faster CI, lockfile already present — supersedes none -->

- 2026-08-18 — v8.1.9 P1 package (9 decisions, human-approved one by one):
  (1C) risk matrix + automode owns process/approval/agents, DESTRUCTIVE never shifts;
  (2B) reviewers expose disagreement, verifier filters, escalation table in skill;
  (3C) agents per matrix row, lanes deleted; (4B) verification-first + proof table
  in pipeline; (5B) Codex parity via .codex/hooks.json, shared skills → v8.2 backlog;
  (6A) checkpoint stages task scope only, no add -A on dirty tree, no stashing
  others' work; (7B) project-map: active≠available, honest degradation; (8B) /init
  guidance via ownership not capability; (9B) CLAUDE.md ≤200 target, hard cap 250,
  MY RULES stay in git (VPS portability). CORE re-baselined with this rationale.

- 2026-08-30 — cross-review mapping (v8.3.0): SHERIFF = Codex CLI (GPT-5.x line);
  ARBITER = Claude Fable 5, fresh chat. Roles fixed in the `cross-review` skill;
  re-check this mapping at each devops audit (model-selection.md). To save tokens
  or on a lineup change, edit THIS line only — e.g. ARBITER = Opus 5.

- 2026-08-30 — canonical sheriff wrapper = the field-proven copy from hermipro-vps
  (4 review rounds, 9 findings, 0 disputes; exit contract 0/1/3/4/5/6; --author
  API, stdin package). Template converged on it in v8.3.4; provenance:
  docs/sheriff-provenance_2026-08-30_v1.md. Template deltas vs the export: the
  Pluggable toggle section in the skill, and `--version </dev/null` in the
  wrapper's probe (portability; owes an upstream sheriff round).

- 2026-08-30 — sheriff round 5 folded (v8.3.5): wrapper invokes its CLI through
  $SHERIFF_TOOL at every site (probe and review can no longer validate different
  executables); locked by the single-spelling assertion in test-hooks §8 (29
  assertions). Rule adopted into UPGRADE.md UPDATE POLICY verbatim: "An additive
  upstream delta is still a diff, and still owes a sheriff pass." Export arrived
  CRLF; line endings normalized to LF (not a logic delta).

- 2026-09-01 — migrated template pre-v8 (unversioned BLC framework, seeded
  2026-04-21) → v8.3.13 **by transplant** (UPGRADE.md section T): the project had
  none of the v8 markers (no CORE sentinel, no `.claude/core.sha`, no `.agent/state/`,
  no `TEMPLATE_VERSION`, no git repo), so the old machinery died wholesale and only
  project knowledge was carried into the new skeleton. Inventory:
  `_reports/migration-pre-v8-to-v8.3.13_2026-09-01.md`. CORE is verbatim from the
  template (hash equals the shipped `.claude/core.sha`) — no kernel change, no
  re-baseline. Rollback = branch `main`, commit 863ef05.

- 2026-09-01 — retired the pre-v8 rule set (`autonomy`, `delegation`,
  `context-management`, `commit-policy`, `local-first`, `logging`,
  `production-safety`) rather than merging it: every one of its guarantees is now
  owned by a v8 mechanism — RISK MATRIX & AUTOMODE (autonomy + delegation +
  production-safety), Context Guard + `context-hygiene.md` + PreCompact snapshot
  (context-management), `checkpoint` skill + `guard.sh` + `.gitignore`
  (commit-policy), `session-log` skill (logging). `local-first.md` had no referent
  at all here — BLC holds no database and no application code.

- 2026-09-01 — dropped `manifest.md` / `repo_access=private-solo`: v8 has no
  repo_access concept and ships no `scripts/switch-repo-access.sh`. This repo is
  local-only with no remote, and the v8 `.gitignore` + `guard.sh` secret scan cover
  what the mode was protecting. If a remote is ever added, revisit before the first push.

- 2026-09-01 — retired `.claude/agent-memory/` (pre-v8 per-agent memory store).
  Its two files were folded into `.agent/capsules/mockups-design-system.md`; the
  v8 memory-router owns routing from now on, and the workspace contract states
  there is no shared agent-memory store.

- 2026-09-01 — KEPT OURS on `scripts/pre-commit` (one line + comment): its staged-secret
  scan now excludes `scripts/test-hooks.sh`. Why — the template's own suite must contain
  synthetic `sk-…` / `ghp_…` / `xoxb-…` fixtures as negative controls proving `guard.sh`
  returns exit 2, so the shipped hook blocks the shipped suite and no v8 project can make
  its first commit. Verified narrow: a planted `sk-proj-…` in `temp/` is still blocked
  (rc=1). This is a template defect, not a project preference — re-check it at every
  upgrade and drop the divergence once upstream fixes it.

- 2026-09-01 — trust-pill price is LIVE DATA, not a design token. The pre-v8 design
  system locked "From $0.06"; `index4.html` ships "From $0.39"; the live site's
  cheapest case is $0.11 [verified 2026-09-01 via WebFetch]. All three are snapshots
  of a moving number. Resolution: the capsule now states the invariant — *the pill
  equals the cheapest case price displayed on that same page* — and index4 is
  CORRECT as-is ($0.39 pill, $0.39 cheapest card, internally consistent). No mockup
  was edited. Supersedes the "From $0.06" line in the retired CLAUDE.md design system.

- 2026-09-01 — `gaming-product-owner` and `gaming-ux-strategist` moved
  `model: sonnet` → `model: opus`. Why: `.claude/rules/model-selection.md` gives the
  strongest model to thinking-heavy phases (brainstorm, spec, plan, review), and
  these two ARE this project's analysis/review layer — BLC ships no code, so every
  task they run is judgment work. Consistent with the shipped roster, where every
  analyst/reviewer (`architect`, `business-analyst`, `code-reviewer`, `ui-ux-qa`,
  `verifier`) is opus and only `block-executor` (mechanical execution of an approved
  plan) is sonnet. Stated, not silent, per the rule. Re-check at the next devops audit.

- 2026-09-01 — trimmed both gaming agents 233→109 and 235→113 lines. The removed
  ~120-line tail of each was a persistent-agent-memory instruction block pointing at
  `.claude/agent-memory/<agent>/`, a directory retired earlier the same day — dead
  instruction aimed at a nonexistent path, which would have had each agent recreate
  the store the workspace contract forbids. Replaced with correct v8 routing
  (memory-router targets, the decay rule, and the hard scope limit). All domain
  expertise, the operating framework, the output format and the self-verification
  checklist were kept verbatim — that is the knowledge the transplant exists to carry.

## 2026-09-01 — upgraded template v8.3.13 → v8.3.16 (merge route)
Artifact `template-v8.3.16-all-in-one.zip`; canonical build `release/v8_3_16.zip`
sha256-verified against its shipped `.sha256`. Route = merge (§2–5), not transplant:
same major, every v8 marker present, and `.claude/core.sha` byte-identical between
FROM and TO — so **no CORE change, no Kernel Change Rationale, no re-baseline**.

**Notable merges/vetoes**
- *Dropped both BLC workarounds.* v8.3.14 fixed the D1/D2 defects this project
  reported, at the source. `scripts/pre-commit` and `scripts/quality-gate.sh` are now
  byte-identical to the template again; **risk R1 is resolved**, not merely mitigated.
  Proof the D1 fix works: this branch's first commit staged `scripts/test-hooks.sh`
  with its synthetic secrets and was allowed.
- *Kept ours* on `.gitignore`, `docs/ROLES.md`, `.claude/settings.json` — in each the
  template's own content is unchanged and only BLC lines were added, so taking the
  template would have silently deleted project content, not "updated" the file.
- *Hand-merged two.* `CLAUDE.md`: the MY RULES ADHD bullet now points at the new
  `.claude/rules/communication.md` (the template moved the formats into a
  path-scoped rule; the kernel stays at 213 lines). `.agent/state/context-index.md`:
  took the `current.json`-authoritative + `state-schema.json` lines, kept the BLC
  capsule/mockup/client-material pointers.
- *Adopted, not just installed, the v8.3.16 execution state.* `.agent/state/current.md`
  is now a RENDERED VIEW of `current.json` — hand-edits there are lost on the next
  render. Two patches seeded the state from the old `current.md` first, so nothing
  was dropped in the conversion.
- *Survival test waived* under §5: the upgrade changes zero BloodyCase deliverable
  bytes; the 146-assertion suite and the gate run on the post-merge tree instead.
- *`devops` audit (step 4) deliberately not folded in.* It is overdue on its own
  35-day cadence, but it is a model/vendor-guide audit, not part of this file merge —
  it stays a separate task rather than a silent rider on an upgrade.

**New upstream findings** (D3: `state-patch.py --self-test` dies on a Windows cp1252
console; plus a stray `.env` in the shipped folder, absent from the canonical zip) —
see `_reports/runs/template-upgrade-v8.3.16_2026-09-01.md`.
