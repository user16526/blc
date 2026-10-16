#!/usr/bin/env bash
# Quality gate: a non-trivial task cannot be "done" until this passes.
# Run from project root:  ./scripts/quality-gate.sh [--trivial]
# Exit 0 = GREEN (all required checks pass). Exit 1 = blocked (see messages).
# It runs a check ONLY if the relevant command/state exists — never invents one.
#
# ADDING A PROJECT-LOCAL BLOCK — the convention (v8.3.25). This file ships with the
# template, so every copy of it also runs where YOUR project's tree does not exist: the
# hook suite's mktemp sandbox, another project's clone, a bare template tree. A local
# block that fail-closes on a project file (a guard script, a fixture index) BLOCKS
# every such run — and a suite whose expected-BLOCK assertions all pass because
# everything blocks is a suite that proves nothing (field project B, 2026-09-09: five
# accept-path assertions RED, every expected-BLOCK assertion passing vacuously). So:
#   1. FIRST test a marker path that proves this is the real project — a directory
#      only your project has (e.g. `[ -d src/<YourApp>.Core ]`), resolved against
#      `git rev-parse --show-toplevel` as well as the cwd; never the file the check
#      itself needs, whose absence is the check's own failure condition;
#   2. only inside that branch apply the fail-closed check — a missing guard there is
#      a `bad`, never a skip;
#   3. outside it, ANNOUNCE the skip with `note` — a skip nobody can see reads as a pass.
# Honest limit: the marker makes a skipped guard visible, it does not enforce it —
# renaming the marker switches the block off. A committed opt-in file owned by the
# guard would make "the guard is off" a reviewable diff; that shape is deferred (owner
# ruling, 2026-09-10): it needs a new file plus a rewrite of every project's local block,
# while the marker convention already closes the defect that was actually observed.
set -uo pipefail

TRIVIAL=0
[ "${1:-}" = "--trivial" ] && TRIVIAL=1
fail=0
note() { echo "  $1"; }
bad()  { echo "✗ $1"; fail=1; }
ok()   { echo "✓ $1"; }

# 0) self-location (v8.3.27, BACKLOG #24): this script gates the tree it lives in. Run
#    from another project's root it would mix trees — that project's git state against
#    this tree's roster and CORE — and certify something nobody built (field, 2026-09-15).
#    This script's parent must BE the cwd: every read below is relative to the cwd
#    (AGENTS.md, _reports/, package.json, the CORE hash), so a gate run from any other
#    directory — another project, or a subdirectory of its own — reads one tree's files
#    against another's git state (security re-check). A project that is a directory
#    inside a larger repository gates from its own root, like any other. `-ef` compares
#    the directory, not the spelling (`pwd -P` on both sides).
here="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -P)"
cwd="$(pwd -P)"
if [ -z "$here" ] || [ ! "$here" -ef "$cwd" ]; then
  echo "✗ never mix trees: this gate lives in $here but the cwd is $cwd — run the gate from its own project root: cd $here && ./scripts/quality-gate.sh"
  echo "GATE: BLOCKED 🔴 — wrong tree. Task is NOT done."; exit 1
fi

echo "── quality gate ──"

# 1) working tree MUST be clean — proof binds to a commit, so any uncommitted
#    change after verification invalidates the proof. Sole exemption:
#    _reports/runs/latest.json (gitignored machine state, written AFTER the
#    commit it points to — it can never be clean by definition).
if git rev-parse --git-dir >/dev/null 2>&1; then
  dirty="$(git status --porcelain | grep -v '_reports/runs/latest\.json$' || true)"
  if [ -z "$dirty" ]; then ok "git clean (exemption: _reports/runs/latest.json)"
  else
    bad "working tree DIRTY — commit (or stash) before claiming done; changes made after verification are UNVERIFIED:"
    echo "$dirty" | sed 's/^/    /'
  fi
  echo "  HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo none)"
else
  note "no git repo yet"
fi

# 2) no .env staged
if git rev-parse --git-dir >/dev/null 2>&1; then
  # The list is read whole: a `grep -q` mid-pipe exits early, and under pipefail the writer's
  # SIGPIPE read as "none staged" (v8.3.32, #113 L1).
  staged_env="$(git diff --cached --name-only 2>/dev/null | grep -E '(^|/)\.env($|\.)' | grep -v '\.env\.example' || true)"
  if [ -n "$staged_env" ]; then
    bad ".env is staged — unstage it"
  else ok "no real .env staged"; fi
fi

# 3) no obvious secrets in staged diff
if git rev-parse --git-dir >/dev/null 2>&1; then
  . "$(dirname "$0")/secret-patterns.sh" 2>/dev/null || SECRET_REGEX='(sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
  # read once, then a here-string: under pipefail an early `grep -q` exit could read as "no match".
  # A failed `git diff` is a failed check, never "no secrets" (sheriff, v8.3.30).
  if ! qg_staged="$(git diff --cached -U0 2>/dev/null)"; then
    bad "staged-secret scan did not run: git diff --cached failed"
  elif grep -Eq "^\+.*$SECRET_REGEX" <<< "$qg_staged"; then
    bad "possible secret in staged changes"
  else ok "no obvious secrets staged"; fi
fi

# helper: run a script from package.json or a known tool, only if it exists.
# Each step writes its OWN log in a per-run folder (v8.3.25). All of them used to share
# one fixed /tmp/qg.out, so the NEXT step overwrote a failing step's output before anyone
# could read it (a one-off test failure could not be root-caused for exactly that
# reason), and two gates running at once raced on the same file. The folder is removed
# on GREEN and kept on BLOCKED — the evidence outlives the run that needs it.
qg_logs="$(mktemp -d "${TMPDIR:-/tmp}/qg.XXXXXX" 2>/dev/null)" \
  || { bad "cannot create a temp folder for the step logs — step output is not kept"; qg_logs=""; }
