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

# What the command-shape checks below read (v8.3.25). A commit or tag MESSAGE fed from a
# heredoc with a QUOTED delimiter is prose, not a command: the shell expands nothing in
# it and git only stores it. Scanning it blocked a commit whose message honestly
# described an earlier, correctly-blocked .env staging, and the only repair on offer was
# to reword the message until the guard stopped recognising it — the evasion every rule
# here forbids. So those bodies, and only those, are dropped from $scan:
#   - the command's FIRST line starts with `git commit` / `git tag` and takes its message
#     from the heredoc (`-F -`, `--file -`, or `-m "$(cat <<`), with no quote, `#`, `$`,
#     `(`, backslash, redirection or ; & | anywhere before it — nothing that could turn
#     `git commit` into an argument, a comment, or text inside an open string;
#   - the delimiter is QUOTED and ENDS that line. Unquoted, the shell expands $(...) in
#     the body; anything after it (`| sh`, `'EOF'X`) could route the body elsewhere;
#   - exactly one << on that line, and not a <<< here-string, which has no body.
# The hook input is DECODED as JSON (python3) before any of this, never split with sed:
# a split on the text `\n` also splits an escaped backslash-n that bash never sees as a
# newline. Everything that is not this exact shape is scanned RAW, exactly as before,
# including backslash-newline continuations. Every line after the terminator is scanned.
# If python3 is missing or anything fails, $scan is the raw input — fail closed.
# The secret check above always reads the full input: a secret in a message is a secret.
GUARD_MSG_PY="$(cat <<'PY'
import json, re, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
ti = d.get("tool_input") if isinstance(d.get("tool_input"), dict) else d
cmd = ti.get("command") if isinstance(ti, dict) else None
if not isinstance(cmd, str) or "\r" in cmd:
    # A CR changes where bash ends the heredoc (git-bash accepts "EOF\r" as the
    # terminator; an exact compare here would not), so never exempt a command with one.
    sys.exit(1)
lines = cmd.split("\n")
opener = re.compile(
    r"^[ \t]*git[ \t]+(?:commit|tag)"
    r"(?:[ \t][^;&|$`()\"'\\<>#\r]*)?"
    r"(?:[ \t]-F[ \t]*-[ \t]*|[ \t]--file[= ]-[ \t]*|[ \t](?:-m|--message)[= ]\"\$\(cat[ \t]+)"
    r"<<-?[ \t]*(?:'([A-Za-z_][A-Za-z0-9_]*)'|\"([A-Za-z_][A-Za-z0-9_]*)\")[ \t]*$")
m = opener.match(lines[0])
if not m or lines[0].count("<<") != 1:
    sys.exit(1)
tag = m.group(1) or m.group(2)
kept = [lines[0]]
for i, line in enumerate(lines[1:], 1):
    if line.lstrip("\t") == tag:      # never ends LATER than bash would
        kept += lines[i + 1:]
        break
print(" ".join(kept))
PY
)"
scan="$p"
if printf '%s' "$p" | grep -q '<<' && printf '%s' "$p" | grep -Eq 'git[[:space:]]+(commit|tag)' \
   && command -v python3 >/dev/null 2>&1; then
  if s="$(printf '%s' "$p" | python3 -c "$GUARD_MSG_PY" 2>/dev/null)" && [ -n "$s" ]; then scan="$s"; fi
fi

# Block committing a real .env (gitignore can be bypassed with -f)
if echo "$scan" | grep -Eiq 'git add (-f |--force )?[^&|]*\.env([^.]|$)|git add (-f|--force|-A|\.)([^&|]*\.env)?'; then
  if echo "$scan" | grep -Eiq '\.env([^.]|$)' && ! echo "$scan" | grep -Eiq '\.env\.example'; then
    echo "BLOCKED: refusing to stage a real .env. It must stay gitignored; commit .env.example instead." >&2; exit 2
  fi
fi

