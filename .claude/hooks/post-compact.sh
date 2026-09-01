#!/usr/bin/env bash
# Runs after context compaction.
# Outputs SNAPSHOT and recent commits to help the agent restore project context.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

cd "$PROJECT_ROOT" || exit 0

echo "=== POST-COMPACTION CONTEXT RECOVERY ==="
echo ""

# Show SNAPSHOT
SNAPSHOT="$PROJECT_ROOT/.claude/SNAPSHOT.md"
if [[ -f "$SNAPSHOT" ]]; then
  echo "--- SNAPSHOT.md ---"
  cat "$SNAPSHOT"
  echo ""
fi

# Show recent commits
echo "--- Recent commits ---"
git log --oneline -15 2>/dev/null || echo "(no git history)"
echo ""

# Check for dirty state
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [[ "$DIRTY" -gt 0 ]]; then
  echo "WARNING: $DIRTY uncommitted file(s) in working tree."
  git status --short
  echo ""
fi

echo "ACTION REQUIRED: Read CLAUDE.md to fully restore project context before resuming work."
echo "Do not proceed with any task until context is verified."
