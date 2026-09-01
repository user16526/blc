#!/usr/bin/env bash
# SHERIFF wrapper — owns the ENTIRE external-reviewer invocation.
#
#   printf '%s' "$criteria_and_diff" | scripts/sheriff-review.sh --author claude
#
# WHY THIS SCRIPT EXISTS
# Reviewer independence used to live as prose in .claude/commands/sheriff.md, i.e.
# as a flag set an agent had to remember to type correctly every time. FOUR
# cross-vendor review rounds over this mechanism (2026-08-30) found 9 real defects,
# each missed by the round before:
#   round 1 — no `-C <empty-dir>`, so codex auto-loaded the repo's own AGENTS.md
#             and reviewed with the author's context (verified: it quoted the file);
#   round 2 — no constraint on `-o`, and `-s read-only` sandboxes the MODEL's tools,
#             NOT the CLI's own output write (verified: `-o` created its file under
#             `-s read-only`), so a findings path in the repo was a write primitive;
#             plus a hardcoded reviewer vendor and a fallback that dropped the criteria;
#   round 3 — on this wrapper: protected root taken from the CALLER's cwd, symlink
#             final components bypassing containment, a vendor denylist that let
#             `ChatGPT`/`o3` through, and flag assertions that only ran when a real
#             CLI happened to be installed;
#   round 4 — flag detection by substring, so a CLI that RENAMED `--cd` to `--cd-root`
#             would have passed the readiness check and then run without the boundary.
# Enumerating boundaries in prose does not close an open-ended class. The flags now
# live here, in one executed code path, asserted by scripts/test-hooks.sh section 8.
# Do not relax a check here without a review round of its own.
#
# This script IS the codex-vendor sheriff. Cross-vendor is the whole point, so it
# refuses to review a diff whose author is also codex (see --author).
#
# EXIT CODES  (every refusal is loud, and every refusal still yields a review)
#   0  review ran; findings written to the --out path (printed on the last line)
#   1  the codex invocation itself failed
#   3  REFUSED: a package/findings path is unsafe — it resolves inside the repo
#      root, or the target already exists (see refuse_if_exists)
#   4  REFUSED: same-vendor author and sheriff
#   5  REFUSED: capability probe failed  -> manual review package emitted
#   6  REFUSED: codex CLI not found      -> manual review package emitted
set -uo pipefail

SHERIFF_TOOL="codex"     # the CLI this wrapper drives
SHERIFF_VENDOR="openai"  # the VENDOR behind it — the thing the author must not share

# Isolation flags this wrapper must be able to pass. Missing one means the guarantee
# cannot be constructed, so automation is gated (exit 5) and the review goes manual.
# `--ephemeral` is REQUIRED, decided round 6 (2026-08-31). The package this wrapper
# pipes in is the entire diff under review; without --ephemeral codex writes that
# session to disk, where a later `codex` run can resume it. That does not weaken THIS
# review's independence, but it leaves review content as persistent state the mechanism
# never accounted for, and it can contaminate a LATER one. Requiring it costs nothing:
# exit 5 still emits the manual package, so the review happens either way. Rationale in
# .agent/state/decisions.md.
REQUIRED_FLAGS="--sandbox --cd --output-last-message --skip-git-repo-check --ephemeral"
# Additive hardening. Missing one weakens the run but does not break independence,
# so it warns and proceeds. `--ignore-rules` governs what the reviewer may RUN
# (execpolicy .rules files), which the read-only sandbox already bounds — a different
# class from what it can SEE or LEAVE behind.
HARDENING_FLAGS="--ignore-rules"

die(){ echo "sheriff-review: $2" >&2; exit "$1"; }

# Does the CLI's help advertise this EXACT option? A bare substring match is wrong:
# `--cd` also matches `--cd-root`, and `--sandbox` matches `--sandbox-mode`, so a CLI
# that RENAMED an isolation flag would pass the readiness check and then run without
# the boundary it claimed. The flag must appear as a whole token - start of line or
# preceded by space/comma, and followed by space, comma, `=`, or end of line.
has_flag(){ # $1 = help text, $2 = flag
  printf '%s' "$1" | grep -qE -- "(^|[[:space:],])$2([[:space:],=]|\$)"
}