# ---- destructive commands (code + VPS/infra + work-erasing git) --------------
# TWO lists, and the split is the whole point (v8.3.24, field lesson 2026-09-08).
#
# All of this used to be one case-INSENSITIVE grep. For SQL keywords and command
# names that is correct — `drop database` and `DROP DATABASE` are one command.
# For a UNIX FLAG it is wrong: in a flag the case IS the meaning, and folding it
# blocks the safe sibling of a dangerous command.
#
#   force-delete of a branch  destroys unmerged work — block it.
#   the lower-case sibling    refuses unless the branch is merged — it is the
#                             SAFE post-merge cleanup, and it was being blocked.
#
# Same class of bug elsewhere in the old list: the iptables flush flag is
# upper-case F while lower-case f is --fragment, and chmod's recursive flag is
# upper-case R while lower-case r is not a chmod flag at all.
#
# And it is not only flags. The raw disk-copy command is a two-letter LOWER-CASE
# name; folding its case turned it into a match for the upper-case day field of
# an ISO date template, so writing a document containing a `-DD ` placeholder via
# a heredoc was blocked as a destructive command. Found the hard way while
# writing this very release (2026-09-08).
#
# The real damage was not the inconvenience. A blocked safe command has only two
# exits: run it by hand, or reword it until the guard stops recognising it. A
# guard people learn to phrase around has stopped being a guard.
#
# The branch rule does NOT try to recognise "delete combined with force", and that is
# deliberate — two cross-vendor review rounds killed that idea before it shipped.
# Enumerating the spellings is a losing game: the two flags can be clustered in either
# order, separated, or written long, and each round of patching the alternatives left
# another order uncovered.
#
# The rule that IS decidable: a branch delete WITHOUT force is safe by definition —
# git refuses it unless the branch is merged. So the guard does not need to model
# deletion at all. It blocks FORCE, in any spelling, on any branch command, and lets
# everything else through. That is one property, order-independent, and it is why the
# safe cleanup this release exists to unblock stays unblocked.
#
# KNOWN LIMIT, accepted deliberately (cross-vendor review rounds 2-4). This guard
# matches command TEXT; it does not parse shell tokens or git options. Two consequences
# it cannot fix at this layer:
#   - a destructive command quoted inside an INLINE message (`-m "..."`) or inside any
#     heredoc other than a quoted-delimiter commit/tag message (see $scan above, v8.3.25)
#     still matches. The header above explains why content scanning is skipped for file
#     writes but not for shell.
#   - git's own semantics are richer than any regex. The reviewer's closing example was
#     deleting two branches in one command whose upstreams are each other, which can
#     strand commits with no force flag anywhere. Closing that class needs argument
#     parsing, not another alternative in a regex.
# The guard is a speed bump against the common destructive mistake, not a sandbox.
# Treat "it did not block" as "it did not recognise", never as "this is safe".
#
# RULE for editing these lists: if the danger depends on a letter's case, the
# pattern belongs in DESTRUCTIVE_CS. Otherwise it belongs in DESTRUCTIVE_CI.
# Never move a pattern to DESTRUCTIVE_CS just to make a block go away — first
# confirm the lower-case form really is harmless.

# Case-insensitive: case carries no meaning in these.
# A forced push is blocked wherever its flag sits after `push` (v8.3.25), and a `+refspec`
# (which forces that one ref) is blocked too, also behind `git -C <dir>` / `git -c <k=v>`.
# Still a text match, not a parser: a quoted flag is not recognised — see KNOWN LIMIT
# above. `--force-with-lease`
# is named explicitly: it only refuses when the remote moved since the last fetch, so a
# fetch-then-push still overwrites someone's published work. It used to be caught only
# as a prefix of `--force`, and only directly after `push` — a flag written after the
# remote and branch (`git push origin main --force`) slipped through.
DESTRUCTIVE_CI='rm -rf|mkfs|DROP DATABASE|TRUNCATE |docker volume rm|docker system prune -a|kubectl delete (namespace|pvc)|terraform destroy|git( -[Cc] [^ ;&|]+)* push[^;&|]* --force-with-lease|git( -[Cc] [^ ;&|]+)* push[^;&|]* --force|git( -[Cc] [^ ;&|]+)* push[^;&|]* \+[A-Za-z0-9_./:@-]|git reset --hard|git checkout -- |git checkout \.|git branch[^;&|]* --for(c|ce)?( |$)|git branch[^;&|]* -[A-Za-z]*f[A-Za-z]*( |$)|ufw --force reset|systemctl (stop|disable) (ssh|sshd)|> /etc/'

# Case-SENSITIVE: the flag letter is the danger; upper and lower are different commands.
# The word boundary here must exclude BOTH cases: with `[^a-z]` an upper-case letter
# would count as a boundary, so an ordinary word ending in "dd " ("Add ") would match.
DESTRUCTIVE_CS='git branch[^;&|]* -[A-Za-z]*D[A-Za-z]*( |$)|git( -[Cc] [^ ;&|]+)* push[^;&|]* -[A-Za-z]*f|git clean -[A-Za-z]*f|(^|[^a-zA-Z])dd |iptables -F|chmod -R 777'

if echo "$scan" | grep -Eiq "$DESTRUCTIVE_CI" || echo "$scan" | grep -Eq "$DESTRUCTIVE_CS"; then
  echo "BLOCKED: destructive/work-erasing command. Needs a backup/commit + explicit approval; run it manually." >&2; exit 2
fi

exit 0
