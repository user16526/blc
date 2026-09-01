# Session cost analysis — where the tokens go (BLC, 2026-09-02)

Tool: `scripts/session-cost.py` (reads `~/.claude/projects/D--claude-blc/*.jsonl`, dedupes
per message id, prices with the calibrated rate table). Estimates land within ~6–9 % of the
totals Claude Code records itself (`cost-state`).

## Three sessions measured
| session | model | turns | API calls | calls/turn | max context | est. $ | recorded $ |
|---|---|---|---|---|---|---|---|
| 70497047 (this one, open) | Fable 5.1 | 7 | 63 | 9 | 208k | 8.5 | — |
| 5b55de2d (2026-09-01 eve) | Fable 5.1 | 10 | 43 | 4 | 202k | 7.5 | 7.94 |
| d605c7cf (2026-09-01 day) | Opus 5 | 11 | 193 | 18 | 192k | 17.4 | 19.10 |

Cost split (this session): cache WRITE 41 %, output 36 %, cache READ 22 %, uncached input 1 %.
Cache writes are billed at 2× input because Claude Code uses the 1-hour cache TTL.

## Findings, ranked by dollars
1. **One giant Read = the dark hole.** In d605 a single `Read` put ~92k tokens into context at
   13:24; it then rode along in ~150 later calls → ≈ $7 of cache reads from one tool call
   (65 % of that session was cache READ). Same mechanism, smaller: the `claude-api` skill load in
   this session (21k tokens, ≈ $0.45 to write + re-read on every call after it).
2. **Calls per turn.** Every tool call is a full API call that re-reads the whole context
   (~120k tokens avg here). 9–27 calls/turn × 200k context is the multiplier on everything else.
3. **Context size 200k+ in all three sessions.** Context Guard's 1M profile only whispers at
   200k and compacts at 450k. At $0.25/M (Fable) or $0.50/M (Opus 5) per re-read, a 200k
   context costs $0.05–0.10 per call before any work is done.
4. **Static config is NOT the hole.** CLAUDE.md + workspace CLAUDE.md + 12 always-on rules ≈
   42k chars ≈ 10–11k tokens; 56 skill/command descriptions ≈ 3k tokens; agents ≈ 1.5k tokens.
   First-request context ≈ 34k tokens total, cached → ≈ $0.55 per session at 63 calls (6 %).
   Halving it saves ~$0.30/session. Not worth a kernel change.
5. **Auto-mode classifier / titles (Haiku): ≈ $0.05 per session.** Negligible.
6. **Model tier is a 2× lever.** Fable 5.1 is $10/$50 vs Opus 5 $5/$25 (and cache read
   $0.25 vs $0.50 — the only place Fable is cheaper). Tunnel scripts, MCP wiring, restores are
   Opus/Sonnet-grade chores.

## What to change
- **Never Read/Skill a >10k-token thing into the main context.** grep/head the part needed,
  or hand it to a subagent (its context dies with it). Rule added to `tasks/lessons.md`.
- **Lower the Context Guard 1M ladder** so the handoff/compaction happens around 120k–160k
  instead of 300k–450k: `.claude/context-guard/config.json` → `"1m": {soft 120000,
  checkpoint 150000, high 180000}` and `auto_compact_window` ≈ 200000 (must match
  `CLAUDE_CODE_AUTO_COMPACT_WINDOW` in `.claude/settings.json`, checked by the test suite).
  The context-hygiene rule already says clear at phase boundaries — the ladder should agree.
- **Batch tool calls** (one script instead of five probes) — the biggest per-turn lever.
- **Pick the model per task**: Fable for product/strategy thinking, Opus 5 or Sonnet 5 for
  devops chores and restores (`/model`).
- **Measure, don't guess:** `python scripts/session-cost.py -n 5` after any expensive day.

## Not changed (deliberately)
- CLAUDE.md / rules size: measured at ~6 % of spend; a kernel edit needs owner OK and buys little.
- The 1-hour cache TTL is a harness setting, not ours.
