# Current State
<!-- RENDERED VIEW. Authoritative state: current.json, merged only via
     scripts/state-patch.py (LLM proposes, script merges). Hand-edits here
     are lost on the next render — patch instead. -->

Last updated: 2026-09-02 02:26

## Goal
- Happy Hour A/B test (BloodyCase) resumed in BLC: design + blockers restored from the remote host's Claude memory into .agent/capsules/happy-hour-ab-test.md; next step is the owner's pick among the 6 open blockers

## Constraints
- SCOPE LIMIT: product/marketing/UI-UX only - never edit BloodyCase application code
- Upgrades are HIGH-row: checkpoint branch first, rollback = git checkout main

## Verified (evidence, not memory)
- template_version: v8.3.21 (merge route 2026-09-02, gate GREEN; run report _reports/runs/template-upgrade-v8.3.21_2026-09-02.md)
- core_sha: unchanged ec9f3774 across v8.3.19->v8.3.21 - no kernel change, no re-baseline
- test_hooks: 146/0 GREEN on the v8.3.21 tree [2026-09-02]
- state_patch_self_test: GREEN under default console, utf-8 and cp1252 - D3 closed on this tree
- sheriff_probe: OK - automation available (toggle off)
- release_zip_sha256: v8_3_21.zip sha256 c93041a8... computed here - NO .sha256 companion shipped, unverified against a published value
- devops_audit: 2026-09-01 vs Fable 5.1 guide - RESOLVED: F9-F14 applied (owner), suite 146/0; sheriff prompt is now a BLC-local canonical divergence (decisions.md)
- template_newest_release: v8.3.21 (2026-09-02) - docs/comment-only gap from v8.3.19; TAKEN, TEMPLATE_VERSION = v8.3.21
- pg_tunnel_scripts: scripts/pg-tunnel.ps1 + pg-mcp-register.ps1 + Read-DotEnv.ps1 parse clean (PS 5.1), fail loudly without .env keys; claude mcp add/remove dry-run OK with dummy URI; uvx --with mcp<2 postgres-mcp --help exit 0 [2026-09-01]
- pg_tunnel_e2e: ssh key auth sparrow@168.119.74.101 OK; host bloodyanalytics02 runs Postgres 18 on 5432, db bloody; tunnel up -> localhost:5432 TcpTestSucceeded; claude mcp get postgres = Connected (restricted mode) [2026-09-02 via scripts/pg-tunnel.ps1 + pg-mcp-register.ps1]
- mcpb_command: .claude/commands/mcpb.md registered as /mcpb; scripts/pg-tunnel-ensure.ps1 starts the tunnel in a minimized window when 5432 is closed and reports UP when it is [2026-09-02]
- happy_hour_restore: remote memory happy_hour_ab_test.md (last real work 2026-08-27) + docs/features/happy-hour-backend.md pulled read-only from sparrow@168.119.74.101; host sessions 2026-08-31 and 2026-09-01 were restores only, no new decisions [2026-09-02]
- happy_hour_dev_status: eugene_s 2026-09-01: A/B split implemented for logged-in users only (33.3/33.3/33.3, control/02UTC/18UTC), UAT only; events gate_shown/shown/spun; guests excluded; blocker #6 closed [source: owner-pasted dev comment 2026-09-02]
- happy_hour_blocker1: standing 1st-deposit bonus 20%/25% (>=~$20), 2+ deposits 6-10%; from live public.deposits 90d, report _reports/blc-data_2026-09-02_0030_v1.md [2026-09-02]

## Working set
- Framework only. No product task active - next real BLC task starts fresh under the v8.3.21 kernel.
- Approved mockup design system locked 2026-05-18: .agent/capsules/mockups-design-system.md
- Product/domain facts: .agent/capsules/bloodycase-product.md

## Decisions (1-liners; reasoning -> decisions.md)
- v8.3.13 -> v8.3.16 taken by merge route: same major, CORE byte-identical
- Local D1 pre-commit divergence and D2 report-format workaround dropped for the shipped fixes (v8.3.14 fixed both at source)
- Kept ours where the template part was unchanged and only BLC lines were added: .gitignore, docs/ROLES.md, .claude/settings.json
- D1/D2 are CLOSED upstream in v8.3.14; risk R1 dissolves - no BLC-local template patching
- Merged to main as 659e4fe; gate GREEN on the merged tree
- D3/D4 SHIPPED UPSTREAM in v8.3.17 (canonical zip sha256 415594db, verified here against the artifact); upgrade queued not taken - owner set normal cadence
- Devops audit 2026-09-01: lineup moved Fable 5 -> Fable 5.1; F5 (opus/sonnet cost table) closed - aliases and prices still valid, effort is the cheaper lever
- v8.3.16 -> v8.3.19 taken by merge route 2026-09-01: 6 replaced, 1 new, 0 hand-merges, CORE unchanged; merged to main as 27b43e7
- v8.3.19 -> v8.3.21 taken by merge route 2026-09-02: 13 replaced, 0 hand-merges, TEMPLATE-DELTA.md deleted, CORE unchanged; survival test waived (zero executable bytes changed)

## Failed / rejected (do NOT retry)
- Local one-line pre-commit exclusion for test-hooks.sh - superseded by the shipped, suite-asserted v8.3.14 fix; do not reintroduce
- Reporting D1/D2 upstream from inside BLC - releases are build products of the maintainer canonical tree; fixed there in v8.3.14 instead
- npm @modelcontextprotocol/server-postgres - deprecated on npm, do not use; plain uvx postgres-mcp - crashes on mcp 2.x import, must pin --with mcp<2; non-ASCII (em-dash) inside .ps1 strings - PS 5.1 parse error
- auto-mode classifier blocks local test scripts that read the DB password from .env (psql/psycopg probes) - rely on claude mcp get status + the in-session MCP tool instead

## Open loops
- Survival test for v8.3.19 + the F9-F14 edits = the next BLC task end-to-end
- Owner deletes temp/template-new and temp/template-old (guard blocks recursive deletes from the agent)
- Confirm whether mockups/main002/index4.html matches what the client last saw - not derivable from the repo (only in baseline commit 863ef05, no call note names it); owner must say
- Sheriff prompt divergence (no severity floor, sentinel No findings.) owed upstream at the next template build
- Context Guard: config.json is the opt-in switch, shared runtime 4.2.4 - POINTER, re-pull before relying on it
- Postgres MCP: ask dev team for a read-only DB role (claude_ro) instead of the app user - SQL in docs/pg-tunnel.md
- /mcpb first live run owed: MCP tools were not loaded in the session that built it (server registered after launch); schema capsule not yet written
- Happy Hour blockers 1-6 listed in .agent/capsules/happy-hour-ab-test.md; #1 (standing first-deposit bonus %) gates the prize design; #3 (prize_cost logging semantics) gates the metric
- Happy Hour: reply to eugene_s owed (logged-in-only OK; tracking additions; prod switch date; day-21 stop)
- /mcpb first live run DONE 2026-09-02; schema capsule .agent/capsules/blc-db-schema.md started (deposits only) - extend on next query
- v8_3_21.zip shipped without a .sha256 companion - owner publishes/compares one (hash in run report); decisions.md 2026-08-30 seed line still names a field project (template aliased it to A) - project-owned, owner decides

## Latest evidence
- _reports/runs/template-upgrade-v8.3.19_2026-09-01.md (gate GREEN on merge commit 27b43e7)

## Next (exactly one action)
- Owner decides Happy Hour prize design given the 20/25% standing bonus: slots 30%+ for all, or Free Ticket/Coins for new clients + Deposit Bonus for returning; then send the reply to eugene_s