run_if() { # $1 = label, $2.. = command
  local label="$1"; shift
  checks_run=$((checks_run+1))
  local log=/dev/null
  # The log is keyed by the STEP (first word of the label), never by the label text: a
  # label may carry a command line, and a command line may carry a token (re-check).
  [ -n "$qg_logs" ] && log="$qg_logs/${label%% *}.log"
  if "$@" >"$log" 2>&1; then ok "$label passed"; else bad "$label FAILED (log: $log)"; fi
}
has_npm_script() { [ -f package.json ] && grep -q "\"$1\"" package.json; }
any_file() { for f in "$@"; do [ -e "$f" ] && return 0; done; return 1; }   # unmatched globs stay literal
# HTML comments out, multi-line ones included: a `- Test:` line commented out across
# several lines is invisible in the rendered file, so it must be invisible to the gate too.
STRIP_HTML_COMMENTS='{ out = ""; s = $0
  while (s != "") {
    if (inc) { i = index(s, "-->"); if (!i) { s = ""; break }; s = substr(s, i + 3); inc = 0; continue }
    i = index(s, "<!--"); if (!i) { out = out s; s = ""; break }
    out = out substr(s, 1, i - 1); s = substr(s, i + 4); inc = 1 }
  print out }'
# The owner's own command from AGENTS.md MY COMMANDS (`- Test: …`): the line's raw value.
my_cmd_value() { # $1 = Test|Build|Lint; the markdown on stdin
  tr -d '\r' | awk "$STRIP_HTML_COMMENTS" | sed -n '/^## MY COMMANDS/,/^## /p' \
    | grep -m1 -iE "^- ${1}:" | sed -E 's/^- [^:]*:[[:space:]]*//; s/[[:space:]]+$//'
}
# Line format (v8.3.28, #29). Empty, a `<placeholder>`, or a value that STARTS with the word
# none / n/a / tbd / todo or a dash = no command (auto-detection runs, and the gate says so);
# the word may sit in `(…)` or `*…*` and carry punctuation (`(none)`, `N/A.`, `TODO: …`), but
# `todo_lint.sh` or `todo.sh` is a command.
# A value that starts with a backtick pair = that pair's content; backticks anywhere else,
# or an empty/unpaired pair = AMBIGUOUS (exit 3) and the step BLOCKS: guessing which part is
# the command let `false  # run with \`CI=1\`` run `CI=1` and pass (security review). Only
# exact `n/a` used to count as no command; the field had `none yet` run as shell.
MYCMD_NONE='^[(*_]*((n/?a|none|tbd|todo)([^A-Za-z0-9_./-]|[.]([^A-Za-z0-9_/-]|$)|$)|-|—|–)'
my_cmd_parse() { # the value on stdin -> the command on stdout, nothing = no command
  local v; IFS= read -r v; [ -n "$v" ] || return 0
  printf '%s\n' "$v" | grep -qiE "$MYCMD_NONE" && return 0
  case "$v" in '<'*) return 0 ;; esac
  case "$v" in
    '`'*) v="$(printf '%s\n' "$v" | sed -nE 's/^`([^`]+)`.*$/\1/p')"; [ -n "${v//[[:space:]]/}" ] || return 3 ;;
    *'`'*) return 3 ;;
  esac
  printf '%s\n' "$v" | grep -qiE "$MYCMD_NONE" && return 0
  printf '%s\n' "$v"
}

# 4/5/6 — lint, test, build. Auto-detect the stack; run a check only if it exists.
# Order of preference (v8.3.27, #10): AGENTS.md MY COMMANDS → npm script → Makefile
# target → justfile → by FILE TYPE → docker. A `tests/` directory alone selects nothing:
# it used to select pytest, so a node project with tests/*.test.mjs got a RED test step
# it could not pass (field, first /run-spec polygon run, 2026-09-14).
. "$(dirname "$0")/secret-patterns.sh" 2>/dev/null || SECRET_REGEX='(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
# Secret-shaped text out of anything the gate prints. sed delimiter = \001 (v8.3.28, #26):
# a project SECRET_REGEX holding a `/` ended the `s/…/` early and crashed the gate (field,
# 2026-09-17); \001 and newlines are removed from the regex first, so it can never close
# the s-command and append one of its own (sheriff).
redact() { local re="${SECRET_REGEX//[$'\001'$'\n']/}"
  printf '%s' "$1" | sed -E "s"$'\001'"$re"$'\001'"<redacted>"$'\001'"g"; }
