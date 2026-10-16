#!/usr/bin/env bash
# PreToolUse guard: blocks secrets being written + destructive SHELL commands.
# Exit 2 = block, exit 0 = allow. Claude Code blocks a tool call ONLY on exit 2; any other
# exit is a non-blocking error and the call RUNS. So the EXIT trap below turns every other
# exit (a `set -e` death, a crash) into 2: the guard fails closed (v8.3.32).
# KNOWN LIMIT: a hook that TIMES OUT does not block either — proven live 2026-10-16 on Claude
# Code 2.1.301 (a hook still running at its timeout: the call ran). Nothing here may wait on a
# network, a lock or a prompt; the guard stays a few fast local checks.
# Inspects the Bash tool and (v8.3.27) the PowerShell tool a Windows
# host exposes: same git rules for both, plus a PowerShell-native destructive list.
set -euo pipefail
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "BLOCKED: guard.sh failed (exit $rc), so this call was not checked. Fix the guard, or run the command yourself." >&2; exit 2; fi' EXIT
p="$(cat || true)"

# Not a JSON object (a UTF-8 BOM, a truncated or an empty input): Claude Code always sends one
# object, so anything else is a fault, and a fault blocks (v8.3.32, backlog #99 — Radion's
# guard crashed on a BOM and let everything through). Only the two ends are tested: the
# input can be megabytes.
p_head="${p:0:64}"; p_tail="$p"; [ "${#p}" -le 64 ] || p_tail="${p: -64}"
if ! [[ $p_head =~ ^[[:space:]]*\{ && $p_tail =~ \}[[:space:]]*$ ]]; then
  echo "BLOCKED: the hook input is not a JSON object (a BOM, truncated or empty input), so this call was not checked." >&2; exit 2
fi

# hit ERE TEXT [-i]: 0 = TEXT matches, 1 = it does not (v8.3.32, #113). TEXT goes in through a
# here-string, never `echo "$x" | grep -q`: under pipefail grep's early exit kills the writer,
# and the pipeline status turned a hit into "no match" on any input over ~64 KB (probe: 5 of 5
# misses at 70 KB). Any other outcome — a grep error, a bad pattern, a here-string bash could
# not write — leaves rc at 9: a check that did not run blocks.
hit() {
  local rc=9
  { grep -Eq ${3:-} -- "$1" && rc=0 || rc=$?; } <<< "$2"
  if [ "$rc" -gt 1 ]; then
    echo "BLOCKED: a guard.sh check could not run (status $rc), so this call was not checked." >&2; exit 2
  fi
  return "$rc"
}

# Shared secret patterns (single source of truth). Fallback = fail SAFE, not open:
# if the pattern file is missing, block writes that even smell like a credential.
d="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$d/secret-patterns.sh" ]; then . "$d/secret-patterns.sh"; else
  SECRET_REGEX='(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
fi

# Detect the calling tool. The destructive-command and git-staging checks only make
# sense for actual shell commands (Bash, PowerShell). Scanning file CONTENT (Write/Edit)
# for command-like words false-positives on docs and analysis (and trains people to
# reword around the guard, which is worse for safety), so we skip them there. Secrets
# are still checked for every tool below. Until v8.3.26 only Bash was inspected, so a
# PowerShell tool call got the secret check and nothing else (BACKLOG-v8.3.27 #7a).
# PowerShell is tested FIRST: a payload naming both tools gets more rules, never fewer
# (security review: a nested "tool_name":"Bash" key must not switch the PS list off).
case "$p" in
  *'"tool_name":"PowerShell"'*|*'"tool_name": "PowerShell"'*) is_shell=1; is_ps=1 ;;
  *'"tool_name":"Bash"'*|*'"tool_name": "Bash"'*) is_shell=1; is_ps=0 ;;
  *) is_shell=0; is_ps=0 ;;
esac

# Secrets being written into the repo (all tools). A here-string, not `echo |`: under
# pipefail a writer killed by an early `grep -q` exit turned a hit into "no match".
if hit "$SECRET_REGEX" "$p"; then
  echo "BLOCKED: looks like a hardcoded secret. Use an env var (.env / process.env)." >&2; exit 2
fi

