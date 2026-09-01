#!/usr/bin/env bash
# PreCompact hook (matcher: auto, async). Fires JUST BEFORE Claude auto-compacts the
# conversation. Claude Code's own PreCompact stdout is NOT injected into the
# post-compaction context, so we PERSIST a handoff to disk here; the SessionStart hook
# (scripts/state-freshness.sh, source=compact|resume) surfaces it back afterwards.
#
# Honest limit: a shell hook can only snapshot what's already on DISK plus the transcript
# path. It cannot extract the in-context design<->code synthesis that lives only in the
# model's head. So this is a safety NET that complements .claude/rules/context-hygiene.md
# ("route durable state to memory FIRST"), not a replacement for it.
set -uo pipefail

# PreCompact stdin carries JSON incl. session_id + transcript_path. Capture best-effort,
# no jq dependency (projects may not have it).
payload="$(cat 2>/dev/null || true)"
transcript="$(printf '%s' "$payload" \
  | grep -oE '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

ts="$(date '+%Y-%m-%d %H:%M:%S')"
out=".agent/state/handoff.md"
mkdir -p .agent/state 2>/dev/null || true

{
  echo "# Compaction handoff — auto-saved $ts"
  echo "<!-- Written by scripts/precompact-snapshot.sh on PreCompact(auto). Overwritten each"
  echo "     auto-compaction. SessionStart (state-freshness.sh) resurfaces this on resume. -->"
  echo "<!-- LIVE-SYSTEM FACTS below are POINTERS, not evidence — re-pull them live before"
  echo "     acting (see .claude/rules/verify-external-state.md). -->"
  echo
  echo "## Git"
  if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "- HEAD $(git rev-parse --short HEAD 2>/dev/null || echo none) on branch $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    dirty="$(git status --porcelain 2>/dev/null)"
    if [ -n "$dirty" ]; then
      echo "- Working tree DIRTY:"
      printf '%s\n' "$dirty" | sed 's/^/    /'
    else
      echo "- Working tree clean"
    fi
  else
    echo "- (no git repo)"
  fi
  echo
  echo "## Full uncompressed transcript"
  [ -n "$transcript" ] && echo "- $transcript" || echo "- (transcript_path not provided in payload)"
  echo
  echo "## .agent/state/current.md (snapshot)"
  [ -f .agent/state/current.md ] && sed 's/^/    /' .agent/state/current.md || echo "    (none yet)"
  echo
  echo "## .agent/state/open-loops.md (snapshot)"
  [ -f .agent/state/open-loops.md ] && sed 's/^/    /' .agent/state/open-loops.md || echo "    (none yet)"
  echo
  echo "## .claude/handoffs/current.md (Context Guard task handoff, snapshot)"
  if [ -f .claude/handoffs/current.md ]; then
    sed 's/^/    /' .claude/handoffs/current.md
  else
    echo "    (none — no agent-written task handoff at compaction time)"
  fi
  echo
  echo "## Resume pointers"
  echo "- Machine run state: _reports/runs/latest.json"
  echo "- Decisions: .agent/state/decisions.md   |   Risks: .agent/state/risks.md"
  echo "- Active lessons: tasks/lessons.md"
  echo "- Protocol: CLAUDE.md > MEMORY — read current.md + latest.json + the active spec,"
  echo "  pick up from the last completed phase. The artifacts are the checkpoint."
} > "$out" 2>/dev/null || true

# This line lands only in the live transcript (PreCompact stdout is not re-injected).
echo "[precompact] working state saved -> $out (surfaced next session by state-freshness.sh)"
exit 0
