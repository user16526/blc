#!/usr/bin/env bash
# Runs after every subagent completes.
# REMINDER only — does not commit automatically. The manager must execute the cycle.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

DIRTY=$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [[ "$DIRTY" -gt 0 ]]; then
  echo "🔔 Subagent finished. $DIRTY uncommitted file(s) detected."
  echo "   Required cycle (see delegation.md):"
  echo "   1. Evaluate subagent result"
  echo "   2. git add <files> && git commit"
  echo "   3. Update .claude/SNAPSHOT.md"
  echo "   4. Integrate into context"
fi