AUTHOR=""; OUT=""; PKG=""; SCRATCH=""; DRY=0; PROBE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --author)  AUTHOR="${2:-}";  shift 2 ;;
    --out)     OUT="${2:-}";     shift 2 ;;
    --package) PKG="${2:-}";     shift 2 ;;
    --scratch) SCRATCH="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    --probe)   PROBE=1; shift ;;
    -h|--help) sed -n '2,27p' "$0"; exit 0 ;;
    *) die 2 "unknown argument: $1" ;;
  esac
done

# ── 0. --probe: is automation available on THIS machine? ───────────────────────
# Standalone readiness check — no author, no stdin, no review. Run it after an
# install, a template merge, or a codex-cli version bump. Same exit codes as a
# real run so a caller can branch on one contract: 0 automation available,
# 5 a required isolation flag is missing, 6 no CLI.
# It reports what the CLI ADVERTISES. A flag that still exists but changed meaning
# looks identical here — only scripts/integration/sheriff-isolation-live.sh can
# tell those apart, which is why that script exists and why this one cannot
# replace it.
if [ "$PROBE" = "1" ]; then
  if ! command -v "$SHERIFF_TOOL" >/dev/null 2>&1; then
    echo "sheriff-review --probe: NO CLI"
    echo "  '$SHERIFF_TOOL' is not on PATH. Automated /sheriff is unavailable;"
    echo "  the review runs through the manual package instead."
    exit 6
  fi
  echo "sheriff-review --probe"
  echo "  tool:    $(command -v "$SHERIFF_TOOL")"
  echo "  version: $("$SHERIFF_TOOL" --version </dev/null 2>&1 | head -1)"
  HELP="$("$SHERIFF_TOOL" exec --help 2>&1 8>&- 9>&-)"
  miss=""; have=""
  for f in $REQUIRED_FLAGS; do
    if has_flag "$HELP" "$f"; then have="$have $f"; else miss="$miss $f"; fi
  done
  echo "  required:$have"
  soft=""
  for f in $HARDENING_FLAGS; do
    has_flag "$HELP" "$f" && soft="$soft $f"
  done
  echo "  hardening:${soft:- (none available)}"
  if [ -n "$miss" ]; then
    echo "  MISSING: $miss"
    echo "sheriff-review --probe: FAIL CLOSED - automation refused, review goes manual."
    exit 5
  fi
  echo "sheriff-review --probe: OK - automation available."
  echo "  Reminder: this proves the flags EXIST, not that they BEHAVE. After a version"
  echo "  bump also run: bash scripts/integration/sheriff-isolation-live.sh"
  exit 0
fi

[ -n "$AUTHOR" ] || die 2 "--author <vendor> is required (who wrote the diff)"

# ── 1. CROSS-VENDOR CHECK ──────────────────────────────────────────────────────
# Deliberately FIRST: it needs no filesystem and no CLI, so the guarantee stays
# testable on a machine with no codex installed.
#
# CLOSED SET, fail closed. An unrecognised identity is REFUSED, not assumed
# safe — a denylist of vendor spellings is an open-ended class, and this project
# has already paid for that once (CG 4.2.4: six rounds patching a similarity
# classifier, closed only by an exact finite schema). `ChatGPT`, `o3` and a bare
# model codename all named the sheriff's own vendor while matching no pattern.
# Adding a model family is one line here; guessing is never right.
a="$(printf '%s' "$AUTHOR" | tr '[:upper:]' '[:lower:]')"
case "$a" in
  claude|anthropic|opus*|sonnet*|haiku*|fable*)          AUTHOR_VENDOR="anthropic" ;;
  codex|openai|chatgpt|gpt*|o1*|o3*|o4*|sol*)            AUTHOR_VENDOR="openai" ;;
  gemini*|google|bard)                                   AUTHOR_VENDOR="google" ;;
  llama*|mistral*|qwen*|deepseek*|grok*|xai)             AUTHOR_VENDOR="other-oss" ;;
  human|owner|manual)                                    AUTHOR_VENDOR="human" ;;
  *)
    die 4 "REFUSED — unrecognised author identity '$AUTHOR'.
  The vendor cannot be determined, so cross-vendor independence cannot be proven, so
  the review does not run. This fails CLOSED on purpose: an unknown spelling that turns
  out to be the sheriff's own vendor is exactly the hole this check exists to close.
  Pass a known identity, or add the family to the closed set in this script." ;;
