# Current State
<!-- RENDERED VIEW. Authoritative state: current.json, merged only via
     scripts/state-patch.py (LLM proposes, script merges). Hand-edits here
     are lost on the next render — patch instead. -->

Last updated: 2026-09-08 16:34

## Goal
- Happy Hour A/B (BloodyCase): SIMPLE FINAL 2026-09-08 - ONE 21-day run, one window 17-22 UTC, 3 arms control/bonus-50%/free-case (docs/happy-hour-simple-final_2026-09-08_v1.md); awaiting owner sign-off

## Constraints
- SCOPE LIMIT: product/marketing/UI-UX only - never edit BloodyCase application code
- Upgrades are HIGH-row: checkpoint branch first, rollback = git checkout main

## Verified (evidence, not memory)
- template_version: v8.3.21 (merge route 2026-09-02, gate GREEN; run report _reports/runs/template-upgrade-v8.3.21_2026-09-02.md)
- core_sha: unchanged ec9f3774 across v8.3.19->v8.3.21 - no kernel change, no re-baseline
- test_hooks: 146/0 GREEN on the v8.3.21 tree [2026-09-02]
- state_patch_self_test: GREEN under default console, utf-8 and cp1252 - D3 closed on this tree
- sheriff_probe: OK - automation available (toggle off)
- release_zip_sha256: v8_3_21.zip sha256 c93041a8... - companion v8_3_21.sha256 generated LOCALLY 2026-09-02 (tamper-evidence, not canonical provenance)
- devops_audit: 2026-09-01 vs Fable 5.1 guide - RESOLVED: F9-F14 applied (owner), suite 146/0; sheriff prompt is now a BLC-local canonical divergence (decisions.md)
- template_newest_release: v8.3.21 (2026-09-02) - docs/comment-only gap from v8.3.19; TAKEN, TEMPLATE_VERSION = v8.3.21
- pg_tunnel_scripts: scripts/pg-tunnel.ps1 + pg-mcp-register.ps1 + Read-DotEnv.ps1 parse clean (PS 5.1), fail loudly without .env keys; claude mcp add/remove dry-run OK with dummy URI; uvx --with mcp<2 postgres-mcp --help exit 0 [2026-09-01]
- pg_tunnel_e2e: ssh key auth sparrow@168.119.74.101 OK; host bloodyanalytics02 runs Postgres 18 on 5432, db bloody; tunnel up -> localhost:5432 TcpTestSucceeded; claude mcp get postgres = Connected (restricted mode) [2026-09-02 via scripts/pg-tunnel.ps1 + pg-mcp-register.ps1]
- mcpb_command: .claude/commands/mcpb.md registered as /mcpb; scripts/pg-tunnel-ensure.ps1 starts the tunnel in a minimized window when 5432 is closed and reports UP when it is [2026-09-02]
- happy_hour_restore: remote memory happy_hour_ab_test.md (last real work 2026-08-27) + docs/features/happy-hour-backend.md pulled read-only from sparrow@168.119.74.101; host sessions 2026-08-31 and 2026-09-01 were restores only, no new decisions [2026-09-02]
- happy_hour_dev_status: eugene_s 2026-09-01: A/B split implemented for logged-in users only (33.3/33.3/33.3, control/02UTC/18UTC), UAT only; events gate_shown/shown/spun; guests excluded; blocker #6 closed [source: owner-pasted dev comment 2026-09-02]
- happy_hour_blocker1: standing 1st-deposit bonus 20%/25% (>=~$20), 2+ deposits 6-10%; from live public.deposits 90d, report _reports/blc-data_2026-09-02_0030_v1.md [2026-09-02]
- happy_hour_blocker3: backend doc: client_happy_hours.prize_won stores nominal roll only (type/weight/amount/case_id), no prize-cost column; applied % lives only in deposits.bonus_amount [2026-09-02, docs/happy-hour-backend_remote-copy_2026-09-02_v1.md]
- happy_hour_power: 3wk x 1/3 split: MDE net revenue ~130% raw / ~45% capped (unusable); depositor rate MDE ~19% rel (5.0% baseline), 6wk ~13%; from live DB 2026-09-02, _reports/blc-data_2026-09-02_1830_v1.md
- happy_hour_reach: 21d reach of a HH window (public.client_login_records, live 2026-09-08): 02-05 UTC = 7.0% of 26551 logged-in clients, 18-21 UTC = 20.3%, 17-22 UTC = 32.1%, 16-23 UTC = 42.6%; depositors 12.9%/30.0% reachable. Report _reports/blc-data_2026-09-08_reach_v1.md
- happy_hour_mde_exposed: Exposed-subset primary analysis at 17-22 UTC: n=2843/arm, base depositor rate 6.62%, MDE 1.85pp = 27.9% rel (30.7% with multiplicity); arm-level ITT at the same window needs +42% among exposed [2026-09-08]
- happy_hour_morning_dead: The 02-05 UTC arm needs ~+79 net-new depositors in an arm whose window yields ~37 depositors of any kind per 21 days - arithmetically untestable, dropped

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
- Happy Hour 2026-09-08: ONE run, prize test with the WINDOW HELD CONSTANT (17-22 UTC, duration 300) - replaces the 2026-09-02 two-run plan; the timing run is dropped, not deferred
- Happy Hour prize arms: a single Deposit Bonus 50% slot (not 30/40/50) vs one free case $5-10 - cost parity, banner-legible, no 30% roll reading as a loss under winner-take-max
- Happy Hour primary metric: depositor rate on the IN-WINDOW EXPOSED subset in all 3 arms (requires gate_shown for control); arm-level ITT reported alongside as the shipping number