gate_step() { # $1 = step name (lint|test|build)
  local step="$1" raw cmd prc
  # The MY COMMANDS line runs through `bash -c`, so it is shown in the output (it lands in
  # the run report) with secret-shaped text redacted, and it is read from the COMMITTED
  # blob only (HEAD must hold a regular file): a working-tree edit, an assume-unchanged or
  # skip-worktree flag, a symlink or an untracked file must not put an unreviewed string
  # into `bash -c` (security review + re-check + sheriff, v8.3.27). Untracked: ignored,
  # visibly; edited: the committed line counts and the edit is named.
  if git ls-tree HEAD ./AGENTS.md 2>/dev/null | grep -q '^100[67][0-9][0-9] blob '; then
    raw="$(git show HEAD:./AGENTS.md 2>/dev/null | my_cmd_value "$step")"
    cmd="$(printf '%s\n' "$raw" | my_cmd_parse)"; prc=$?
    [ -f AGENTS.md ] && [ "$(my_cmd_value "$step" < AGENTS.md)" != "$raw" ] \
      && note "MY COMMANDS ${step}: the working AGENTS.md differs from HEAD — the committed line counts"
    if [ "$prc" -eq 3 ]; then
      bad "MY COMMANDS ${step}: ambiguous line '$(redact "$raw")' — put the command first, bare or in one pair of backticks, notes after it"; return
    fi
    if [ -n "$cmd" ]; then run_if "$step (AGENTS.md MY COMMANDS: $(redact "$cmd"))" bash -c "$cmd"; return; fi
    [ -n "$raw" ] && note "MY COMMANDS ${step}: '$(redact "$raw")' reads as no command — auto-detection runs"
  elif [ -f AGENTS.md ] && [ -n "$(my_cmd_value "$step" < AGENTS.md)" ]; then
    note "MY COMMANDS ${step} ignored: AGENTS.md is not a committed, regular, tracked file"
  fi
  if has_npm_script "$step"; then run_if "$step (npm)" npm run -s "$step" 2>/dev/null || run_if "$step (npm)" npm "$step" --silent; return; fi
  if [ -f Makefile ] && grep -q "^${step}:" Makefile; then run_if "$step (make)" make "$step"; return; fi
  if [ -f justfile ] && grep -q "^${step}" justfile; then run_if "$step (just)" just "$step"; return; fi
  case "$step" in
    test)
      if [ -f pyproject.toml ] || any_file tests/test_*.py tests/*_test.py test/test_*.py; then run_if "test (pytest)" python3 -m pytest -q; return; fi
      if any_file tests/*.test.mjs tests/*.test.js tests/*.test.cjs test/*.test.mjs test/*.test.js test/*.test.cjs; then run_if "test (node --test)" node --test; return; fi ;;
    lint)
      if [ -f pyproject.toml ] && command -v ruff >/dev/null 2>&1; then run_if "lint (ruff)" ruff check .; return; fi ;;
    build)
      if [ -f docker-compose.yml ] || [ -f compose.yml ]; then run_if "build (compose config)" docker compose config -q; return; fi ;;
  esac
  note "no $step command detected — skipped"
}
checks_run=0
orig_gate_step_marker=1
gate_step lint
gate_step test
gate_step build
if [ "$TRIVIAL" -eq 0 ] && [ "$checks_run" -eq 0 ]; then
  if [ "${QG_ALLOW_NO_CHECKS:-0}" = "1" ]; then
    note "no lint/test/build detected — allowed by QG_ALLOW_NO_CHECKS=1 (non-code project)"
  else
    bad "no lint/test/build commands detected for a NON-TRIVIAL task. Define them (package.json / Makefile / justfile), or run --trivial, or set QG_ALLOW_NO_CHECKS=1 for a genuinely non-code project"
  fi
fi

# 7) + 8) run report present & well-formed (skipped for trivial tasks)
if [ "$TRIVIAL" -eq 0 ]; then
  # WHICH report, and which verdict in it (v8.3.28, #40): the report latest.json names, and
  # in it the Verdict heading bound to latest.json's run_id. The newest file and its FIRST
  # Verdict heading used to win, so a /run-spec report — one file, a section appended per
  # step — was read at its oldest section: "report verdict: GREEN" printed while that
  # night's run was RED (field, 2026-09-20; only latest.json blocked it).
  run_id=""; latest=""
  if [ -f _reports/runs/latest.json ] && command -v python3 >/dev/null 2>&1; then
    IFS=$'\037' read -r run_id latest < <(python3 -c 'import json, sys
sys.stdout.reconfigure(encoding="utf-8")
d = json.load(open("_reports/runs/latest.json", encoding="utf-8"))
d = d if isinstance(d, dict) else {}
def f(k):   # exact, never normalised (sheriff: "run  02.md" must not become "run 02.md")
    v = d.get(k, "")
    v = v if isinstance(v, str) else str(v)
    return "\001INVALID" if any(ord(c) < 32 for c in v) else v
print(f("run_id") + "\037" + f("report"))' 2>/dev/null)
    latest="${latest%$'\r'}"   # Windows python ends the line with CR LF
    if [ "$run_id" = $'\001INVALID' ] || [ "$latest" = $'\001INVALID' ]; then
      bad "latest.json run_id/report holds a control character — write them as plain text"
      run_id=""; latest=$'\001INVALID'
    fi
  fi
  # The named report must be a COMMITTED file under _reports/runs/: a path outside the repo,
  # a `..` path or a gitignored file would let an unreviewed GREEN stand in for the real
  # report (security review: an absolute path to a GREEN file beat a committed RED report).
  # It is READ from HEAD too (sheriff): a skip-worktree working copy saying GREEN over a
  # committed RED, or a committed symlink pointing out of the repo, must not be the proof.
  # The object READ must be the regular file: `x/` or `x/.` resolve to a tree whose first
  # child is a blob, a symlink is a blob of mode 120000 (sheriff rounds 3-4).
  committed_file() { [ "$(git cat-file -t "HEAD:./$1" 2>/dev/null)" = blob ]     && git ls-tree HEAD -- "./$1" 2>/dev/null | grep -qE '^100(644|755) blob '; }
  rep_bad=0; rep_src=""
  if [ -n "$latest" ]; then
    case "$latest" in
      /*|*..*|*\\*|[A-Za-z]:*) rep_bad=1 ;;
      _reports/runs/*) committed_file "$latest" || rep_bad=2 ;;
      *) rep_bad=1 ;;
    esac
    [ "$rep_bad" -eq 1 ] && bad "latest.json report '$latest' must be a repo-relative path under _reports/runs/"
    [ "$rep_bad" -eq 2 ] && bad "latest.json report '$latest' is not a regular file committed in HEAD — commit the report before the proof"
    if [ "$rep_bad" -eq 0 ]; then
      rep_src="${qg_logs:+$qg_logs/run-report.md}"
      { [ -n "$rep_src" ] && git show "HEAD:./$latest" > "$rep_src" 2>/dev/null; } \
        || { rep_bad=3; bad "cannot read the committed report '$latest' from HEAD"; }
    fi
  else
    latest=$(ls -t _reports/runs/*.md 2>/dev/null | head -1); rep_src="$latest"   # pre-v8.3.28 behaviour
  fi
  if [ "$rep_bad" -ne 0 ]; then
    :
  elif [ -z "$latest" ]; then
    bad "no run report in _reports/runs/ for a non-trivial task"
  else
    ok "run report: $latest"
    for sec in Verdict Inputs Findings Artifacts; do
      grep -qi "$sec" "$rep_src" || bad "run report missing section: $sec"
    done
    # The VALUE of the verdict matters, not the word "Verdict" (field D2, 2026-09-01). Which
    # report and which section (#40): the report latest.json names; with several Verdict
    # headings only the one naming this run's run_id, none or several naming it BLOCK; one
    # heading naming ANOTHER run BLOCKS. v8.3.28 review rounds kept finding bypasses in a
    # lexical reader, so the report is read by a strict grammar that BLOCKS on anything it
    # cannot read one way.
    # THREAT MODEL (owner ruling, v8.3.29): HONEST MISTAKES — a stale section, another run's
    # heading, a corrected or struck value, the template's own comment. A report CRAFTED to
    # hide its verdict (raw HTML blocks, entities, headings inside lists or quotes) is out of
    # scope: the same author writes latest.json, and this is awk, not a Markdown renderer.
    # The grammar:
    #  - code is not prose: CommonMark fences (``` or ~~~, 3+, indent 0-3 or after a list
    #    marker; a backtick opener carries no other backtick; closed only by the same char,
    #    at least as long, alone on its line; unclosed BLOCKS) and 4-column-indented lines;
    #  - HTML comments as CommonMark renders them: a line STARTING with `<!--` (indent 0-3,
    #    outside code) hides everything up to the line holding `-->` — text after that `-->`
    #    BLOCKS; inside a line only a complete `<!-- … -->` is hidden, and a `<!--` left open
    #    there BLOCKS (a renderer hides the lines after it, a code span does not: v8.3.29);
    #  - a Verdict heading is any heading holding the word "verdict" ("## Final verdict" too);
    #    a setext one (a paragraph line underlined with --- or ===) BLOCKS — it would go
    #    uncounted; under a list item or a quote that --- is a rule, not an underline;
    #  - a heading names a run ONLY as `Verdict`, non-letters, `run <id>` — the id is the next
    #    word minus trailing `:),.;` and must EQUAL the run_id (no substring search);
    #  - the verdict is the first TOKEN ([A-Za-z0-9_-]+, so `green-S02` is not GREEN) of the
    #    heading after `Verdict` and its run, else of the first prose line after the heading
    #    (a leading word "Verdict" is skipped). Not GREEN/YELLOW/RED there → BLOCK: "Not GREEN"
    #    is not a verdict. That text naming a SECOND verdict word, hidden parts included
    #    (`~~GREEN~~ RED`, `GREEN → RED`), or striking anything out (`~~`), BLOCKS: the
    #    reader never picks one of two;
    #  - no Verdict heading: exactly one prose line starting with "Verdict" or carrying a
    #    "Verdict:" label, else BLOCK;
    #  - the run_id reaches awk through ENVIRON: awk escape-processes `-v` values.
    vawk() { QG_RID="$1" awk -v mode="$2" "$VAWK" "$rep_src"; }   # $1 = run_id, $2 = mode
    VAWK='BEGIN { rid = ENVIRON["QG_RID"] }
      function afterv(s,  t) {   # the text after the first whole word "verdict", else ""
        t = tolower(s); if (!match(t, /(^|[^a-z])verdict/)) return ""
        return substr(s, RSTART + RLENGTH) }
      function runof(s,  t) {   # the run a Verdict heading names (`Verdict`, non-letters, `run <id>`), else ""
        t = afterv(s); if (!match(tolower(t), /^[^a-z0-9]*run[ \t]+/)) return ""
        t = substr(t, RSTART + RLENGTH); sub(/[ \t].*$/, "", t); sub(/[:),.;]+$/, "", t); return t }
      function token(s) {   # the first token (a letter or digit, then [A-Za-z0-9_-]*), upper-cased; TREST = the rest
        if (!match(s, /[A-Za-z0-9][A-Za-z0-9_-]*/)) { TREST = ""; return "" }
        TREST = substr(s, RSTART + RLENGTH); return toupper(substr(s, RSTART, RLENGTH)) }
      function nverd(s,  w, g, y, x) {   # how many DIFFERENT verdict words s holds
        while ((w = token(s)) != "") { if (w == "GREEN") g = 1; else if (w == "YELLOW") y = 1; else if (w == "RED") x = 1; s = TREST }
        return g + y + x }
      function verdict_of(s, r,  w) {   # GREEN/YELLOW/RED if s STARTS with one (after a word "Verdict"), else "";
        w = token(s); if (w == "VERDICT") w = token(TREST)   # MANYV when r (s with its comments) names two
        if (w != "GREEN" && w != "YELLOW" && w != "RED") return ""
        return (nverd(r) > 1 || index(r, "~~")) ? "MANYV" : w }
      function after_heading(s,  t) {   # the heading after `verdict` and the run it names
        t = afterv(s); if (runof(s) != "") sub(/^[^A-Za-z0-9]*[Rr][Uu][Nn][ \t]+[^ \t]+/, "", t)
        return t }
      function inline(s,  i, j, o) {   # s without its complete one-line <!-- ... --> comments
        o = ""; while ((i = index(s, "<!--")) && (j = index(substr(s, i + 2), "-->"))) { o = o substr(s, 1, i - 1); s = substr(s, i + j + 4) }
        return o s }
      function rest(s) { if (inline(s) !~ /^[ \t]*$/) junk++ }   # text after a block comment closes
      function opener(s,  f) {
        if (!match(s, /^ ? ? ?(([-*+]|[0-9]+[.)])[ \t]+)?(```+|~~~+)/)) return ""
        f = substr(s, RSTART, RLENGTH); sub(/^[^`~]*/, "", f)
        if (substr(f, 1, 1) == "`" && index(substr(s, RSTART + RLENGTH), "`")) return ""
        return f }
      function closes(s,  c) {
        if (s !~ /^ ? ? ?(```+|~~~+)[ \t]*$/) return 0
        c = s; gsub(/[ \t]/, "", c)
        return substr(c, 1, 1) == substr(fence, 1, 1) && length(c) >= length(fence) }
      { raw = $0; sub(/\r$/, "", raw)   # a CRLF report: the CR is never text
        if (inc) { i = index(raw, "-->"); if (!i) next; inc = 0; rest(substr(raw, i + 3)); next }
        if (fence != "") { if (closes(raw)) fence = ""; pv = 0; next }
        if (raw ~ /^ ? ? ?<!--/) { i = index(raw, "<!--"); j = index(substr(raw, i + 2), "-->"); pv = 0
          if (j) rest(substr(raw, i + j + 4)); else inc = 1
          next }
        o = opener(raw); if (o != "") { fence = o; pv = 0; next }
        if (raw ~ /^(\t| \t|  \t|   \t|    )/) { pv = 0; next }
        line = inline(raw); if (index(line, "<!--")) junk++   # opens mid-line, closes on a later one
        if (pv && line ~ /^ ? ? ?(=+|-+)[ \t]*$/) sx++   # a setext underline under a line holding "verdict"
        pv = line !~ /^[ \t]*$/ && line !~ /^ ? ? ?(#|>|[-*+][ \t]|[0-9]+[.)][ \t])/ && tolower(line) ~ /(^|[^a-z])verdict([^a-z]|$)/ }
      want && line !~ /^[ \t]*$/ {   # read: the first prose line after the selected heading
        if (line ~ /^ ? ? ?#/) { print "NONE"; done = 1; exit }
        v = verdict_of(line, raw); print (v != "" ? v : "NONE"); done = 1; exit }
      line ~ /^ ? ? ?#/ && tolower(line) ~ /(^|[^a-z])verdict([^a-z]|$)/ {   # a heading holding the word "verdict"
        n++; if (runof(line) != "") r++; if (rid != "" && runof(line) == rid) m++
        if (mode == "read" && !want && (rid == "" || runof(line) == rid)) {
          v = verdict_of(after_heading(line), after_heading(raw)); if (v != "") { print v; done = 1; exit }
          want = 1 }
        next }
      mode == "fallback" && token(line) == "VERDICT" { k++; fv = verdict_of(line, afterv(raw)); next }
      mode == "fallback" && match(tolower(line), /(^|[^a-z])verdict[*_]*[ \t]*:/) { k++; fv = verdict_of(substr(line, RSTART + RLENGTH), afterv(raw)) }
      END {
        if (mode == "count") print (fence != "" ? -1 : sx ? -2 : junk ? -3 : n + 0)
        if (mode == "runs") print r + 0
        if (mode == "named") print m + 0
        if (mode == "read" && !done) print "NONE"
        if (mode == "fallback") print (k + 0) " " (fv != "" ? fv : "NONE") }'
    nv=$(vawk "" count); rid_use=""; vread=1
    if [ "$nv" -eq -1 ]; then
      vread=0; bad "run report has an unclosed code fence — everything after it is code, so no verdict can be read"
    elif [ "$nv" -eq -2 ]; then
      vread=0; bad "run report has a setext Verdict heading (a line holding 'Verdict' underlined with --- or ===) — write it as '## Verdict'"
    elif [ "$nv" -lt 0 ]; then
      vread=0; bad "run report has an HTML comment the gate cannot read one way (text after its '-->', or a '<!--' opened mid-line and not closed on that line) — put each comment on its own lines"
    elif [ "$nv" -gt 1 ]; then
      nm=0; [ -n "$run_id" ] && nm=$(vawk "$run_id" named)
      if [ "$nm" -eq 1 ]; then rid_use="$run_id"; note "report holds $nv Verdict headings — reading the one that names this run ($run_id)"
      else vread=0; bad "report holds $nv Verdict headings and $nm name this run's run_id (${run_id:-none in latest.json}) — write each run's heading as 'Verdict — run <run_id>', exactly once"; fi
    elif [ "$nv" -eq 1 ] && [ -n "$run_id" ] && [ "$(vawk "" runs)" -gt 0 ] && [ "$(vawk "$run_id" named)" -ne 1 ]; then
      # One heading that names a run (`### Verdict — run <id>`) must name THIS one: a step
      # that never appended its section must not pass on the previous step's (review F1).
      vread=0; bad "the report's only Verdict heading names another run, not this run_id ($run_id) — append this run's section"
    fi
    if [ "$vread" -eq 1 ]; then
      if [ "$nv" -gt 0 ]; then rv=$(vawk "$rid_use" read)
      else
        read -r nf rv < <(vawk "" fallback)
        [ "${nf:-0}" -gt 1 ] && rv="MANY"
      fi
      case "$rv" in
        GREEN) ok "report verdict: GREEN" ;;
        YELLOW|RED) bad "report verdict is $rv — the run itself says it is not done" ;;
        MANY) bad "report has no Verdict heading and several lines starting with 'Verdict' — add one '## Verdict' heading" ;;
        MANYV) bad "the report's verdict names more than one of GREEN/YELLOW/RED or strikes a value out (a corrected value, an arrow, ~~) — write only the final one" ;;
        *) bad "report has no parsable verdict value — the Verdict heading, or the first prose line under it, must START with GREEN/YELLOW/RED" ;;
      esac
    fi
    [ -n "$qg_logs" ] && rm -f "$qg_logs/run-report.md"   # the HEAD copy; never kept as evidence
    # machine-readable state: must exist AND match schema AND bind to THIS commit
    if [ ! -f _reports/runs/latest.json ]; then
      # Name the cause (v8.3.25): "no run yet" and "run state lost" look identical here.
      bad "missing _reports/runs/latest.json"
      note "  It is gitignored run state and never travels: a fresh clone or worktree has none"
      note "  until its first gated run writes it. If a run DID happen in this tree, its proof"
      note "  is lost — re-run the review; never hand-write the file. LOW work: --trivial."
    elif command -v python3 >/dev/null 2>&1; then
      head_now="$(git rev-parse HEAD 2>/dev/null || echo '')"
      if python3 - "$head_now" <<'PY'