esac
if [ "$AUTHOR_VENDOR" = "$SHERIFF_VENDOR" ]; then
  die 4 "REFUSED — author '$AUTHOR' resolves to vendor '$AUTHOR_VENDOR', the same vendor as
  this sheriff ($SHERIFF_TOOL / $SHERIFF_VENDOR). A same-vendor review shares the author's
  blind spots, which is the one thing this mechanism exists to prevent. Use a
  different-vendor sheriff: see the role mapping in .agent/state/decisions.md and
  .claude/skills/cross-review/SKILL.md."
fi

# ── 2. PATH CONTAINMENT ────────────────────────────────────────────────────────
# The protected root is THIS SCRIPT'S OWN repository, never the caller's current
# directory. Deriving it from `git rev-parse` in $PWD would mean that invoking the
# wrapper by absolute path from outside the repo silently protects the wrong tree —
# and then a findings path pointed straight at a tracked file would be accepted.
# Both sides are normalised through `cd … && pwd -P` so they share one spelling
# convention. Comparing a `D:/…` string against a `/d/…` string would silently never
# match — the same mixed-path-spelling trap Context Guard hit with the /tmp mapping.
SELF_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" \
  || die 2 "cannot locate this script — refusing to guess the protected root"
REPO_ROOT="$(cd "$SELF_DIR" && git rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$REPO_ROOT" ]; then
  REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
else
  # Not a git checkout (a transplanted tree, or a test sandbox): fall back to the
  # parent of scripts/. Deterministic, still independent of $PWD. Never empty —
  # an empty protected root would disable containment entirely.
  REPO_ROOT="$(cd "$SELF_DIR/.." && pwd -P)"
fi
[ -n "$REPO_ROOT" ] || die 2 "cannot establish the protected root — refusing to run unprotected"