## Failed / rejected (do NOT retry)
- Local one-line pre-commit exclusion for test-hooks.sh - superseded by the shipped, suite-asserted v8.3.14 fix; do not reintroduce
- Reporting D1/D2 upstream from inside BLC - releases are build products of the maintainer canonical tree; fixed there in v8.3.14 instead
- npm @modelcontextprotocol/server-postgres - deprecated on npm, do not use; plain uvx postgres-mcp - crashes on mcp 2.x import, must pin --with mcp<2; non-ASCII (em-dash) inside .ps1 strings - PS 5.1 parse error
- auto-mode classifier blocks local test scripts that read the DB password from .env (psql/psycopg probes) - rely on claude mcp get status + the in-session MCP tool instead
- Happy Hour: different prize per WINDOW without a swap (owner's first framing) - window and prize fully confounded, nothing attributable; and a Deposit Bonus pool of 5-25% - no-op vs the standing 20/25% first-deposit bonus
- Happy Hour mixed-pool fallback (one planner, bonus+case slots in one pool): the prize is rolled AFTER the qualifying deposit so it cannot explain it, and one client can draw both prizes - a stop-and-replan, not a workaround
- Happy Hour separate timing run (02-05 vs 18-21): the morning arm cannot clear its MDE at any plausible prize strength

## Open loops
- Survival test for v8.3.19 + the F9-F14 edits = the next BLC task end-to-end
- Confirm whether mockups/main002/index4.html matches what the client last saw - not derivable from the repo (only in baseline commit 863ef05, no call note names it); owner must say
- Sheriff prompt divergence (no severity floor, sentinel No findings.) owed upstream at the next template build
- Context Guard: config.json is the opt-in switch, shared runtime 4.2.4 - POINTER, re-pull before relying on it
- Postgres MCP: ask dev team for a read-only DB role (claude_ro) instead of the app user - SQL in docs/pg-tunnel.md
- /mcpb first live run owed: MCP tools were not loaded in the session that built it (server registered after launch); schema capsule not yet written
- Happy Hour blockers 1-6 listed in .agent/capsules/happy-hour-ab-test.md; #1 (standing first-deposit bonus %) gates the prize design; #3 (prize_cost logging semantics) gates the metric
- Happy Hour: reply to eugene_s owed (logged-in-only OK; tracking additions; prod switch date; day-21 stop)
- /mcpb first live run DONE 2026-09-02; schema capsule .agent/capsules/blc-db-schema.md started (deposits only) - extend on next query
- Happy Hour reply to eugene_s DRAFTED 2026-09-02 (docs/happy-hour-reply-eugene_2026-09-02_v1.md, Ukrainian, under option C); waiting on owner D1-D4
- Happy Hour design options + sheriff pass (5 findings, all fixed) in _reports/happy-hour-test-design-options_2026-09-02_v1.md [2026-09-02]; MDE on client-level data (P1) owed via /mcpb before start
- Happy Hour P1 (MDE) DONE 2026-09-02: primary metric must be depositor rate, not revenue; Free Ticket cost not in replica -> ask eugene_s
- Happy Hour FINAL written 2026-09-02 (docs/happy-hour-final_2026-09-02_v1.md: UA recommendation + RU TZ v2 + RU reply); uncommitted, owner to send
- Happy Hour GO/NO-GO for eugene_s: is a real free case (PromoCode) available as a planner prize, or only FreeTicket? If not, G2 does not assemble and the plan needs rework
- Happy Hour dev asks: group -> planner routing at one cron; gate_shown must fire for the CONTROL arm on the same in-window trigger (hard blocker); group/experiment_id persisted OR the deterministic hash mapping handed over
- Happy Hour: HH is a reward-the-present tool, not re-engagement (in-window modal only, ceiling 32%) - an announcement channel (push/email/banner) is a separate ticket

## Latest evidence
- Happy Hour simple final docs/happy-hour-simple-final_2026-09-08_v1.md + _reports/blc-data_2026-09-08_reach_v1.md; reviewed independently by the CS2-CMO agent, a data-analyst agent and SHERIFF (codex, cross-vendor) - 5 sheriff findings, all closed in the doc [2026-09-08]

## Next (exactly one action)
- Owner signs off the simple final, then sends section D (dev asks) to eugene_s; run starts no earlier than 2026-09-10
