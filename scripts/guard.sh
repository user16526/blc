#!/usr/bin/env bash
# PreToolUse guard: blocks secrets being written + destructive SHELL commands.
# Exit !=0 = block. Windows: run Claude Code from Git Bash/WSL, or port to PowerShell.
set -euo pipefail
p="$(cat || true)"

# Shared secret patterns (single source of truth). Fallback = fail SAFE, not open:
# if the pattern file is missing, block writes that even smell like a credential.
d="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$d/secret-patterns.sh" ]; then . "$d/secret-patterns.sh"; else
  SECRET_REGEX='(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
fi

# Detect the calling tool. The destructive-command and git-staging checks only make
# sense for actual shell commands (Bash). Scanning file CONTENT (Write/Edit) for
# command-like words false-positives on docs and analysis (and trains people to reword
# around the guard, which is worse for safety), so we skip them there. Secrets are
# still checked for every tool below.
case "$p" in
  *'"tool_name":"Bash"'*|*'"tool_name": "Bash"'*) is_bash=1 ;;
  *) is_bash=0 ;;
esac

# Secrets being written into the repo (all tools)
if echo "$p" | grep -Eq "$SECRET_REGEX"; then
  echo "BLOCKED: looks like a hardcoded secret. Use an env var (.env / process.env)." >&2; exit 2
fi

# Everything past here targets shell commands only (secrets were already checked above).
[ "$is_bash" = "1" ] || exit 0

# Block committing a real .env (gitignore can be bypassed with -f)
if echo "$p" | grep -Eiq 'git add (-f |--force )?[^&|]*\.env([^.]|$)|git add (-f|--force|-A|\.)([^&|]*\.env)?'; then
  if echo "$p" | grep -Eiq '\.env([^.]|$)' && ! echo "$p" | grep -Eiq '\.env\.example'; then
    echo "BLOCKED: refusing to stage a real .env. It must stay gitignored; commit .env.example instead." >&2; exit 2
  fi
fi

# Destructive commands (code + VPS/infra + work-erasing git)
if echo "$p" | grep -Eiq 'rm -rf|mkfs|(^|[^a-z])dd |DROP DATABASE|TRUNCATE |docker volume rm|docker system prune -a|kubectl delete (namespace|pvc)|terraform destroy|git push --force|git push -f|git reset --hard|git checkout -- |git checkout \.|git clean -[a-z]*f|git branch -D|ufw --force reset|iptables -F|systemctl (stop|disable) (ssh|sshd)|chmod -R 777|> /etc/'; then
  echo "BLOCKED: destructive/work-erasing command. Needs a backup/commit + explicit approval; run it manually." >&2; exit 2
fi

exit 0
