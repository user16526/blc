# Current State
<!-- RENDERED VIEW. Authoritative state: current.json, merged only via
     scripts/state-patch.py (LLM proposes, script merges). Hand-edits here
     are lost on the next render — patch instead. -->

Last updated: 2026-09-02 00:36

## Goal
- Remote BloodyCase Postgres reachable read-only from Claude Code via SSH tunnel + Postgres MCP (restricted) - DONE, in daily use

## Constraints
- SCOPE LIMIT: product/marketing/UI-UX only - never edit BloodyCase application code
- Upgrades are HIGH-row: checkpoint branch first, rollback = git checkout main

## Verified (evidence, not memory)
- template_version: v8.3.19 (merge commit 27b43e7, gate GREEN)
- core_sha: unchanged ec9f3774 - no kernel change, no re-baseline
- test_hooks: 146/0 GREEN
- state_patch_self_test: GREEN under default console, utf-8 and cp1252 - D3 closed on this tree
- sheriff_probe: OK - automation available (toggle off)
- release_zip_sha256: de4e823e... matches shipped release/v8_3_19.sha256
- devops_audit: 2026-09-01 vs Fable 5.1 guide - RESOLVED: F9-F14 applied (owner), suite 146/0; sheriff prompt is now a BLC-local canonical divergence (decisions.md)
- template_newest_release: v8.3.19 (2026-09-01) - not security-relevant; TEMPLATE_VERSION still v8.3.16
- pg_tunnel_scripts: scripts/pg-tunnel.ps1 + pg-mcp-register.ps1 + Read-DotEnv.ps1 parse clean (PS 5.1), fail loudly without .env keys; claude mcp add/remove dry-run OK with dummy URI; uvx --with mcp<2 postgres-mcp --help exit 0 [2026-09-01]
- pg_tunnel_e2e: ssh key auth sparrow@168.119.74.101 OK; host bloodyanalytics02 runs Postgres 18 on 5432, db bloody; tunnel up -> localhost:5432 TcpTestSucceeded; claude mcp get postgres = Connected (restricted mode) [2026-09-02 via scripts/pg-tunnel.ps1 + pg-mcp-register.ps1]
- mcpb_command: .claude/commands/mcpb.md registered as /mcpb; scripts/pg-tunnel-ensure.ps1 starts the tunnel in a minimized window when 5432 is closed and reports UP when it is [2026-09-02]

## Working set
- Framework only. No product task active - next real BLC task starts fresh under the v8.3.16 kernel.
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

## Latest evidence
- _reports/runs/template-upgrade-v8.3.19_2026-09-01.md (gate GREEN on merge commit 27b43e7)

## Next (exactly one action)
- Owner: restart Claude Code (or /mcp -> reconnect postgres), then run /mcpb schema to build .agent/capsules/blc-db-schema.md
