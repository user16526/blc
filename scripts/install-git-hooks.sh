#!/usr/bin/env bash
# Installs the git-side safety hook. Run ONCE per project, after `git init`.
# Usage: ./scripts/install-git-hooks.sh
set -euo pipefail

if [ ! -d .git ]; then
  echo "No .git folder here. Run 'git init' first, then re-run this." >&2
  exit 1
fi

cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "✓ Installed .git/hooks/pre-commit — real .env files and secrets are now"
echo "  blocked even on manual commits."
