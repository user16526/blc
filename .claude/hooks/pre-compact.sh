#!/usr/bin/env bash
# Runs before context compaction.
# Commits tracked file changes and updates SNAPSHOT timestamp.
# Does NOT update substantive SNAPSHOT sections — that is the agent's responsibility.
# Does NOT auto-stage untracked files — blind git add . could capture secrets or build artifacts.

# Intentionally no set -e: allow execution to complete despite errors.

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

cd "$PROJECT_ROOT" || exit 0

# Check framework-state mode safety
MANIFEST="$PROJECT_ROOT/manifest.md"
REPO_ACCESS="private-solo"
if [[ -f "$MANIFEST" ]]; then
  REPO_ACCESS=$(grep '^repo_access=' "$MANIFEST" | cut -d= -f2 | tr -d '[:space:]')
fi

# In public/private-shared mode, framework files must already be untracked
if [[ "$REPO_ACCESS" == "public" || "$REPO_ACCESS" == "private-shared" ]]; then
  # Check if any framework files are still tracked
  TRACKED_FRAMEWORK=$(git ls-files .claude/ 2>/dev/null | grep -v '^$' | wc -l)
  if [[ "$TRACKED_FRAMEWORK" -gt 0 ]]; then
    echo "WARNING: Framework files are tracked in $REPO_ACCESS mode. Run scripts/switch-repo-access.sh first."
  fi
fi

# Commit already-tracked changes
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
MODIFIED=$(git diff --name-only 2>/dev/null | wc -l)

if [[ "$MODIFIED" -gt 0 || "$STAGED" -gt 0 ]]; then
  git add -u
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
  git commit -m "auto: pre-compaction checkpoint $TIMESTAMP" --quiet 2>/dev/null || true
fi

# Update SNAPSHOT timestamp
SNAPSHOT="$PROJECT_ROOT/.claude/SNAPSHOT.md"
if [[ -f "$SNAPSHOT" ]]; then
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^\*\*Last updated:\*\*.*/\*\*Last updated:\*\* $TIMESTAMP/" "$SNAPSHOT"
  else
    sed -i "s/^\*\*Last updated:\*\*.*/\*\*Last updated:\*\* $TIMESTAMP/" "$SNAPSHOT"
  fi

  # Commit SNAPSHOT in private-solo mode
  if [[ "$REPO_ACCESS" == "private-solo" ]]; then
    git add "$SNAPSHOT" 2>/dev/null
    git commit -m "auto: snapshot timestamp $TIMESTAMP" --quiet 2>/dev/null || true
  fi
fi