# Everything past here targets shell commands only (secrets were already checked above).
[ "$is_shell" = "1" ] || exit 0

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
try:   # bytes in, UTF-8 out: the result must not depend on the host's code page
    d = json.loads(sys.stdin.buffer.read().decode("utf-8", "surrogateescape"))
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
sys.stdout.buffer.write(" ".join(kept).encode("utf-8", "surrogateescape"))
PY
)"
scan="$p"
if hit '<<' "$p" && hit 'git[[:space:]]+(commit|tag)' "$p" \
   && command -v python3 >/dev/null 2>&1; then
  if s="$(printf '%s' "$p" | python3 -I -c "$GUARD_MSG_PY" 2>/dev/null)" && [ -n "$s" ]; then scan="$s"; fi
fi

# Any git global options before a subcommand (v8.3.26): `-C <dir>`, `-c <k=v>`,
# `--no-pager`, `-P`, `--git-dir=…`, a value in double or single quotes, or double quotes
# as they appear JSON-escaped in the raw hook input — each quoted value may run on into a
# bare suffix (`'/d/my'/repo`). v8.3.25 recognised only -C/-c with a bare value, so
# `git --no-pager push --force` or a quoted -C path hid a forced push.
# A word is any run of bare characters and whole quoted segments, so a quote attached
# mid-word (`-c alias.x='!a;b'`) is consumed with the ; inside it (sheriff pass).
GITW='(\\"[^"]*\\"|"[^"]*"|'"'"'[^'"'"']*'"'"'|\\\\.|\\.|[^ ;&|"'"'"'])+'   # \\\\. / \\. = escaped char, JSON / decoded
# Only the options that take a value consume a following word — otherwise the prefix
# could swallow a subcommand and its argument (`git --no-pager log --grep push --force`).
GITPFX='git( -(C|c|-git-dir|-work-tree|-namespace|-config-env) '"$GITW"'| -'"$GITW"')*'

# Block staging a real .env (gitignore can be bypassed with -f).
# v8.3.26: `.env` is tested as a PATH ARGUMENT of `git add` / `git stage`, with the
# pre-commit hook's rule — (^|/)\.env($|\.), minus .env.example — never as text anywhere
# in the command. The v8.3.25 rule fired on any command holding `git add -A`, `git add .`
# or a dot-path plus the letters ".env" anywhere, so `git add x && git commit -m "…the .env
# blocker…"` was refused with nothing staged; and `.env.example` anywhere cleared a real
# .env beside it. A first regex cut of this rule was itself bypassed by shell syntax
# (a brace list, git pathspec magic, a ; or newline inside quotes — security review), so
# the command is TOKENIZED as the shell would (python shlex: quotes, escapes, ; & |),
# brace lists are expanded, pathspec magic (`:(top)`, `:!`, `:/`) is stripped, and a
# dot-led glob is matched against .env. `git add -f` of the whole tree (`.`, `-A`, `:/`,
# `*`) is refused too: -f bypasses .gitignore wholesale, which is how a .env gets staged
# without being named. An unbalanced quote cannot be segmented, so every token is tested.
# A staging path holding an unresolved `$`/backtick expansion falls back to the v8.3.25
# text answer: any .env in the command blocks. A forced whole tree is normalised (`././`).
# KNOWN LIMIT (text, not a git model; the pre-commit hook is the backstop): a pathspec
# from a file (`--pathspec-from-file`), a variable set in an EARLIER command, a glob not
# led by a dot, a forced directory (`git add -f config/`), a git alias. A commit message
# quoting "git add .env" inline is still blocked.
# Without python3 (or with a broken one) a text rule runs instead: fail closed, never open.
# v8.3.32: once OUR code runs, its own failure is a fault and blocks — invalid JSON prints
# BADJSON, any uncaught error prints CRASH (sys.excepthook). A stub python3 (missing, or the
# Windows Store alias) never runs it and keeps the text fallback. `python3 -I`: a json.py or
# shlex.py in the project directory must not replace the modules this guard reads with.
# v8.3.27: the same tokenizer decides two more subcommands (BACKLOG-v8.3.27 #8, #19).
#   push  — a force flag (`-f` in any cluster, `--force`, `--force-with-lease[=…]`) before
#           `--`, or a `+refspec` anywhere, is BLOCK-PUSH. Two sheriff rounds on v8.3.26
#           each found one shell-word shape the text regex missed; the tokens are what the
#           shell hands git, so a QUOTED flag (`push "--force"`) is caught here too. The
#           text regexes further down stay as the backstop (and the no-python answer).
#           KNOWN LIMIT: a force carried in git CONFIG rather than on the command line —
#           `-c remote.origin.push=+refs/heads/main`, a `push.default`/alias set earlier,
#           a `.git/config` entry — is invisible to both layers (security review).
#   merge — a message from stdin (`-F -`, `-F-`, `--file -`, `--file=-`) is BLOCK-MERGE:
#           git merge reads no message from stdin, the merge dies AFTER the branch switch
#           (2026-09-14, field). Sessions typed it live despite the prose; a rule it is.
GUARD_ENV_PY="$(cat <<'PY'
import io, sys
sys.excepthook = lambda typ, val, tb: print("CRASH " + typ.__name__, flush=True)
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="surrogateescape", newline="\n", line_buffering=True)
import fnmatch, json, posixpath, re, shlex
raw = sys.stdin.buffer.read().decode("utf-8", "surrogateescape")
if sys.argv[1] == "json":
    try:
        d = json.loads(raw)
    except Exception:   # not JSON, or nested deeper than the parser goes
        print("BADJSON")
        sys.exit(0)
    t = d.get("tool_input") if isinstance(d.get("tool_input"), dict) else d
    c = t.get("command") if isinstance(t, dict) else None
    if not isinstance(c, str):
        print("NOCMD")   # no command string: the text rules below decide, as before
        sys.exit(0)
