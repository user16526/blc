#!/usr/bin/env bash
# One-time setup. Run this FIRST, right after extracting the template:
#     bash setup.sh
# (invoke via `bash` so it works even before exec bits are set).
#
# Why this exists: the template ships from a filesystem that does not carry the
# Unix execute bit, so the hooks in .claude/settings.json (guard.sh,
# state-freshness.sh, check-*.sh) and the quality gate would silently fail to run
# until the scripts are made executable. This fixes that, and installs the git
# pre-commit hook if a repo already exists.
set -euo pipefail

echo "── template setup ──"

# 1) Make every shipped script executable (the core fix).
chmod +x setup.sh 2>/dev/null || true
chmod +x scripts/*.sh scripts/integration/*.sh scripts/pre-commit 2>/dev/null || true
# context-guard/ is the Context Guard RELEASE SOURCE, not project payload:
# it is what scripts/install-context-guard.py copies to ~/.claude/context-guard/.
# It is absent from the project template artifact, so this chmod is a no-op there.
chmod +x context-guard/statusline/*.sh context-guard/hooks/*.sh \
         context-guard/hooks/*.py context-guard/*.py 2>/dev/null || true
mkdir -p .claude/handoffs/archive 2>/dev/null || true
echo "✓ scripts are now executable"

# 2) If this is already a git repo, install the safety pre-commit hook.
if [ -d .git ]; then
  ./scripts/install-git-hooks.sh
else
  echo "  (no .git yet — after 'git init', run ./scripts/install-git-hooks.sh)"
fi

# 2b) Seed a local .env from the example so the dev has somewhere to put secrets.
#     .env is gitignored; it is never committed. Placeholders only until you fill it.
if [ -f .env.example ] && [ ! -f .env ]; then
  cp .env.example .env
  echo "✓ created .env from .env.example — fill in real values (it stays gitignored)"
elif [ -f .env ]; then
  echo "  (.env already exists — left untouched)"
fi

# 3) Sanity: confirm the hooks Claude Code will call are runnable.
for s in scripts/guard.sh scripts/state-freshness.sh scripts/check-core.sh \
         scripts/check-claude-md-size.sh scripts/precompact-snapshot.sh \
         scripts/quality-gate.sh; do
  [ -x "$s" ] && echo "  ✓ $s" || echo "  ✗ $s NOT executable — check permissions"
done

echo "──────────────────"
echo "Next:"
echo "  1. git init   (if you haven't)   then  ./scripts/install-git-hooks.sh"
echo "  2. Verify every hook actually works:  bash scripts/test-hooks.sh   (expect GREEN)"
echo "  2b. Context Guard is OPTIONAL and MACHINE-LEVEL: one shared runtime at"
echo "      ~/.claude/context-guard/. From the Context Guard release tree run"
echo "      python3 scripts/install-context-guard.py --project <this project>"
echo "      then python3 ~/.claude/context-guard/verify-install.py --project . (GREEN)."
echo "      A project NEVER carries the runtime - only .claude/context-guard/config.json."
echo "  3. In Claude Code, say:  \"Run the FIRST RUN onboarding interview from CLAUDE.md.\""
echo "     (FIRST RUN owns onboarding here; don't regenerate CLAUDE.md with /init —"
echo "      it already exists and its CORE is hash-protected. If /init already ran,"
echo "      roll nothing back: just run FIRST RUN next.)"
