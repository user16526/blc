---
name: checkpoint
description: Create a safe restore point before any large or risky change (refactor, migration, bulk edit, dependency bump, infra/VPS change), and know how to roll back.
---

# Checkpoint (anti-overwrite safety)

Run this BEFORE a big change so nothing valuable can be lost.

## Before
1. `git status` — inspect FIRST. Classify every dirty file: **this task's scope**
   vs **someone else's / unrelated** (the human's WIP, another agent, debug files).
2. **HARD RULE: stage only this task's files** — `git add <paths>`, then
   `git commit -m "checkpoint: before <change>"`. `git add -A` is allowed ONLY if
   the tree was clean before this task started. Unrelated dirty files: list them
   to me in one line, do NOT stage them, do NOT stash them (stashing someone
   else's work is a work-erasing action — SAFETY applies). Never stage a real `.env`.
3. Work on a branch, not `main`:
   `git switch -c <feature-branch>`
4. For data/schema/infra: take a real backup (DB dump, config copy, snapshot)
   and write down WHERE it is.
5. Write the rollback line and show it to me before proceeding, e.g.:
   - code: `git reset --hard <checkpoint-hash>` (only with my approval)
   - branch: `git switch main` (discard the branch)
   - data: the restore command for the backup from step 4.

## After
6. Verify the change (tests / build / health check) — show evidence.
7. Only then merge: `git switch main && git merge <feature-branch>`.
8. For meaningful releases, tag it: `git tag -a v<x.y.z> -m "<what>"`.

If anything goes wrong mid-change: STOP, do not push further, restore from the
checkpoint, and report state. Reversible-but-slow beats fast-but-irreversible.
