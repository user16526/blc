# Current State
<!-- RENDERED VIEW. Authoritative state: current.json, merged only via
     scripts/state-patch.py (LLM proposes, script merges). Hand-edits here
     are lost on the next render — patch instead. -->

Last updated: 2026-09-01 23:20

## Goal
- BLC framework is on template v8.3.19; no product task active - owner is about to give a BLC-oriented task

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
- devops_audit: 2026-09-01 vs Fable 5.1 guide - YELLOW, F9-F14 proposed, none CORE; harness 146/0, gate GREEN at 3a84df6
- template_newest_release: v8.3.19 (2026-09-01) - not security-relevant; TEMPLATE_VERSION still v8.3.16

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

## Open loops
- Resolve audit findings F9-F14: owner apply/veto per line (docs/model-audit-recommendations_2026-09-01_2301_v1.md)
- Survival test for v8.3.19 = the next BLC task end-to-end (not waived: executable bytes changed)
- Owner deletes temp/template-new and temp/template-old (guard blocks recursive deletes from the agent)
- Confirm whether mockups/main002/index4.html matches what the client last saw before iterating
- Context Guard: config.json is the opt-in switch, shared runtime 4.2.4 - POINTER, re-pull before relying on it

## Latest evidence
- _reports/runs/template-upgrade-v8.3.19_2026-09-01.md (gate GREEN on merge commit 27b43e7)

## Next (exactly one action)
- Take the BLC-oriented task the owner gives next; it doubles as the v8.3.19 survival test