else:
    c = raw
c = c.replace("\\\r\n", " ").replace("\\\n", " ")
ENV = re.compile(r"(^|/)\.env($|\.)", re.I)
EXAMPLE = re.compile(r"(^|/)\.env\.example$", re.I)
BRACE = re.compile(r"^(.*?)\{([^{}]*,[^{}]*)\}(.*)$")
SEP = set(";&|\n")
VALUED = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env"}
WHOLE = {".", "./", ":/", ":(top)", "*", "'*'"}
# An exclude-only pathspec (`:!x`, `:^x`, `:(exclude)x`) means "everything except x":
# with -f that is the whole tree past .gitignore (security re-check 2).
EXCL = re.compile(r"^:(\(([^)]*,)?exclude(,[^)]*)?\)|[!^])")

def expand(t, n=0):
    m = BRACE.match(t)
    if not m or n > 5:
        return [t]
    return [x for a in m.group(2).split(",") for x in expand(m.group(1) + a + m.group(3), n + 1)]

def norm(t):
    t = t.strip("$\"'`").rstrip(")`")   # $: shlex reads ANSI-C $'.env' as $.env
    t = re.sub(r"^:(\([^)]*\)|[!^/]*)", "", t)
    return t.replace("\\", "/")

def envish(tok):
    for x in expand(tok):
        p = norm(x)
        if EXAMPLE.search(p):
            continue
        if ENV.search(p):
            return p
        base = p.rsplit("/", 1)[-1].lower()
        if base.startswith(".") and any(ch in base for ch in "*?["):
            if fnmatch.fnmatchcase(".env", base) or fnmatch.fnmatchcase(".env.local", base):
                return p
    return None

def is_sep(t):
    return set(t) <= SEP

try:
    # A newline ends a command as ; does; a # comment stays in the tokens, so .env text
    # in it still blocks, as in v8.3.25 (both from the sheriff re-check).
    lx = shlex.shlex(c, posix=True, punctuation_chars=";&|\n")
    lx.whitespace = " \t\r"
    lx.commenters = ""
    lx.whitespace_split = True
    toks = list(lx)
except ValueError:
    if re.search(r"\bgit(\.exe)?\b", c) and re.search(r"\b(add|stage)\b", c):
        hits = [h for h in (envish(t) for t in c.split()) if h]
        if hits:
            print("BLOCK " + hits[0])
            sys.exit(0)
    print("OK")
    sys.exit(0)

