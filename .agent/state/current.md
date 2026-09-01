# Current State
<!-- RENDERED VIEW. Authoritative state: current.json, merged only via
     scripts/state-patch.py (LLM proposes, script merges). Hand-edits here
     are lost on the next render — patch instead. -->

Last updated: 2026-09-01 20:26

## Goal
- BLC framework is on template v8.3.16; no product task active

## Constraints
- SCOPE LIMIT: product/marketing/UI-UX only - never edit BloodyCase application code
- Upgrades are HIGH-row: checkpoint branch first, rollback = git checkout main

## Verified (evidence, not memory)
- template_version: v8.3.16
- core_sha: unchanged ec9f3774 - no kernel change, no re-baseline
- test_hooks: 146/0 GREEN
- state_patch_self_test: 9/9 GREEN (needs PYTHONIOENCODING=utf-8 on Windows)
- sheriff_probe: OK - automation available (toggle off)
- release_zip_sha256: b967869d... matches shipped .sha256

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

## Failed / rejected (do NOT retry)
- Local one-line pre-commit exclusion for test-hooks.sh - superseded by the shipped, suite-asserted v8.3.14 fix; do not reintroduce
- Reporting D1/D2 upstream from inside BLC - releases are build products of the maintainer canonical tree; fixed there in v8.3.14 instead

## Open loops
- Whether mockups/main002/index4.html matches what the client last saw is unrecorded - confirm before iterating
- Context Guard: config.json is the opt-in switch (schema 1, min_runtime 4.2.0), shared runtime 4.2.4 - POINTER, re-verify before relying on it
- D3 owed upstream: state-patch.py --self-test crashes on a default Windows cp1252 console (UnicodeEncodeError on the check-mark)

## Latest evidence
- _reports/runs/template-upgrade-v8.3.16_2026-09-01.md (gate GREEN on merge commit 659e4fe)

## Next (exactly one action)
- Start the next BLC product/UX task, or run the overdue devops audit
