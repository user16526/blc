#!/usr/bin/env bash
# SessionStart hook (zero network). Two jobs:
#  (1) On resume/compact: surface the PreCompact handoff (scripts/precompact-snapshot.sh
#      saved it to disk because PreCompact's own stdout is NOT injected post-compaction;
#      SessionStart's stdout IS — so the re-surfacing happens HERE).
#  (2) Always: remind that current.md / docs hold NOTES about live systems that DECAY,
#      so a stale fact never silently anchors a decision again.
set +e

# SessionStart stdin carries JSON incl. "source" (startup|resume|clear|compact).
payload="$(cat 2>/dev/null || true)"
source="$(printf '%s' "$payload" \
  | grep -oE '"source"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

# (1) Resume/compact handoff.
#     Single-owner rule (v8.2.0): if Context Guard has a fresh ACTIVE task handoff,
#     ITS SessionStart hook (context-guard-restore.py) owns the injection — dumping
#     the disk snapshot here too would double-fill the just-cleaned context. This
#     full dump remains as the FALLBACK safety net when no agent handoff exists
#     (blowup before the checkpoint threshold, or the reminder was ignored).
handoff=".agent/state/handoff.md"
cg_handoff=".claude/handoffs/current.md"
case "$source" in
  compact|resume)
    if [ -f "$cg_handoff" ] && grep -q "Task status: ACTIVE" "$cg_handoff" 2>/dev/null; then
      echo "[resume] Active task handoff: $cg_handoff (Context Guard injects/announces it)."
      [ -f "$handoff" ] && echo "[resume] Disk snapshot also available: $handoff (pointers, not evidence)."
      echo
    elif [ -f "$handoff" ]; then
      echo "[resume] Restoring working state from a compaction/resume handoff:"
      echo "──────── $handoff ────────"
      cat "$handoff"
      echo "──────── end handoff ────────"
      echo "[resume] Live-system facts above are POINTERS — re-pull them live before acting."
      echo
    fi
    ;;
esac

# (2) Freshness reminder (always).
cur=".agent/state/current.md"
upd="$(grep -m1 -E '^Last updated:' "$cur" 2>/dev/null)"
checker="scripts/check_live_state.py"
stub=1
[ -f "$checker" ] && ! grep -q "TODO: implement live checks" "$checker" 2>/dev/null && stub=0
cat <<'EOF'
[state-freshness] current.md / CLAUDE.md hold NOTES about live systems (deployed or
published versions, external APIs, provider/cloud config) that DECAY. A stale note is
a pointer, not evidence. Before concluding or recommending on ANY live-system fact,
re-pull it live first, then trust live over the notes.
Rule: .claude/rules/verify-external-state.md
EOF
if [ "$stub" -eq 1 ]; then
  echo "[state-freshness] note: scripts/check_live_state.py is still the template stub —"
  echo "                  implement it for this project's external systems, or verify by hand."
else
  echo "[state-freshness] live checker ready: run  python scripts/check_live_state.py"
fi
[ -n "$upd" ] && echo "[state-freshness] $upd"

# (3) Model & instruction audit staleness (deterministic, zero network).
#     The audit itself needs network + judgment → that's the `devops` skill;
#     this hook only surfaces the age so the cadence can't be silently missed.
audit=".agent/state/model-audit.md"
max_days=35
cd_line="$(grep -m1 -E '^Cadence days:' "$audit" 2>/dev/null | grep -oE '[0-9]+' | head -1)"
[ -n "$cd_line" ] && max_days="$cd_line"
last="$(grep -m1 -E '^Last audited:' "$audit" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"
if [ -z "$last" ]; then
  echo "⚑ ATTENTION: no model/instruction audit on record — the config was tuned for"
  echo "  whatever model existed when it was written. Run the devops skill"
  echo "  (.claude/skills/devops/ or /devops-audit), then record it in $audit."
else
  now_s="$(date +%s 2>/dev/null)"
  last_s="$(date -d "$last" +%s 2>/dev/null || date -j -f '%Y-%m-%d' "$last" +%s 2>/dev/null || echo '')"
  if [ -n "$now_s" ] && [ -n "$last_s" ]; then
    age=$(( (now_s - last_s) / 86400 ))
    if [ "$age" -ge "$max_days" ]; then
      echo "⚑ ATTENTION: model/instruction audit is ${age} days old (cadence ${max_days}d)."
      echo "  The model lineup and vendor prompting guides may have moved since —"
      echo "  run the devops skill (/devops-audit) before long or expensive work."
    else
      echo "[state-freshness] model/instruction audit: ${age}d ago (cadence ${max_days}d) — OK."
    fi
  fi
fi


# (4) Execution-state staleness (v8.3.16, deterministic, zero network).
#     The state must live DURING work, not appear at the end. If commits exist
#     newer than the last merged patch, the discipline slipped — say so loudly.
sj=".agent/state/current.json"
if [ -f "$sj" ]; then
  lp="$(grep -oE '"last_patch"[[:space:]]*:[[:space:]]*"[^"]*"' "$sj" | head -1 \
        | sed -E 's/.*"([0-9T:-]+)"/\1/')"
  lc="$(git log -1 --format=%cI 2>/dev/null | cut -c1-19)"
  if [ -n "$lp" ] && [ -n "$lc" ] && [ "$(printf '%s' "$lp" | cut -c1-19)" \< "$lc" ]; then
    echo "⚑ state-patch: last merged patch ($lp) is OLDER than HEAD ($lc)."
    echo "  Semantic events since then owe a patch — see skill state-patch."
  else
    echo "[state-freshness] execution state: last patch $lp — current."
  fi
else
  echo "[state-freshness] execution state not started yet (first patch creates it):"
  echo "                  python3 scripts/state-patch.py --patch '{\"set\":{\"goal\":\"...\",\"next\":\"...\"}}'"
fi
exit 0