i = 0
while i < len(toks):
    t = toks[i].lstrip("$(`{")
    if t.rsplit("/", 1)[-1].lower() not in ("git", "git.exe"):
        i += 1
        continue
    j = i + 1
    while j < len(toks) and toks[j].startswith("-") and not is_sep(toks[j]):
        j += 2 if toks[j] in VALUED else 1
    if j >= len(toks) or toks[j] not in ("add", "stage", "push", "merge"):
        i = j
        continue
    k = j + 1
    args = []
    while k < len(toks) and not is_sep(toks[k]):
        args.append(toks[k])
        k += 1
    if toks[j] == "push":
        ended = False
        for a in args:
            if a == "--" and not ended:
                ended = True
            elif a.startswith("+") and len(a) > 1:
                print("BLOCK-PUSH +refspec forces that ref: " + a)
                sys.exit(0)
            elif not ended and (a == "--force" or a.startswith("--force-with-lease")):
                # --force-if-includes is a SAFETY flag, not a force (corpus, v8.3.27)
                print("BLOCK-PUSH " + a)
                sys.exit(0)
            elif not ended and a.startswith("-") and not a.startswith("--") and "f" in a[1:]:
                print("BLOCK-PUSH " + a)
                sys.exit(0)
        i = k
        continue
    if toks[j] == "merge":
        for n, a in enumerate(args):
            nxt = args[n + 1] if n + 1 < len(args) else ""
            if a in ("-F-", "--file=-") or (a in ("-F", "--file") and nxt == "-"):
                print("BLOCK-MERGE " + a)
                sys.exit(0)
        i = k
        continue
    force = whole = False
    paths = []
    ended = False
    for a in args:
        if not ended and a == "--":
            ended = True
        elif not ended and a.startswith("--"):
            force = force or a == "--force"
            whole = whole or a in ("--all", "--no-ignore-removal")
        elif not ended and a.startswith("-") and len(a) > 1:
            force = force or "f" in a[1:]
            whole = whole or "A" in a[1:]
        else:
            paths.append(a)
    for a in paths:
        h = envish(a)
        if h:
            print("BLOCK " + h)
            sys.exit(0)
    # Two cases keep the v8.3.25 answer — any .env text in the command blocks — because
    # the path alone cannot say what gets staged: an unresolved expansion
    # (`f=.env; git add "$f"`), and a FORCED add (`git add -f config/` may pull in
    # config/.env past .gitignore). The prose exemption (#9) is for unforced adds.
    envtext = re.search(r"\.env(?!\.example)", c, re.I)
    if envtext and (force or any(ch in a for a in paths for ch in "$`")):
        print("BLOCK .env in the command with a forced add or an unresolved staging path")
        sys.exit(0)
    if force and (whole or any(a in WHOLE or norm(a) in WHOLE
                               or posixpath.normpath(norm(a) or ".") == "." for a in paths)
                  or (paths and all(EXCL.match(a.strip("\"'`")) for a in paths))):
        print("BLOCK force-add of the whole tree (-f bypasses .gitignore)")
        sys.exit(0)
    i = k
print("OK")
PY
)"
envv=""
# A python3 that exits non-zero gave no verdict: keep only our own CRASH line (the excepthook
# exits 1), never other stdout — a stub that prints "OK" must not pass as a verdict.
crash_only(){ case "$1" in "CRASH "*) printf '%s' "$1" ;; esac; }
if command -v python3 >/dev/null 2>&1; then
  if [ "$scan" != "$p" ]; then   # already decoded, quoted-delimiter commit message dropped
    envv="$(printf '%s' "$scan" | python3 -I -c "$GUARD_ENV_PY" text 2>/dev/null)" || envv="$(crash_only "$envv")"
  else
    envv="$(printf '%s' "$p" | python3 -I -c "$GUARD_ENV_PY" json 2>/dev/null)" || envv="$(crash_only "$envv")"
  fi
