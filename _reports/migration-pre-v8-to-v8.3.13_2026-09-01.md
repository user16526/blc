# Migration inventory — BLC: pre-v8 → template v8.3.13 (transplant)

Date: 2026-09-01 · Route: UPGRADE.md **section T** (major-version gap / no v8 markers)
FROM: pre-v8, unversioned in-house BLC framework (seeded 2026-04-21; no
`TEMPLATE_VERSION`, no `CHANGELOG.md`, no `.claude/core.sha`, no `.agent/`, no git repo)
TO: v8.3.13 (`D:\claude\1-claude-templates\v8_3_13-cg4.zip`)
Rollback: branch `main`, commit `863ef05` ("Pre-upgrade baseline"). Work branch:
`template-upgrade-v8.3.13`.

## Why transplant and not merge
The project had none of the v8 markers the procedure tests for: no CORE sentinel in
CLAUDE.md, no `.claude/core.sha`, no `.agent/state/`. Its framework was a different
lineage (a 7-rule set + 4 shell hooks + 6 skills), not an older v8. Per section T the
direction reverses: the new skeleton is stood up clean and only project KNOWLEDGE is
carried into it.

## Pile 1 — project knowledge (transplanted)
| Source | New home |
|---|---|
| CLAUDE.md § Purpose (platform, game mix, modes, monetization, auth providers) | `.agent/capsules/bloodycase-product.md` + CLAUDE.md → PROJECT |
| CLAUDE.md § Architecture / Contracts & Integrations (Angular, Go, GA4, Clarity; out-of-scope list) | CLAUDE.md → STACK & STRUCTURE + the product capsule |
| CLAUDE.md § "Claude's role is product/marketing/UI-UX only — no dev" | CLAUDE.md → PROJECT "SCOPE LIMIT" + MY RULES + `tasks/lessons.md` |
| CLAUDE.md § Mockup Conventions (versioning, app-shell constraint, fantaicon, local http.server) | `.agent/capsules/mockups-design-system.md` |
| CLAUDE.md § Approved Design System (typography, tokens, hero, trust signals, glassmorphism, +25% copy) | `.agent/capsules/mockups-design-system.md` (verbatim values) |
| CLAUDE.md § Agents — Routing Guide | `docs/ROLES.md` → "Project-created roles (BLC)" + CLAUDE.md → PROJECT "Active team" |
| CLAUDE.md § MY RULES (ADHD response style) | CLAUDE.md → MY RULES (already present in the v8 template's MY RULES; kept once) |
| `.claude/agents/gaming-product-owner.md`, `gaming-ux-strategist.md` | kept in `.claude/agents/` (audited — see below) |
| `.claude/agent-memory/gaming-ux-strategist/*` (v2 design alignment, index3 UX patterns, competitor findings) | folded into `.agent/capsules/mockups-design-system.md`; the "real `<img>` assets, never placeholder boxes" finding also became a lesson |
| `.claude/SNAPSHOT.md` (empty beyond a 2026-04-21 stub) | `.agent/state/current.md` |
| `mockups/`, `designs/`, `weeekly-co-founder-calls/`, root `*.docx` / `*.xlsx` / `*.png` | untouched in place; pointed at from `.agent/state/context-index.md` |
| `.claude/settings.local.json` (playwright MCP + skill permissions) | untouched, project-owned |
| `.claude/settings.json` permissions + `thinkingBudget: max` | merged into the template's settings.json |

## Pile 2 — old template machinery (died with FROM)
Replaced wholesale by the v8 mechanism named in brackets. Full text remains on
branch `main` and in `temp/retired-pre-v8/`.
- `.claude/rules/autonomy.md` [RISK MATRIX & AUTOMODE]
- `.claude/rules/delegation.md` [RISK MATRIX row → agent count, `orchestration` skill]
- `.claude/rules/production-safety.md` [DESTRUCTIVE row + `deploy` skill + `guard.sh`]
- `.claude/rules/context-management.md` [`context-hygiene.md`, PreCompact snapshot, Context Guard]
- `.claude/rules/commit-policy.md` [`checkpoint` skill + `guard.sh` secret scan + v8 `.gitignore`]
- `.claude/rules/logging.md` [`session-log` skill + `_reports/runs/`]
- `.claude/rules/local-first.md` [**no referent** — BLC holds no database and no application code]
- `.claude/hooks/{pre-compact,post-compact,post-tool-checkpoint,subagent-done}.sh` [`scripts/*.sh` hooks wired in the template settings.json]
- `.claude/skills/{start,finish,housekeeping,testing,playwright,db-migrate}` [v8 skills + `/start`, `/verify`, `quality-gate.sh`]
- `.claude/agents/{implementer,researcher,reviewer}/` [`block-executor`, `architect`, `code-reviewer`, `verifier`]
- `manifest.md` (`repo_access=private-solo`) [no v8 equivalent — see decisions.md]
- `.claude/logs/`, `.claude/.tool-counter` [artifacts of the retired hooks]
- `scripts/` [was empty; the two scripts its docs referenced — `switch-repo-access.sh`, `migrate.sh` — never existed]

## Quarantine — nothing
Every file classified. No unclassifiable leftovers.

## Devops audit of transplanted instructions (section T step 3)
- **`memory: project` frontmatter removed** from both gaming agents. It rebuilt the
  pre-v8 `.claude/agent-memory/` store, which the workspace contract and the v8
  `memory-router` both replace with `.agent/` + `tasks/lessons.md`.
- **`tools:` lists trimmed** on both agents, from a 30-entry auto-generated dump
  (CronCreate/CronDelete/RemoteTrigger/PowerShell/Monitor/Google-Drive MCP/…) to
  `Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, Skill`. `Write` is kept
  deliberately: CORE requires every NORMAL+ run to leave a report in `_reports/`.
- **`model: sonnet` left as-is** on both. `.claude/rules/model-selection.md` forbids
  silently changing a model mid-project — this is owed to the owner as a decision.
- **Agent bodies (233 / 235 lines) left verbatim.** They are domain knowledge, which
  is exactly what section T says to transplant. They are long and prescriptive by
  current-model standards; a trim is proposed, not taken. See "Still owed".
- Grep for reasoning-echo instructions (Fable refusal hazard) across the
  transplanted files: clean.

## CORE
Verbatim from the template. `sha256` of the CORE block equals the shipped
`.claude/core.sha` (`ec9f3774f581b09c572c5f2312b3abe03765c305cd86f3fe6aaada1a9272d11b`)
— no kernel change, no re-baseline, no owner OK required.

## Still owed
1. `model: sonnet` on both gaming agents — confirm or change (owner decision).
2. Trimming the two 230-line agent personas — proposed, not done.
3. Context Guard opt-in for this project — config shipped, installer not run.
4. If a git remote is ever added, revisit what the retired `repo_access` mode protected.
