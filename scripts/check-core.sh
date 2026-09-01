#!/usr/bin/env bash
# PostToolUse hook: detects edits to the protected CORE block of CLAUDE.md.
# If CORE changed but the baseline wasn't updated, it surfaces a STOP message.
# This is a "needs your OK" gate, not a permanent ban — re-baseline to approve.
set -uo pipefail
f="CLAUDE.md"; base=".claude/core.sha"
[ -f "$f" ] || exit 0

core=$(awk '/CORE:START/{flag=1} flag{print} /CORE:END/{flag=0}' "$f")
[ -z "$core" ] && exit 0   # no CORE block yet

now=$(echo "$core" | sha256sum | awk '{print $1}')

if [ ! -f "$base" ]; then
  echo "Note: no CORE baseline yet. If this CORE is correct, run ./scripts/core-baseline.sh." >&2
  exit 0
fi

if [ "$now" != "$(cat "$base")" ]; then
  echo "⚑ STOP: the protected CORE block in CLAUDE.md changed. This needs my explicit OK." >&2
  echo "  If the change is intended: state a Kernel Change Rationale, get approval, then run ./scripts/core-baseline.sh." >&2
  echo "  If not intended: revert the CORE edit." >&2
  exit 2
fi
exit 0