fi
case "$envv" in
  "BLOCK "*)
    echo "BLOCKED: refusing to stage a real .env or to force-add past .gitignore (${envv#BLOCK }). Stage exact paths; commit .env.example instead." >&2; exit 2 ;;
  "BLOCK-PUSH "*)
    echo "BLOCKED: forced push (${envv#BLOCK-PUSH }) overwrites published work. Needs explicit approval; run it manually." >&2; exit 2 ;;
  "BLOCK-MERGE "*)
    echo "BLOCKED: git merge does not read a message from stdin (${envv#BLOCK-MERGE }) — the merge dies after the branch switch. Use: git merge -m '<message>' <branch>." >&2; exit 2 ;;
  BADJSON)
    echo "BLOCKED: the hook input is not valid JSON, so this call was not checked." >&2; exit 2 ;;
  "CRASH "*)
    echo "BLOCKED: guard.sh's command parser failed (${envv#CRASH }), so this call was not checked." >&2; exit 2 ;;
  OK) ;;
  *)
    # No verdict (python3 missing or broken, or NOCMD): the text rule, with .env.example REMOVED
    # before the test rather than clearing the whole command (v8.3.25 let
    # `git add .env.example .env` through here). Coarse on purpose: any .env text beside a
    # git add/stage blocks (.env.production included), and so does a forced whole-tree add.
    if hit 'git[^;&|]* (add|stage) ' "$scan" -i; then
      noex="$(sed -E 's/\.env\.example//Ig' <<< "$scan")"
      if hit '\.env' "$noex" -i; then
        echo "BLOCKED: refusing to stage a real .env. It must stay gitignored; commit .env.example instead." >&2; exit 2
      fi
      if hit 'git[^;&|]* (add|stage) [^;&|]*(-[A-Za-z]*f|--force)' "$scan" \
         && hit 'git[^;&|]* (add|stage) [^;&|]*( -[A-Za-z]*A| --all| \.[./]*| :/| \*| :[!^]| :\(exclude)( |$|[;&|"a-z])' "$scan"; then
        echo "BLOCKED: refusing to force-add the whole tree past .gitignore." >&2; exit 2
      fi
    fi
    # No-python answer for the merge rule (#19); the forced-push text rules below stay.
    if hit 'git[^;&|]* merge [^;&|]*(-F ?-|--file[= ]-)( |$|[;&|<])' "$scan"; then
      echo "BLOCKED: git merge does not read a message from stdin (-F -). Use: git merge -m '<message>' <branch>." >&2; exit 2
    fi ;;
esac

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
# (which forces that one ref) is blocked too, behind any git global option ($GITPFX above,
# v8.3.26 — it was `-C`/`-c` only). From v8.3.27 the PARSED tokens decide first
# (GUARD_ENV_PY, BLOCK-PUSH — a quoted flag included); these text rules are the backstop
# and the whole answer when python3 is missing. `--force-with-lease`
# is named explicitly: it only refuses when the remote moved since the last fetch, so a
# fetch-then-push still overwrites someone's published work. It used to be caught only
# as a prefix of `--force`, and only directly after `push` — a flag written after the
# remote and branch (`git push origin main --force`) slipped through.
DESTRUCTIVE_CI='rm -rf|mkfs|DROP DATABASE|TRUNCATE |docker volume rm|docker system prune -a|kubectl delete (namespace|pvc)|terraform destroy|'"$GITPFX"' push[^;&|]* --force-with-lease|'"$GITPFX"' push[^;&|]* --force|'"$GITPFX"' push[^;&|]* \+[A-Za-z0-9_./:@-]|git reset --hard|git checkout -- |git checkout \.|git branch[^;&|]* --for(c|ce)?( |$)|git branch[^;&|]* -[A-Za-z]*f[A-Za-z]*( |$)|ufw --force reset|systemctl (stop|disable) (ssh|sshd)|> /etc/'

# Case-SENSITIVE: the flag letter is the danger; upper and lower are different commands.
# The word boundary here must exclude BOTH cases: with `[^a-z]` an upper-case letter
# would count as a boundary, so an ordinary word ending in "dd " ("Add ") would match.
DESTRUCTIVE_CS='git branch[^;&|]* -[A-Za-z]*D[A-Za-z]*( |$)|'"$GITPFX"' push[^;&|]* -[A-Za-z]*f|git clean -[A-Za-z]*f|(^|[^a-zA-Z])dd |iptables -F|chmod -R 777'

if hit "$DESTRUCTIVE_CI" "$scan" -i || hit "$DESTRUCTIVE_CS" "$scan"; then
  echo "BLOCKED: destructive/work-erasing command. Needs a backup/commit + explicit approval; run it manually." >&2; exit 2
fi