lower(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

abspath(){ # resolve a path that need not exist yet
  local d b
  # An existing directory resolves fully, symlinks included.
  if [ -d "$1" ]; then (cd "$1" && pwd -P); return; fi
  d="$(dirname -- "$1")"; b="$(basename -- "$1")"
  [ -d "$d" ] || return 1
  printf '%s/%s' "$(cd "$d" && pwd -P)" "$b"
}

refuse_if_in_repo(){ # $1 = label, $2 = path
  local abs lr lp
  # A symlink final component defeats parent-only resolution: the parent can sit
  # safely outside the repo while the link itself targets a tracked file, and the
  # CLI's -o write follows it. Containment cannot be proven, so refuse.
  if [ -L "$2" ]; then
    die 3 "REFUSED — the $1 path is a symlink ($2).
  Its target cannot be contained reliably, and the reviewer's output write follows it.
  Use a real path inside an isolated scratch directory."
  fi
  abs="$(abspath "$2")" || die 3 "REFUSED — $1 path has no existing parent directory: $2"
  [ -n "$REPO_ROOT" ] || return 0
  lr="$(lower "$REPO_ROOT")"; lp="$(lower "$abs")"
  if [ "$lp" = "$lr" ] || case "$lp/" in "$lr"/*) true;; *) false;; esac; then
    die 3 "REFUSED — the $1 path resolves INSIDE the repo root.
  path: $abs
  repo: $REPO_ROOT
  A read-only sandbox constrains the MODEL's tools, not this CLI's own -o write, so a
  findings path inside the repo is a write primitive for reviewer-controlled text.
  Leave the path unset to use an isolated scratch directory."
  fi
}

precheck_target(){ # $1 = label, $2 = path — refuse an existing target, create nothing
  if [ -e "$2" ] || [ -L "$2" ]; then
    die 3 "REFUSED — the $1 path already exists: $2
  This wrapper only writes targets it creates itself. An existing target may be a hard
  link or symlink to a tracked file (containment resolves paths, not inodes), or a file
  pre-planted for the reviewer's output. Point --$1 at a path that does not exist yet,
  or leave it unset to use an isolated scratch directory."
  fi
}


same_file(){ # $1, $2 — do these two paths denote one file?
  # A package that is ALSO the findings path hands the reviewer one file as both stdin
  # and -o, so its output overwrites the package it is meant to read. Neither path
  # exists at this point, so an inode comparison cannot see it — compare the resolved
  # names, case-folded like the containment check, which also catches the identical
  # spelling and a ./ variant of it.
  [ "$(lower "$(abspath "$1" 2>/dev/null || printf '%s' "$1")")"     = "$(lower "$(abspath "$2" 2>/dev/null || printf '%s' "$2")")" ]
}

if [ -z "$SCRATCH" ]; then
  SCRATCH="$(mktemp -d 2>/dev/null)" || die 2 "cannot create a scratch directory"
  CLEAN_SCRATCH=1
else
  mkdir -p "$SCRATCH" 2>/dev/null || die 2 "cannot create --scratch dir: $SCRATCH"
  CLEAN_SCRATCH=0
fi
refuse_if_in_repo "scratch" "$SCRATCH"
# Round 8 (2026-08-31) — closes sheriff round-7 findings [1] and [2]. The CANONICAL
# package and findings files live HERE, in a directory mktemp -d creates 0700 and only
# this user can enter. A caller-supplied --package / --out is a copy-OUT destination,
# written through a descriptor this script opened with O_EXCL and never released.
# Consequence: no caller-controlled pathname is ever REOPENED for reading (finding [1]),
# and the reviewer CLI never opens a caller-controlled pathname at all (finding [2]).
# Both windows close without taking the destination away from the caller.
# --scratch cannot serve this purpose: it is caller-supplied, so its mode and its
# parent directory are outside our control. This one is not.
PRIV="$(mktemp -d 2>/dev/null)" || die 2 "cannot create the private working directory"
refuse_if_in_repo "internal" "$PRIV"
PRIV_PKG="$PRIV/package.txt"
PRIV_OUT="$PRIV/findings.txt"
# find -delete rather than rm -rf: same effect, and it is the idiom the rest of this
# mechanism already uses. Runs on every exit path, including the die 3/5/6 refusals.
trap 'find "$PRIV" -mindepth 0 -delete 2>/dev/null' EXIT
[ -n "$PKG" ] && refuse_if_in_repo "package" "$PKG"
[ -n "$OUT" ] && refuse_if_in_repo "findings" "$OUT"
[ -n "$PKG" ] || PKG="$SCRATCH/sheriff-package.txt"
[ -n "$OUT" ] || OUT="$SCRATCH/sheriff-findings.txt"
# After the defaults, so a REUSED --scratch dir cannot silently overwrite the package
# or findings of the review that ran there before.
if same_file "$PKG" "$OUT"; then
  die 3 "REFUSED — the package and findings paths are the same file:
  package:  $PKG
  findings: $OUT
  The reviewer would receive it as both stdin and -o, so its output would overwrite the
  package it is meant to read. Give them different paths, or leave both unset."
fi
# The package is reserved by OPENING it: round 6c, from the sheriff's second pass. A
# reserve-then-reopen (`>|`) hands the pathname back to the filesystem in between, so
# the swap this rule exists to stop was simply moved one step later. Holding the
# exclusively-created descriptor and writing through it removes the reopen entirely --
# there is no window on the package write at all.
precheck_target "package" "$PKG"
set -C
# NO redirection may ride along on this line. `exec` with redirections and no command
# rewires the SHELL, permanently: an `exec 9> ... 2>/dev/null` here sent every later
# refusal message to /dev/null and turned a fail-closed refusal into a silent one.
# Caught by test-hooks ("refusal did not name --ephemeral"), 2026-08-31.
exec 9> "$PKG" || { set +C; die 3 "REFUSED — the package path already exists, or could not be exclusively created: $PKG
  This wrapper only writes targets it creates itself. An existing target may be a hard
  link or symlink to a tracked file (containment resolves paths, not inodes), or a file
  pre-planted for the package. Point --package at a path that does not exist yet, or
  leave it unset to use an isolated scratch directory."; }
set +C
# Round 8: the findings path now closes exactly like the package, and the honest limit
# round 6 had to state here is gone. The reviewer CLI writes to $PRIV_OUT inside the
# 0700 directory above; the result is copied OUT through this descriptor, opened with
# O_EXCL and held until the copy. The CLI never opens $OUT, so there is no longer a
# create->open window for anything to be swapped into.
precheck_target "findings" "$OUT"
set -C
# Same rule as fd 9 above: NO redirection may ride along on this exec line.
exec 8> "$OUT" || { set +C; die 3 "REFUSED — the findings path already exists, or could not be exclusively created: $OUT
  This wrapper only writes targets it creates itself. An existing target may be a hard
  link or symlink to a tracked file (containment resolves paths, not inodes), or a file
  pre-planted for the reviewer's output. Point --out at a path that does not exist yet,
  or leave it unset to use an isolated scratch directory."; }
set +C

# The reviewer's working root: EMPTY, outside the repo. This is the boundary that
# actually stops project-context loading — a read-only sandbox does not, it still
# permits reads.
WORKDIR="$SCRATCH/empty-workroot"
mkdir -p "$WORKDIR" || die 2 "cannot create the isolated work root"

# ── 3. ASSEMBLE THE PACKAGE ────────────────────────────────────────────────────
# stdin carries the acceptance criteria + the diff. The canonical prompt is
# prepended HERE so it can never be dropped, and so the automatic and the manual
# path send byte-identical content.
PROMPT_FILE="${REPO_ROOT:-.}/.claude/skills/cross-review/prompts/sheriff-review.md"
{
  if [ -f "$PROMPT_FILE" ]; then
    awk '/^```$/{n++; next} n==1' "$PROMPT_FILE"
  else
    echo "You are SHERIFF, an independent code reviewer. Analyze the diff below."
    echo "Report ONLY functional bugs, logic errors, security issues, data loss or"
    echo "corruption, performance problems with real impact. Critical/high only."
    echo "Max 5 findings, most severe first, numbered [1]-[5]. Write no code, ask no"
    echo "questions. If nothing qualifies, reply exactly: No critical/high findings."
  fi
  echo
  cat
} > "$PRIV_PKG" || die 2 "cannot write the review package"
# Round 8: the canonical package is $PRIV_PKG. $PKG is only ever WRITTEN, and only
# through the O_EXCL descriptor opened above — it is never reopened by name, which is
# what round-7 finding [1] was about. Everything that READS the package (the reviewer
# on stdin, emit_manual_package) reads $PRIV_PKG instead.
cat "$PRIV_PKG" >&9 || die 2 "cannot write the review package to $PKG"
exec 9>&-

emit_manual_package(){
  echo
  echo "════════ MANUAL SHERIFF PACKAGE — paste to a different-vendor reviewer ════════"
  cat "$PRIV_PKG"
  echo "══════════════════════════════ end of package ═══════════════════════════════"
  echo "(also saved at: $PKG)"
  echo "sheriff-review: the REVIEW is not optional — only its automation is gated." >&2
  echo "  Do not proceed to the gate until the findings come back and are answered." >&2
}

# ── 4. CAPABILITY PROBE ────────────────────────────────────────────────────────
# WHAT THIS PROVES: that a flag EXISTS in this CLI build. It does NOT prove the flag
# BEHAVES — that the sandbox really blocks writes, or that --cd really prevents
# project-context loading. Behavioural proof is a live run, deliberately out of the
# gate: scripts/integration/sheriff-isolation-live.sh
if ! command -v "$SHERIFF_TOOL" >/dev/null 2>&1; then
  echo "sheriff-review: REFUSED — the $SHERIFF_TOOL CLI is not on PATH; automation unavailable." >&2
  emit_manual_package; exit 6
fi
HELP="$("$SHERIFF_TOOL" exec --help 2>&1 8>&- 9>&-)"
missing=""
for f in $REQUIRED_FLAGS; do
  has_flag "$HELP" "$f" || missing="$missing $f"
done
if [ -n "$missing" ]; then
  echo "sheriff-review: REFUSED — this $SHERIFF_TOOL build lacks required isolation flag(s):$missing" >&2
  echo "  Automation is FAIL-CLOSED: without them the isolation cannot be constructed," >&2
  echo "  and a review that merely looks isolated is worse than one known not to be." >&2
  emit_manual_package; exit 5
fi
EXTRA=""
for f in $HARDENING_FLAGS; do
  if has_flag "$HELP" "$f"; then
    EXTRA="$EXTRA $f"
  else
    echo "sheriff-review: WARNING — hardening flag $f absent; proceeding without it." >&2
  fi
done

# ── 5. RUN ─────────────────────────────────────────────────────────────────────
if [ "$DRY" = "1" ]; then
  echo "DRY RUN — would execute:"
  echo "$SHERIFF_TOOL exec -s read-only --ephemeral -C $WORKDIR --skip-git-repo-check$EXTRA -o $PRIV_OUT - < $PRIV_PKG 8>&- 9>&-"
  echo "  (then: findings copied to $OUT through a held O_EXCL descriptor)"
  echo "$OUT"
  exit 0
fi
# shellcheck disable=SC2086
# --ephemeral is literal here, beside the other required caps: round 6 promoted it out
# of $EXTRA, and a cap the probe REQUIRES but the run never passes is the round-5 defect
# (probe validating something the review does not do). test-hooks asserts it in the argv.
# 8>&- 9>&- : round-8 finding [1], and the reason it is on EVERY invocation of the
# CLI rather than only this one. fd 8 is a writable descriptor on the caller's --out,
# held open from its own O_EXCL creation until the copy-out below. A child inherits
# it, and an inherited descriptor is a write primitive that no pathname rule and no
# `-s read-only` can take back: /dev/fd/8 reaches the inode directly, bypassing the
# private-directory boundary this round exists to build. Closing it for the child
# costs nothing. fd 9 is already closed here; naming it too means a later edit that
# moves the package write cannot reopen the same hole in silence.
"$SHERIFF_TOOL" exec -s read-only --ephemeral -C "$WORKDIR" --skip-git-repo-check $EXTRA -o "$PRIV_OUT" - < "$PRIV_PKG" 8>&- 9>&-
rc=$?
if [ $rc -ne 0 ] || [ ! -s "$PRIV_OUT" ]; then
  echo "sheriff-review: the $SHERIFF_TOOL invocation failed (rc=$rc) or produced no findings." >&2
  emit_manual_package
  exit 1
fi
# The reviewer wrote inside our 0700 directory; publish it to the caller's path through
# the descriptor we have held since we created it. Nothing could be swapped in between.
cat "$PRIV_OUT" >&8 || die 2 "cannot write the findings to $OUT"
exec 8>&-
[ "${CLEAN_SCRATCH:-0}" = "1" ] && echo "sheriff-review: scratch kept for the record at $SCRATCH" >&2
echo "$OUT"
