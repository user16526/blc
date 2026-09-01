---
name: memory-router
description: Decide WHERE a new piece of information belongs before persisting it. Use whenever you're about to "remember", record, or write down something — so CLAUDE.md stays a kernel, not a junk drawer.
---

# Memory Router

Before writing anything down, classify it. CLAUDE.md is the kernel — it almost never
grows. Route by this table:

| The info is… | Goes to | Mode |
|---|---|---|
| A permanent operating/safety rule or command | CLAUDE.md (CORE) — **needs my OK + re-baseline** | rare |
| Current project state ("what's true now") | `.agent/state/current.md` | overwrite, keep ≤250 lines |
| An important decision + why | `.agent/state/decisions.md` | append-only |
| An active risk | `.agent/state/risks.md` | update; close when resolved |
| An unresolved task / pending approval | `.agent/state/open-loops.md` | update |
| A lesson from a mistake | `tasks/lessons.md` | append, tag [active] |
| Durable domain knowledge | `.agent/capsules/<domain>.md` | create/update the capsule |
| Evidence from a run | `_reports/runs/<dated>.md` + `latest.json` | per run |
| In-flight task state (mid-task handoff) | `.claude/handoffs/current.md` via the `handoff` skill | overwrite; local, gitignored, ephemeral |
| Throwaway scratch | `temp/` | not committed |

## Rules
- Default assumption: it does NOT belong in CLAUDE.md. Prove it's a permanent kernel
  rule before touching CORE — otherwise route it elsewhere.
- A "capsule" is created only when a domain actually has durable facts (don't
  pre-create empty ones). Format = see `.agent/capsules/_TEMPLATE.md`.
- `current.md` is mutable and compact; `decisions.md`, `risks` history, and
  `lessons.md` grow by appending — never rewrite history there.
- When in doubt between current vs decision: state → current.md; "we chose X over
  Y because Z" → decisions.md.
- The task handoff is EPHEMERAL and gitignored — never the only home of anything
  durable. Decisions/lessons discovered mid-task get routed to their buckets above
  even while the handoff also mentions them.

## When asked to "remember X"
Say which bucket it goes to, write it there, and confirm in one line. Do NOT silently
expand CLAUDE.md.