# PowerShell-native list (v8.3.27), applied ONLY to the PowerShell tool: its syntax is
# case-insensitive and its parameters abbreviate to any unambiguous prefix, so a
# recursive forced delete is Remove-Item / rm / ri / del / erase / rd / rmdir with
# -Recurse (-r, -rec…) AND -Force (-fo…) in either order (-Force alone deletes one
# file; -Recurse alone stops at read-only and hidden items — the pair is the work-eraser,
# exactly as `rm -rf` is the pair above). Plus the disk-level commands, and the cmd.exe
# switches (`rd /s /q`, `del /s`) PowerShell passes through. -Filter is not -Force: only
# `-fo` prefixes count. The idiomatic pipeline form — `Get-ChildItem -Recurse |
# Remove-Item -Force` — is the same pair split across a pipe and is blocked too;
# PowerShell also accepts an en/em dash as a parameter prefix (functional review).
# The hook input is JSON, where a newline is the two characters `\n` and a dash may
# arrive as `–`: the command is DECODED (python3) and each newline becomes a `;`
# — a separator, so a command on the second line of a script is seen (security review,
# HIGH) and two safe lines never fuse into one destructive-looking command (re-check).
# Without python3 the `\n` `\r` escapes are rewritten to `;` in the raw text instead.
# KNOWN LIMIT, same class as the bash lists above: this is a TEXT match. Splatting
# (`$p=@{Recurse=$true;Force=$true}; Remove-Item @p`), a backtick inside a cmdlet name,
# a name built from strings (`&('Remove-'+'Item')`), flags held in variables, runtime
# aliases, anything inside a `.ps1` the command merely calls, and — without python3 —
# a `\uXXXX`-escaped dash are not recognised.
# "It did not block" means "it did not recognise", here as everywhere in this file.
ANCH='(^|[;|&({ "'"'"'])'
PSD='(-|–|—|―)'
PS_V='(remove-item|rm|ri|del|erase|rd|rmdir)'
# An argument span: anything up to an UNQUOTED separator; a quoted path may carry ; | &
# ('C:\R&D\project') without ending the command (sheriff, v8.3.27).
PS_ARG="([^;|&\"']|'[^']*'|\"[^\"]*\")*"
PS_RF="$PS_V"'["'"'"']?( '"$PS_ARG"')?'   # a quoted name (&'Remove-Item') closes with a quote
PS_R=' '"$PSD"'(r|re[a-z]*)(:\$?[a-z]*)?'   # -r, -re, -rec…, -recurse: every unambiguous prefix
PS_F=' '"$PSD"'fo[a-z]*(:\$?[a-z]*)?'
PS_END='( |$|[;|&)}"])'
PS_PIPE="$PSD"'(r|re[a-z]*)(:\$?[a-z]*)?( '"$PS_ARG"')?\|'"$PS_ARG$PS_RF$PS_F$PS_END"
PS_CMD="$ANCH"'(cmd(\.exe)? /c )?(rd|rmdir|del|erase) '"$PS_ARG"'/s'"$PS_END"
PS_DESTRUCTIVE="$ANCH$PS_RF$PS_R"'( '"$PS_ARG"')?'"$PS_F$PS_END"'|'"$ANCH$PS_RF$PS_F"'( '"$PS_ARG"')?'"$PS_R$PS_END"'|'"$PS_PIPE"'|'"$PS_CMD"'|format-volume|clear-disk|remove-partition|initialize-disk'
GUARD_PS_PY="$(cat <<'PY'
import json, sys
# bytes in, UTF-8 out: on a cp1252 host a bare stdin/print would mangle a decoded en dash
# (re-check round 3); a backtick before the newline is PowerShell's line continuation.
d = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
t = d.get("tool_input") if isinstance(d.get("tool_input"), dict) else d
c = t.get("command") if isinstance(t, dict) else None
c = c.replace("`\r\n", " ").replace("`\n", " ") if isinstance(c, str) else ""
sys.stdout.buffer.write(c.replace("\r", ";").replace("\n", ";").replace("\t", " ").encode("utf-8"))
PY
)"
ps_scan=""
if [ "$is_ps" = "1" ] && command -v python3 >/dev/null 2>&1; then
  ps_scan="$(printf '%s' "$p" | python3 -I -c "$GUARD_PS_PY" 2>/dev/null)" || ps_scan=""
fi
[ -n "$ps_scan" ] || ps_scan="$(printf '%s' "$scan" | sed 's/`\\r\\n/ /g; s/`\\n/ /g; s/\\[nr]/;/g; s/\\t/ /g')"
if [ "$is_ps" = "1" ] && hit "$PS_DESTRUCTIVE" "$ps_scan" -i; then
  echo "BLOCKED: destructive/work-erasing PowerShell command. Needs a backup/commit + explicit approval; run it manually." >&2; exit 2
fi

exit 0
