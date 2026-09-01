#!/usr/bin/env bash
# Runs after every tool call.
# Increments a counter and reminds the agent to commit at every 20-call boundary.
# Overhead target: < 10ms for non-checkpoint calls.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

COUNTER_FILE="$PROJECT_ROOT/.claude/.tool-counter"

# Read and increment counter
COUNT=0
if [[ -f "$COUNTER_FILE" ]]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Only act on checkpoint intervals
INTERVAL=20
if (( COUNT % INTERVAL != 0 )); then
  exit 0
fi

# Checkpoint reached
DIRTY=$(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [[ "$DIRTY" -gt 0 ]]; then
  echo "⚡ CHECKPOINT ($COUNT tool calls): $DIRTY uncommitted file(s)."
  echo "   → Commit changes and update .claude/SNAPSHOT.md before continuing."
fi