import json, os, sys
head_now = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    # explicit UTF-8: a bare open() uses the platform codepage, and on Windows
    # one non-ASCII byte in a valid UTF-8 file reported "unreadable" (false RED)
    d = json.load(open("_reports/runs/latest.json", encoding="utf-8"))
except Exception as e:
    print(f"  latest.json unreadable: {e}"); sys.exit(1)
errs = []
if not isinstance(d, dict) or not d:
    errs.append("latest.json is empty — the orchestrator never wrote real run state")
else:
    v = str(d.get("verdict", "")).upper()
    if v != "GREEN":
        errs.append(f"latest.json verdict is '{d.get('verdict','<missing>')}' — gate requires GREEN")
    for k in ("run_id", "timestamp"):
        if not str(d.get(k, "")).strip():
            errs.append(f"latest.json missing '{k}'")
    rep = str(d.get("report", "")).strip()
    if not rep:
        errs.append("latest.json missing 'report' (path to the run report .md)")
    elif not os.path.isfile(rep):
        errs.append(f"latest.json points to a report that does not exist: {rep}")
    sha = str(d.get("head_sha", "")).strip()
    if head_now and sha and not head_now.startswith(sha) and not sha.startswith(head_now[:7]):
        errs.append(f"latest.json head_sha ({sha[:12]}) != current HEAD ({head_now[:12]}) — stale run state")
    elif head_now and not sha:
        errs.append("latest.json missing 'head_sha' — cannot bind the proof to this commit")
    # F2 (v8.3.23): a NORMAL+ run must carry an INDEPENDENT review — the kernel's
    # "verifier at the end" was a hope, not a hook: field project A shipped ~19 of 20
    # NORMAL+ runs in one week with no reviewer but the builder itself. Fields:
    #   row       LOW | NORMAL | HIGH | DESTRUCTIVE   (default NORMAL; LOW runs use --trivial)
    #   builder   the agent/role that produced the change (e.g. block-executor, devops-operator)
    #   reviewers non-empty list; each entry starts with the agent name; none may be the builder
    #   risks     touched risks; HIGH+ needs one DISTINCT reviewer per listed risk
    import re as _re, glob as _glob
    # The ACTIVE roster: an agent on leave (.claude/agents/_archive/) is not a reviewer.
    # An EMPTY roster blocks (SHERIFF [1], v8.3.23): the template ships agents, so no
    # roster means the team was never created or was archived wholesale — either way
    # there is nobody who could have reviewed, and a shape-only fallback let invented
    # names through.
    ROSTER = sorted({os.path.splitext(os.path.basename(f))[0].lower()
                     for f in _glob.glob(".claude/agents/*.md")}, key=len, reverse=True)
    def _slug(x):
        # canonical form: "Block Executor (self)" -> "block-executor"; a bullet prefix
        # is tolerated; spaces/underscores are hyphens (functional-verifier ADV-1:
        # "block executor" vs "block-executor" used to pass as two different agents)
        x = str(x).strip().lstrip("-*•").strip().lower()
        for sep in ("(", ":", ",", ";"):
            x = x.split(sep, 1)[0]
        return _re.sub(r"[\s_]+", "-", x.strip()).strip("-")
    def _name(x):
        s_ = _slug(x)
        for a in ROSTER:                      # longest roster name first
            if s_ == a or s_.startswith(a + "-"):
                return a
        return s_
    AGENT_RE = _re.compile(r"[a-z][a-z0-9-]{2,}")
    row = str(d.get("row", "NORMAL")).strip().upper() or "NORMAL"
    if row not in ("LOW", "NORMAL", "HIGH", "DESTRUCTIVE"):
        errs.append(f"latest.json row '{d.get('row')}' is not LOW/NORMAL/HIGH/DESTRUCTIVE")
    raw_builder = d.get("builder", "")
    if not isinstance(raw_builder, str):
        # functional-verifier F-1 (v8.3.23): a list/dict builder str()'d to a token that
        # matched no reviewer, so the builder reviewing itself passed as "independent"
        errs.append(f"latest.json 'builder' must be a string (the agent/role name), got {type(raw_builder).__name__}")
        raw_builder = ""
    builder = _name(raw_builder) if raw_builder else ""
    if isinstance(d.get("builder", ""), str) and not builder:
        errs.append("latest.json missing 'builder' — name the agent/role that built this, so the gate can check the review is independent")
    # v8.3.25 (field project B's first gated run): reviewers were resolved against the
    # roster but the builder never was, so a run built by an agent the project keeps in
    # _archive/ was certified as long as its reviewers were real. Same roster rule now.
    # One extra name is allowed: 'orchestrator', the main session, which legitimately builds.
    if builder and row != "LOW":
        if builder in ("self", "me", "none", "n/a", "-"):
            errs.append(f"builder '{raw_builder}' is not an agent — name who built it (a roster agent, or 'orchestrator' for the main session)")
        elif ROSTER and builder != "orchestrator" and builder not in ROSTER:
            errs.append(f"builder '{raw_builder}' is not an active agent in .claude/agents/ (invented names and agents on leave do not count; the main session is 'orchestrator')")
    reviewers = d.get("reviewers", [])
    if isinstance(reviewers, list) and any(not isinstance(r, str) for r in reviewers):
        errs.append("latest.json 'reviewers' entries must be strings ('verifier', not an object or number)")
    raw_reviewers = [r for r in reviewers if isinstance(r, str) and r.strip()] if isinstance(reviewers, list) else []
    names = [_name(r) for r in raw_reviewers]
    if row == "LOW":
        # this block only runs WITHOUT --trivial; a LOW task uses --trivial. Declaring LOW
        # here would be the cheapest escape from F2 (functional-verifier r3), so it blocks.
        errs.append("row LOW but the gate ran without --trivial — a LOW task uses ./scripts/quality-gate.sh --trivial; if this run needs a report it is not LOW")
    elif not names:
        errs.append(f"{row} run has no independent review: latest.json 'reviewers' is empty (self-review is not a review)")
    else:
        notname = [r for r, n in zip(raw_reviewers, names) if not AGENT_RE.fullmatch(n)]
        if notname:
            errs.append(f"reviewer '{notname[0]}' does not start with an agent name (e.g. 'verifier', 'security-reviewer (…)')")
        same = [n for n in names if builder and n == builder]
        if same:
            errs.append(f"reviewer '{same[0]}' is the builder — a builder cannot review its own work")
        fake = [n for n in names if n in ("orchestrator", "self", "me", "none", "n/a", "-")]
        if fake:
            errs.append(f"reviewer '{fake[0]}' is not an independent agent")
        if not ROSTER:
            errs.append("no active agents in .claude/agents/ — nobody could have reviewed this; create the team (team-proposal) or re-activate a role from _archive/")
        else:
            unknown = [r for r, n in zip(raw_reviewers, names) if n not in ROSTER]
            if unknown:
                errs.append(f"reviewer '{unknown[0]}' is not an active agent in .claude/agents/ (invented names and agents on leave do not count)")
        if row in ("HIGH", "DESTRUCTIVE"):
            risks = d.get("risks", [])
            risks = sorted({r.strip().lower() for r in risks if isinstance(r, str) and r.strip()}) if isinstance(risks, list) else []
            if not risks:
                errs.append(f"{row} run must list the touched 'risks' in latest.json")
            elif len(set(names)) < len(risks):
                errs.append(f"{row} run touches {len(risks)} risk(s) ({', '.join(risks)}) but names {len(set(names))} distinct reviewer(s) — one independent reviewer per risk")
