# AGENTS.md — Codex Adapter

This repository's single source of truth is **`CLAUDE.md`**. This file only adapts
it for Codex (or any agent that isn't Claude Code). Do not duplicate rules here.

Before doing any work:
1. Read `CLAUDE.md` (the full project contract) and `tasks/lessons.md`.
   Also read `.agent/state/current.md` (what's true now) and
   `_reports/runs/latest.json` (current run state). The CORE block in CLAUDE.md is
   protected — never edit it without the human's explicit OK.
2. For non-trivial work, read the relevant procedure in `.claude/skills/`
   (`scope-and-spec`, `pipeline`, `orchestration`, `checkpoint`, `deploy`, `devops`).
   A SessionStart hook (`state-freshness.sh`) IS registered in `.codex/hooks.json`;
   if it did not visibly fire (untrusted project / hooks disabled), do its job
   yourself: check `.agent/state/model-audit.md` — `Last audited:` older than
   `Cadence days:` → propose the `devops` audit before long or expensive work.
3. Treat files in `.claude/agents/` as role definitions. Current Codex supports
   native subagent workflows — use them; role files map to custom agents. Only if
   subagents are genuinely unavailable, fall back to sequential passes (BA/spec →
   plan → build → independent review(s) → verifier), with the honest caveat that
   sequential passes on one model in one session are closer to one careful opinion
   than several — for high-stakes/irreversible work, the human is the real
   independent check.
4. Agent count and reviewer selection come from the RISK MATRIX row in `CLAUDE.md`
   (details: `.claude/skills/orchestration/SKILL.md`).
5. **"Done" requires evidence AND a passing gate.** Run `./scripts/quality-gate.sh`
   (or `--trivial`) and only report done on GREEN. Non-trivial flow: write
   `_reports/runs/<dated>.md`, **commit code + report**, THEN write
   `_reports/runs/latest.json` (gitignored, `head_sha` = current HEAD), then gate.
   The gate BLOCKS on a dirty tree (sole exemption: latest.json) — unverified
   changes after the proof invalidate the proof.
6. Respect the RISK MATRIX & AUTOMODE in `CLAUDE.md`: HIGH needs the human's plan
   approval; DESTRUCTIVE/MONEY/PROD/SECRETS always needs explicit approval and
   automode never shifts it. Never deploy, delete data, run destructive commands,
   or touch real secrets without explicit approval.
7. **Hooks on Codex: registered, but trust-gated — verify, don't assume.** Codex
   loads project-local lifecycle hooks from `.codex/hooks.json` (top-level `hooks`
   key; same event names + stdin JSON as Claude Code) only for TRUSTED projects,
   and every command hook must be reviewed & trusted by hash — new or changed
   hooks are skipped until trusted. Some builds also require
   `[features] codex_hooks = true` in `.codex/config.toml`, and on several Codex
   versions PreToolUse/PostToolUse fire for **Bash only** (Write/Edit matchers
   never run). So: at session start verify hooks actually fire; where they don't,
   you are responsible for the same rules manually. The guaranteed, agent-agnostic
   enforcement is the git `pre-commit` hook (`scripts/install-git-hooks.sh`).
   Script logic is proven by `bash scripts/test-hooks.sh`.
8. **Compaction on Codex is covered natively.** Codex fires `PreCompact` before
   compaction and `SessionStart` with `source="compact"` after it — the same chain
   as Claude Code: `precompact-snapshot.sh` persists working state to
   `.agent/state/handoff.md`, `state-freshness.sh` resurfaces it. Both are
   registered in `.codex/hooks.json`. Fallback ONLY if hooks are not trusted/firing:
   before you summarize or restart a long session, run
   `bash scripts/precompact-snapshot.sh` yourself and read `handoff.md` back when
   you resume. If `.claude/handoffs/current.md` exists with `Task status: ACTIVE`,
   read it too — it is the richest in-flight task state (written by Claude Code's
   Context Guard; the snapshot embeds a copy of it as well).

## SHERIFF mode (Codex as external reviewer)
When invoked as SHERIFF (cross-review skill), read ONLY the review prompt and
the diff — skip `CLAUDE.md`, skills, and state files. Reviewer independence
requires less context, not more. When Codex is the AUTHOR of a task, cross-review
still applies with roles swapped: the sheriff must be a different-vendor model.
