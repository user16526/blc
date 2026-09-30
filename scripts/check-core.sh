#!/usr/bin/env bash
# PostToolUse hook: detects edits to the protected CORE block of AGENTS.md (the kernel
# since v8.3.28; CLAUDE.md is the stub that imports it).
# If CORE changed but the baseline wasn't updated, it surfaces a STOP message.
# This is a "needs your OK" gate, not a permanent ban — re-baseline to approve.
set -uo pipefail
f="AGENTS.md"; base=".claude/core.sha"
# A missing kernel is judged like a missing CORE block (sheriff): with a baseline on disk it
# is a removed kernel, not "nothing to check".
core=$( [ -f "$f" ] && awk '/CORE:START/{flag=1} flag{print} /CORE:END/{flag=0}' "$f")
if [ -z "$core" ]; then
  [ -f "$base" ] || exit 0   # no CORE block yet, and none was ever baselined
  # Mid-upgrade (UPGRADE.md s.3b not done yet): the CORE still lives in CLAUDE.md, and
  # AGENTS.md is the old Codex adapter. The gate still BLOCKS that state; the hook only notes it.
  if grep -q 'CORE:START' CLAUDE.md 2>/dev/null; then
    echo "Note: the CORE is still in CLAUDE.md — finish the kernel move (UPGRADE.md s.3b)." >&2; exit 0
  fi
  echo "⚑ STOP: AGENTS.md is missing or has no CORE block, but a CORE baseline exists — the protected kernel was removed. This needs my explicit OK." >&2
  exit 2
fi

now=$(echo "$core" | sha256sum | awk '{print $1}')

if [ ! -f "$base" ]; then
  echo "Note: no CORE baseline yet. If this CORE is correct, run ./scripts/core-baseline.sh." >&2
  exit 0
fi

if [ "$now" != "$(cat "$base")" ]; then
  echo "⚑ STOP: the protected CORE block in AGENTS.md changed. This needs my explicit OK." >&2
  echo "  If the change is intended: state a Kernel Change Rationale, get approval, then run ./scripts/core-baseline.sh." >&2
  echo "  If not intended: revert the CORE edit." >&2
  exit 2
fi
exit 0