for e in errs:
    print(f"  {e}")
sys.exit(1 if errs else 0)
PY
      then ok "latest.json schema + verdict GREEN + bound to HEAD + independent review (F2)"
      else bad "latest.json failed validation (see lines above)"; fi
      # 8b) spec lint (v8.3.28, #35 D) — the spec latest.json names, when it is written in
      #     spec format 2: every step has a Kind; a `choice` step has a research brief with
      #     a recommendation, evidence, a falsifier and a confidence; at most 2 choices.
      #     A spec without `Spec format: 2` predates the lint and is named, not failed.
      #     Spec and briefs are read from HEAD (the proof binds to a commit) and must be
      #     repo-relative; a lint that crashes or says nothing BLOCKS (security review).
      lint_done=0
      while IFS= read -r l; do
        l="${l%$'\r'}"
        case "$l" in
          BAD\ *) bad "spec lint: ${l#BAD }" ;;
          WARN\ *) note "spec lint WARN: ${l#WARN }" ;;
          OK\ *) ok "spec lint: ${l#OK }" ;;
          NONE) : ;;
          LINT-END) lint_done=1 ;;
          *) note "$l" ;;
        esac
      done < <(python3 - <<'PY' 2>&1
import json, os, re, subprocess, sys
sys.stdout.reconfigure(encoding="utf-8")          # non-ASCII messages; Windows default is cp1252

def committed(path):
    """Text of a repo-relative path as committed in HEAD, or None."""
    p = path                          # exact: a backslash is refused, never rewritten
    if not p or "\\" in p or any(ord(c) < 32 for c in p) or p.startswith("/") or re.match(r"^[A-Za-z]:", p) or ".." in p.split("/"):
        return None
    t = subprocess.run(["git", "ls-tree", "HEAD", "./" + p], capture_output=True)
    k = subprocess.run(["git", "cat-file", "-t", "HEAD:./" + p], capture_output=True)
    if k.stdout.strip() != b"blob" or not re.match(rb"^100(644|755) blob ", t.stdout):
        return None                    # the object read is a regular file: never a tree, a symlink
    r = subprocess.run(["git", "show", "HEAD:./" + p], capture_output=True)
    return r.stdout.decode("utf-8").replace("\r", "") if r.returncode == 0 else None

def main():
    try:
        d = json.load(open("_reports/runs/latest.json", encoding="utf-8"))
    except Exception:
        print("NONE"); return                         # already reported above
    spec = d.get("spec", "") if isinstance(d, dict) else ""   # exact: never normalised (sheriff)
    spec = spec if isinstance(spec, str) else str(spec)
    if not spec:
        print("NONE"); return                         # not a spec run: nothing to lint
    text = committed(spec)
    if text is None:
        print(f"BAD latest.json names spec {spec}: not a repo-relative file committed in HEAD"); return
    if not re.search(r"^- \*\*Spec format:\*\*\s*2\b", text, re.M):
        print(f"spec lint skipped: {spec} has no 'Spec format: 2' line (written before v8.3.28)"); return
    FIELD = lambda body, name: re.search(r"^- \*\*" + name + r":\*\*[ \t]*(.*)$", body, re.M)
    NUM_NEAR = re.compile(r"\b(caps?|limits?|max(imum)?|min(imum)?|thresholds?|timeouts?)\b\W+(\w+\W+){0,2}?\d"
                          r"|\d[\w.]*\W+(\w+\W+){0,2}?(caps?|limits?|max(imum)?|min(imum)?|thresholds?|timeouts?)\b", re.I)
    # code is not structure: fenced examples go first; a step heading may be indented 0-3
    # spaces and be h3-h6 (sheriff: " ### S02" hid a step from every check)
    kept, fence = [], None      # CommonMark: closes on the same char, at least as long, alone
    for line in text.split("\n"):
        m = re.match(r"^ {0,3}(`{3,}|~{3,})", line)
        if fence is None:
            o = re.match(r"^ {0,3}(?:(?:[-*+]|\d+[.)])[ \t]+)?(`{3,}|~{3,})(.*)$", line)
            if o and not (o.group(1)[0] == "`" and "`" in o.group(2)):   # backtick info: no backtick
                fence = o.group(1)
            else: kept.append(line)
        elif m and m.group(1)[0] == fence[0] and len(m.group(1)) >= len(fence) \
                and re.match(r"^ {0,3}(`{3,}|~{3,})[ \t]*$", line):
            fence = None
    if fence is not None:
        print(f"BAD {spec}: unclosed code fence — every step after it would be hidden"); return
    text = "\n".join(kept)
    parts = re.split(r"^ {0,3}#{3,6}[ \t]+(S\d+)\b.*$", text, flags=re.M)
    steps = [(parts[i], re.split(r"^ {0,3}## ", parts[i + 1], maxsplit=1, flags=re.M)[0])
             for i in range(1, len(parts) - 1, 2)]
    bad = 0; choices = []
    for sid, body in steps:
        m = FIELD(body, "Kind")
        kind = re.sub(r"<!--.*?-->", "", m.group(1)).strip().lower() if m else ""
        if kind not in ("fix", "build", "choice"):
            print(f"BAD {sid}: Kind is {'missing' if not m else repr(kind)} — exactly one of fix | build | choice"); bad = 1; continue
        r = FIELD(body, "Research")
        rpath = re.sub(r"<!--.*?-->", "", r.group(1)).strip().strip("`") if r else ""
        rpath = "" if rpath in ("", "-", "—", "–") else rpath
        if kind == "choice":
            choices.append(sid)
            brief = committed(rpath) if rpath else None
            if brief is None:
                print(f"BAD {sid}: Kind choice needs a Research brief committed in HEAD — "
                      f"{'no Research line' if not rpath else rpath + ' not found'}"); bad = 1; continue
            for need in ("Recommendation:", "What would change this recommendation:", "Confidence:"):
                if not re.search(r"^" + re.escape(need), brief, re.M):
                    print(f"BAD {sid}: brief {rpath} has no '{need}' line"); bad = 1
            ev = re.search(r"^Evidence:[^\n]*\n((?:[ \t]*- [^\n]*\n?)*)", brief, re.M)
            if not ev or not ev.group(1).strip():
                print(f"BAD {sid}: brief {rpath} has zero Evidence lines"); bad = 1
        else:
            if kind == "fix" and rpath:
                print(f"WARN {sid}: research on a fix = scope creep ({rpath})")
            for name in ("Deliverable", "DoD"):
                f = FIELD(body, name)
                if f and NUM_NEAR.search(f.group(1)):
                    print(f"WARN {sid}: {name} has a bare number next to a cap/limit/threshold/timeout — constant or formula? mark choice or cite derivation")
    if len(choices) > 2:
        print(f"BAD {len(choices)} choice steps ({', '.join(choices)}) — max 2 per spec: split: design spec first"); bad = 1
    if not steps:
        print(f"BAD {spec}: no '### Sxx' steps found"); bad = 1
    if not bad:
        print(f"OK {spec} — {len(steps)} step(s), {len(choices)} choice")

try:
    main()
except Exception as e:                               # a lint that crashed has not passed
    print(f"BAD spec lint crashed: {type(e).__name__}: {e}")
print("LINT-END", flush=True)   # not reached on an interrupt: an unfinished lint BLOCKS (sheriff)
PY
)
      [ "$lint_done" -eq 1 ] || bad "spec lint did not finish — no completion line from python3"
    else
      # SHERIFF [2], v8.3.23: a validator that did not run is not a pass. Without it
      # nothing checks the verdict, the HEAD binding or the independent review.
      bad "python3 unavailable — latest.json could not be validated (verdict, HEAD binding, F2 review); install python3 or run --trivial only for LOW tasks"
    fi
  fi
