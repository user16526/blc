#!/usr/bin/env bash
# Installs the git-side safety hook. Run ONCE per project, after `git init`.
# Usage: ./scripts/install-git-hooks.sh
#
# Asks git where hooks live instead of assuming `.git/hooks` (v8.3.25). The old
# `cp … .git/hooks/pre-commit` went wrong two ways, both silently:
#   - `core.hooksPath` set (a project that keeps its own hooks in a tracked folder):
#     git runs hooks from THAT folder only, so the file written into .git/hooks never
#     executed and the .env/secret blocker was off with no error anywhere. Refused
#     below — this script will not write a hook git is not going to run, and will not
#     overwrite a project's own tracked hooks either. The message says how to chain it.
#     `core.hooksPath` is per-clone config: a fresh clone has it unset until someone
#     sets it again, so re-run this script after cloning such a project.
#   - a worktree, where `.git` is a FILE: the old `[ -d .git ]` refused to run at all.
set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repository. Run 'git init' first, then re-run this." >&2
  exit 1
fi

hp="$(git config --get core.hooksPath || true)"
if [ -n "$hp" ]; then
  echo "REFUSED: core.hooksPath=$hp — git runs hooks from there only, so a hook written" >&2
  echo "  to the default folder would never execute (the .env/secret blocker would be" >&2
  echo "  silently OFF). Either chain it from your own hook — add to $hp/pre-commit:" >&2
  echo "      bash scripts/pre-commit || exit 1" >&2
  echo "  — or unset core.hooksPath and re-run this script." >&2
  exit 1
fi

dir="$(git rev-parse --git-path hooks)"
mkdir -p "$dir"
# A pre-commit that is not ours (husky, the pre-commit framework, a hand-written one) is
# never overwritten: that would silently switch it off. Our own older copy is replaced.
if [ -f "$dir/pre-commit" ] && ! cmp -s scripts/pre-commit "$dir/pre-commit" \
   && ! grep -q 'last line of defense' "$dir/pre-commit"; then
  echo "REFUSED: $dir/pre-commit already exists and is not this template's hook —" >&2
  echo "  overwriting it would switch it off. Chain ours from it instead:" >&2
  echo "      bash scripts/pre-commit || exit 1" >&2
  exit 1
fi
cp scripts/pre-commit "$dir/pre-commit"
chmod +x "$dir/pre-commit"
echo "✓ Installed $dir/pre-commit — real .env files and secrets are now"
echo "  blocked even on manual commits."