else
  note "trivial task — run report not required"
fi

# 9) control-state / memory health
# A missing kernel used to crash awk ("fatal: cannot open file") on stderr and SKIP
# the CORE check without a line on stdout — a check that vanishes reads as a pass
# (v8.3.25). No kernel here means this is not a project root, and the gate says so.
# The kernel is AGENTS.md (v8.3.28, #42); CLAUDE.md is a stub that imports it. Claude Code
# reads AGENTS.md only through that import — its own AGENTS.md fallback never fires below a
# directory holding a CLAUDE.md — so a stub that lost the import is a session with NO
# kernel, silently. The gate checks the stub for exactly that.
if [ ! -f AGENTS.md ]; then
  bad "no AGENTS.md here — not a project root, so the CORE check cannot run (run the gate from the project root)"
else
  if awk '/CORE:START/{f=1} f{c++} /CORE:END/{f=0} END{exit !c}' AGENTS.md; then
    if [ -f .claude/core.sha ]; then
      cur=$(awk '/CORE:START/{f=1} f{print} /CORE:END/{f=0}' AGENTS.md | sha256sum | awk '{print $1}')
      [ "$cur" = "$(cat .claude/core.sha)" ] && ok "CORE matches baseline" || bad "CORE changed vs baseline — needs approval + re-baseline"
    else note "no CORE baseline yet — run ./scripts/core-baseline.sh"; fi
  elif [ -f .claude/core.sha ]; then
    bad "AGENTS.md has no CORE block but a CORE baseline exists — the protected kernel was removed"
  fi
  # The stub is exactly one import: anything else in it loads unreviewed instructions
  # beside the kernel, outside the CORE hash (security review, v8.3.28).
  stub="$( [ -f CLAUDE.md ] && tr -d '\r' < CLAUDE.md | awk "$STRIP_HTML_COMMENTS" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^$')"
  if [ "$stub" = "@AGENTS.md" ]; then ok "CLAUDE.md is the kernel stub (@AGENTS.md)"
  elif printf '%s\n' "$stub" | grep -qx '@AGENTS\.md'; then
    bad "CLAUDE.md carries more than the '@AGENTS.md' line — the stub holds that one import and comments only"
  else bad "CLAUDE.md has no '@AGENTS.md' line — Claude Code would run this project WITHOUT its kernel"; fi
fi
[ -f .agent/state/current.md ] && ok "current.md present" || note "no .agent/state/current.md yet"
if [ -f _reports/runs/latest.json ]; then
  if command -v python3 >/dev/null 2>&1 && python3 -c "import json,sys;json.load(open('_reports/runs/latest.json',encoding='utf-8'))" 2>/dev/null; then ok "latest.json valid"
  else bad "latest.json is not valid JSON"; fi
fi

echo "──────────────────"
if [ "$fail" -eq 0 ]; then rm -rf "$qg_logs"; echo "GATE: GREEN ✅"; exit 0
else rmdir "$qg_logs" 2>/dev/null   # BLOCKED: a failing step's log is the evidence — kept unless empty
     echo "GATE: BLOCKED 🔴 — fix the ✗ items above. Task is NOT done."; exit 1; fi
