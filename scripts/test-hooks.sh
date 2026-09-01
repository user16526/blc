#!/usr/bin/env bash
# Hermetic test harness for the template's hooks/scripts.
#   bash scripts/test-hooks.sh        (run from the project root)
# It builds a throwaway sandbox (mktemp -d) and exercises each hook's LOGIC there, so it
# NEVER touches your real CLAUDE.md, .claude/core.sha, or git repo.
# Exit 0 = all green. Exit 1 = at least one failure (see the ✗ lines).
set -uo pipefail

ROOT="$(pwd)"
SCRIPTS="$ROOT/scripts"
pass=0; fail=0
ok(){ echo "  ✓ $1"; pass=$((pass+1)); }
no(){ echo "  ✗ $1"; fail=$((fail+1)); }

# ── 0. scripts present AND executable ──
# Direct guard against the defect that broke v8.1.3: an archive shipped without the Unix
# execute bit, so every hook silently no-op'd after extraction. This catches that.
echo "── 0. scripts present & executable ──"
for s in guard.sh state-freshness.sh check-core.sh check-claude-md-size.sh core-baseline.sh \
         quality-gate.sh precompact-snapshot.sh install-git-hooks.sh pre-commit test-hooks.sh \
         sheriff-review.sh; do
  if [ ! -f "$SCRIPTS/$s" ]; then no "$s missing"; continue; fi
  [ -x "$SCRIPTS/$s" ] && ok "$s executable" || no "$s NOT executable (run: bash setup.sh)"
done
bash -n "$SCRIPTS/integration/sheriff-isolation-live.sh" && ok "sheriff-isolation-live.sh syntax (manual canary, not run here)" \
                                             || no "sheriff-isolation-live.sh syntax"
# watch-transition.sh is project machinery, not Context Guard; its syntax check used
# to ride along in the Context Guard suite, which broke the moment the two releases
# were split apart. It belongs here, with the rest of the project scripts.
bash -n "$SCRIPTS/watch-transition.sh" && ok "watch-transition.sh syntax" \
                                       || no "watch-transition.sh syntax"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
cp -r "$SCRIPTS" "$SANDBOX/scripts"
cd "$SANDBOX" || { echo "cannot enter sandbox"; exit 1; }

# ── 1. guard.sh (PreToolUse) ──
echo "── 1. guard.sh ──"
g(){ printf '%s' "$1" | bash scripts/guard.sh >/dev/null 2>&1; echo $?; }
[ "$(g '{"tool_name":"Write","content":"key=sk-abcdefghijklmnop1234567890"}')" = "2" ] \
  && ok "blocks a hardcoded secret (any tool)" || no "did NOT block a secret"
[ "$(g '{"tool_name":"Bash","command":"rm -rf /tmp/x"}')" = "2" ] \
  && ok "blocks rm -rf in a Bash command" || no "did NOT block rm -rf"
[ "$(g '{"tool_name":"Write","content":"hello world, just prose"}')" = "0" ] \
  && ok "allows a benign write" || no "false-blocked a benign write"
# The v8.1.x over-broad-guard bug: a DOC that merely MENTIONS rm -rf must not be blocked.
[ "$(g '{"tool_name":"Write","content":"The command rm -rf is dangerous; never run it."}')" = "0" ] \
  && ok "does NOT false-block a doc mentioning rm -rf" || no "false-blocked a doc (over-broad guard regressed)"
[ "$(g '{"tool_name":"Bash","command":"git add .env"}')" = "2" ] \
  && ok "blocks staging a real .env" || no "did NOT block staging .env"
[ "$(g '{"tool_name":"Bash","command":"git add .env.example"}')" = "0" ] \
  && ok "allows staging .env.example" || no "false-blocked .env.example"
# Adversarial: MODERN credential families (the v8.1.9 regex missed all of these).
[ "$(g '{"tool_name":"Write","content":"OPENAI_API_KEY=sk-proj-AbCd1234EfGh5678IjKl9012MnOp3456"}')" = "2" ] \
  && ok "blocks sk-proj- (modern OpenAI)" || no "MISSED sk-proj- key"
[ "$(g '{"tool_name":"Write","content":"key=sk-ant-api03-AbCd1234EfGh5678IjKl9012MnOp"}')" = "2" ] \
  && ok "blocks sk-ant- (Anthropic)" || no "MISSED sk-ant- key"
[ "$(g '{"tool_name":"Write","content":"token=ghp_AbCdEfGh1234567890AbCdEfGh12345678"}')" = "2" ] \
  && ok "blocks ghp_ (GitHub)" || no "MISSED ghp_ token"
[ "$(g '{"tool_name":"Write","content":"t=github_pat_11AAAA0abcdefghijklmnopqrstuvwx"}')" = "2" ] \
  && ok "blocks github_pat_" || no "MISSED github_pat_"
[ "$(g '{"tool_name":"Write","content":"slack=xoxb-1234567890-1234567890123-AbCdEfGhIjKl"}')" = "2" ] \
  && ok "blocks xoxb- (Slack)" || no "MISSED xoxb- token"
[ "$(g '{"tool_name":"Write","content":"see https://github.com/openai/gpt-4 and tokens like ghp_ (redacted)"}')" = "0" ] \
  && ok "does NOT false-block prose mentioning token prefixes" || no "false-blocked prose"

# ── 2. check-claude-md-size.sh (PostToolUse) ──
echo "── 2. check-claude-md-size.sh ──"
seq 1 251 > CLAUDE.md
bash scripts/check-claude-md-size.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "flags >250 lines (exit 2)" || no "did NOT flag 251 lines (rc=$rc)"
seq 1 100 > CLAUDE.md
bash scripts/check-claude-md-size.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "passes a 100-line file" || no "false-flagged a 100-line file (rc=$rc)"

# ── 3. check-core.sh + core-baseline.sh ──
echo "── 3. check-core.sh + core-baseline.sh ──"
mkdir -p .claude
cat > CLAUDE.md <<'EOF'
# test kernel
<!-- CORE:START -->
rule one
rule two
<!-- CORE:END -->
non-core tail
EOF
bash scripts/core-baseline.sh >/dev/null 2>&1
[ -f .claude/core.sha ] && ok "core-baseline writes .claude/core.sha" || no "core-baseline did not write a baseline"
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "matching CORE passes" || no "matching CORE failed (rc=$rc)"
sed -i 's/rule two/rule two CHANGED/' CLAUDE.md
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && ok "tampered CORE → STOP (exit 2)" || no "tampered CORE not caught (rc=$rc)"
# A non-CORE edit (below CORE:END) must NOT trip the gate.
cat > CLAUDE.md <<'EOF'
# test kernel
<!-- CORE:START -->
rule one
rule two
<!-- CORE:END -->
non-core tail EDITED FREELY
EOF
bash scripts/check-core.sh >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "non-CORE edit does NOT trip the gate" || no "non-CORE edit wrongly tripped the gate (rc=$rc)"

# ── 4. precompact-snapshot.sh (PreCompact) ──
echo "── 4. precompact-snapshot.sh ──"
mkdir -p .agent/state
printf '# Current State\nLast updated: 2026-01-01\n## Now working on\n- the-sentinel-task\n' > .agent/state/current.md
printf '# Open loops\n- the-sentinel-loop\n' > .agent/state/open-loops.md
printf '%s' '{"session_id":"abc","transcript_path":"/tmp/sentinel.jsonl","source":"auto"}' \
  | bash scripts/precompact-snapshot.sh >/dev/null 2>&1
if [ -f .agent/state/handoff.md ] \
   && grep -q "the-sentinel-task" .agent/state/handoff.md \
   && grep -q "/tmp/sentinel.jsonl" .agent/state/handoff.md; then
  ok "writes handoff.md with current state + transcript path"
else
  no "handoff.md missing or incomplete"
fi

# ── 5. state-freshness.sh resume-surfacing (SessionStart) ──
echo "── 5. state-freshness.sh resume-surfacing ──"
out_c="$(printf '%s' '{"source":"compact"}' | bash scripts/state-freshness.sh 2>/dev/null)"
echo "$out_c" | grep -q "Restoring working state" && ok "surfaces handoff on source=compact" \
  || no "did NOT surface handoff on compact"
out_s="$(printf '%s' '{"source":"startup"}' | bash scripts/state-freshness.sh 2>/dev/null)"
if echo "$out_s" | grep -q "state-freshness" && ! echo "$out_s" | grep -q "Restoring working state"; then
  ok "normal startup: freshness only, no handoff"
else
  no "startup behavior wrong (handoff surfaced when it shouldn't be)"
fi

# ── 6. pre-commit (git hook) ──
echo "── 6. pre-commit ──"
git init -q . 2>/dev/null
git config user.email t@t.t 2>/dev/null; git config user.name t 2>/dev/null
cp scripts/pre-commit .git/hooks/pre-commit 2>/dev/null; chmod +x .git/hooks/pre-commit 2>/dev/null
echo "SECRET=value" > .env; git add -f .env 2>/dev/null
if git commit -qm "should be blocked" >/dev/null 2>&1; then
  no "pre-commit let a real .env through"
else
  ok "pre-commit blocks a real .env"
fi
git rm -q --cached .env >/dev/null 2>&1; rm -f .env
echo "hello" > ok.txt; git add ok.txt 2>/dev/null
if git commit -qm "clean commit" >/dev/null 2>&1; then
  ok "pre-commit allows a clean commit"
else
  no "pre-commit blocked a clean commit"
fi
# BLC finding D1 (2026-09-01): the suite carries synthetic secrets as negative
# controls, so a project's FIRST commit — which stages this very file — must
# not be blocked by the secret scan. And the exclusion must stay NARROW.
git add -f scripts/test-hooks.sh 2>/dev/null
if git commit -qm "first commit incl. the suite" >/dev/null 2>&1; then
  ok "pre-commit allows committing test-hooks.sh (synthetic secrets are negative controls)"
else
  no "D1 regressed: the suite's own synthetic secrets block the first commit"
fi
printf 'key = "sk-%s"\n' "0123456789abcdefghijklmnop" > leak.py; git add leak.py 2>/dev/null
if git commit -qm "should be blocked" >/dev/null 2>&1; then
  no "D1 exclusion is NOT narrow: a synthetic secret outside the suite slipped through"
else
  ok "the D1 exclusion is narrow: a secret in any OTHER file still blocks"
fi
git rm -q --cached leak.py >/dev/null 2>&1; rm -f leak.py
# BLC finding D2 (2026-09-01): a report written exactly to the shipped template
# (verdict on the line AFTER "## Verdict") must yield a parsable verdict.
printf '## Verdict\nGREEN ✅\n## Inputs\nx\n## Findings\nx\n## Artifacts\nx\n' > d2-report.md
rv=$(grep -iEA1 -m1 'verdict' d2-report.md | grep -oEi 'GREEN|YELLOW|RED' | head -1)
[ "$rv" = "GREEN" ] && ok "verdict parses from the line after the header (gate's own extraction)" \
                    || no "D2 regressed: template-style report has no parsable verdict"
rm -f d2-report.md

# ── 7. quality-gate.sh — smoke + ADVERSARIAL (fake proof must NOT pass) ──
echo "── 7. quality-gate.sh ──"
qout="$(bash scripts/quality-gate.sh --trivial 2>&1)"
echo "$qout" | grep -qi "quality gate" && ok "quality-gate runs (--trivial)" || no "quality-gate did not run"
# 7a. RED verdict in the report + empty {} json → gate must BLOCK (the v8.1.9 GREEN-on-RED bug)
mkdir -p _reports/runs
printf 'Verdict: RED\nInputs: x\nFindings: failed\nArtifacts: none\n' > _reports/runs/t_red.md
echo '{}' > _reports/runs/latest.json
if bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "gate passed a RED report + empty latest.json (GREEN-on-RED regressed)"
else
  ok "gate BLOCKS a RED report + empty latest.json"
fi
# 7b. A well-formed GREEN run bound to HEAD → gate must pass (with checks waived for this non-code sandbox)
# Canonical flow: write report → COMMIT code+report → write latest.json(head_sha=HEAD) → gate.
# Sandbox scaffolding (scripts/, CLAUDE.md, .agent/, .claude/) is gitignored here, NOT
# `git add -A`-ed: test-hooks.sh itself contains fake secret literals and the installed
# pre-commit hook would (correctly) refuse to commit it.
printf '%s\n' '/scripts/' '/.agent/' '/.claude/' '/CLAUDE.md' '/_reports/runs/latest.json' > .gitignore
printf 'Verdict: GREEN\nInputs: x\nFindings: none\nArtifacts: ok\n' > _reports/runs/t_green.md
git add .gitignore _reports/runs/t_red.md _reports/runs/t_green.md 2>/dev/null
git commit -qm "code + report" >/dev/null 2>&1
sha="$(git rev-parse HEAD 2>/dev/null || echo '')"
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md"}' "$sha" > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  ok "gate passes a genuine GREEN run bound to HEAD (clean tree, latest.json exempt)"
else
  no "gate blocked a legitimate GREEN run"
fi
# 7c. GREEN json but head_sha of a DIFFERENT commit → stale proof must BLOCK
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"deadbeefdeadbeefdeadbeefdeadbeefdeadbeef","report":"_reports/runs/t_green.md"}' > _reports/runs/latest.json
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "gate accepted proof from a DIFFERENT commit (stale-proof hole)"
else
  ok "gate rejects proof bound to a different commit"
fi
# 7d. THE DIRTY-TREE LOOPHOLE (external review, v8.1.9-p1-lean): valid GREEN proof
# bound to HEAD + an UNVERIFIED unstaged change made AFTER verification → must BLOCK.
printf '{"run_id":"t1","timestamp":"now","verdict":"GREEN","head_sha":"%s","report":"_reports/runs/t_green.md"}' "$sha" > _reports/runs/latest.json
echo "tampered after verification" >> ok.txt
if QG_ALLOW_NO_CHECKS=1 bash scripts/quality-gate.sh >/dev/null 2>&1; then
  no "gate went GREEN with a dirty tree (proof-for-old-state loophole regressed)"
else
  ok "gate BLOCKS unverified changes on top of a valid proof (dirty tree)"
fi
git checkout -q -- ok.txt 2>/dev/null

# ---------------------------------------------------------------------------
# test-hooks.sh SECTION 8 -- sheriff-review.sh reviewer-isolation guarantees
# Splice-ready fragment (hermipro-vps, 2026-08-30, post sheriff round 5).
# 29 assertions; verified standalone against this contract: PASS: 29, FAIL: 0.
# New since v8.3.4: the single-spelling check (round 5) -- see NOTE.md.
#
# CONTRACT (corrected -- the v8.3.4 export's "needs only ok/no and $SANDBOX" was
# INCOMPLETE, and splicing it on that basis yields spurious failures):
#   1. the harness's `ok` / `no` helpers
#   2. $SANDBOX, a mktemp dir
#   3. cwd == $SANDBOX at entry  -- the wrapper finds no git repo there and falls back
#      to $PWD as its protected root, which is what makes "$SANDBOX/..." the
#      inside-the-repo case. Run it from a real repo root instead and three containment
#      assertions invert.
#   4. $SANDBOX/scripts is a copy of the repo's scripts/ (`cp -r "$SCRIPTS" "$SANDBOX/scripts"`)
#      -- the fragment invokes `bash scripts/sheriff-review.sh` relatively.
# Splice after section 7, before the totals, and keep steps 3-4 in place.
# ---------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# test-hooks.sh SECTION 8 - splice-ready fragment, round 6 (2026-08-31)
#
# SPLICE CONTRACT (unchanged from r5 - the fragment assumes all of it):
#   - the `ok` / `no` helpers exist and count into $pass / $fail
#   - $SANDBOX is a temp dir that is NOT a git repo; cwd == $SANDBOX at entry
#   - scripts/ has been copied into $SANDBOX (so `scripts/sheriff-review.sh` runs)
#   - $SCRIPTS points at the REAL scripts dir (used for the integration/ canary)
#   - the wrapper falls back to $PWD as its root here, which is what makes
#     "$SANDBOX/..." the inside-the-repo case
# Assertions in this fragment: 44. Full suite in the field project: 92/0.
# -----------------------------------------------------------------------------

# -- 8. sheriff-review.sh -- reviewer-isolation guarantees --
# These are the STATIC half. The wrapper exists because the same guarantees, written as
# prose in .claude/commands/sheriff.md, lost a different boundary to each of two review
# rounds (2026-08-30). Prose cannot be regression-tested; this can.
# The BEHAVIOURAL half -- does the sandbox actually block, does --cd actually stop
# project-context loading -- needs a live model call and lives OUT of the gate, in
# scripts/integration/sheriff-isolation-live.sh. A capability probe proves a flag EXISTS,
# never that it BEHAVES; do not let these assertions imply otherwise.
echo "-- 8. sheriff-review.sh (reviewer isolation) --"
sr(){ printf 'ACCEPTANCE: t\nDIFF: t\n' | bash scripts/sheriff-review.sh "$@" >/dev/null 2>&1; echo $?; }
# In this sandbox there is no git repo, so the wrapper falls back to $PWD as its root --
# which makes "$SANDBOX/..." the inside-the-repo case. Hermetic, no real repo touched.
[ "$(sr --author codex)" = "4" ] \
  && ok "refuses a same-vendor author (codex reviewing codex)" || no "accepted a SAME-VENDOR review"
[ "$(sr --author OpenAI)" = "4" ] \
  && ok "same-vendor check is case-insensitive and covers vendor aliases" || no "vendor alias slipped through"
[ "$(sr)" = "2" ] \
  && ok "requires --author (cannot review without knowing the author)" || no "ran without --author"
[ "$(sr --author claude --out "$SANDBOX/findings.txt")" = "3" ] \
  && ok "refuses a findings path inside the repo root" || no "accepted a findings path INSIDE the repo"
[ "$(sr --author claude --package "$SANDBOX/pkg.txt")" = "3" ] \
  && ok "refuses a package path inside the repo root" || no "accepted a package path INSIDE the repo"
[ "$(sr --author claude --scratch "$SANDBOX/scratch")" = "3" ] \
  && ok "refuses a scratch dir inside the repo root" || no "accepted a scratch dir INSIDE the repo"
# Relative spellings must not evade containment: ./findings.txt resolves into the root too.
[ "$(sr --author claude --out ./findings.txt)" = "3" ] \
  && ok "containment resolves relative paths (./ does not evade it)" || no "a relative path evaded containment"
# ORDERING GUARANTEE: the vendor check must precede every filesystem and CLI step, so it
# stays provable on a machine with no codex installed. Same-vendor + a repo path must
# report the vendor refusal (4), never the path refusal (3).
[ "$(sr --author codex --out "$SANDBOX/findings.txt")" = "4" ] \
  && ok "vendor check runs BEFORE path/CLI work (provable without codex)" || no "vendor check is not first"
# POSITIVE PATH, via a STUB CLI. It must NOT depend on a real codex being installed:
# a CI worker without one would otherwise pass the gate with -C, -s or -o deleted from
# the wrapper, i.e. the guarantee that matters most would be asserted exactly nowhere.
# The stub advertises the required flags and records the argv it was called with, so
# these assertions test the REAL invocation path and run identically on every machine.
STUBDIR="$(mktemp -d)"
mkdir -p "$STUBDIR/good" "$STUBDIR/crippled"
write_stub(){ # $1 = dir, $2 = 1 to advertise --cd
  {
    echo '#!/usr/bin/env bash'
    echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
    echo '  echo "  -s, --sandbox <MODE>"'
    [ "$2" = "1" ] && echo '  echo "  -C, --cd <DIR>"'
    echo '  echo "      --skip-git-repo-check"'
    echo '  echo "      --ephemeral"'
    echo '  echo "      --ignore-rules"'
    echo '  echo "  -o, --output-last-message <FILE>"'
    echo '  exit 0'
    echo 'fi'
    echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
    echo 'out=""; prev=""'
    echo 'for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done'
    echo 'cat >/dev/null'
    echo '[ -n "$out" ] && printf "STUB FINDINGS\n" > "$out"'
    echo 'exit 0'
  } > "$1/codex"
  chmod +x "$1/codex"
}
write_stub "$STUBDIR/good" 1
write_stub "$STUBDIR/crippled" 0
# A CLI that RENAMED an isolation flag: advertises --cd-root, not --cd. A substring
# match would score this as compliant and run a review with no work-root isolation.
mkdir -p "$STUBDIR/renamed"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd-root <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'exit 0'
} > "$STUBDIR/renamed/codex"
chmod +x "$STUBDIR/renamed/codex"

export STUB_ARGV_LOG="$STUBDIR/argv.txt"
SR_SCRATCH="$(mktemp -d)"
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh \
      --author claude --scratch "$SR_SCRATCH" >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "0" ] && ok "wrapper drives the CLI end-to-end against a stub (rc 0)" \
                   || no "wrapper failed against a conforming stub (rc=$SR_RC)"
ARGV="$(cat "$STUB_ARGV_LOG" 2>/dev/null)"
miss=""
for f in "-s read-only" "--skip-git-repo-check" "-C " "-o " "--ephemeral"; do
  printf '%s' "$ARGV" | grep -q -- "$f" || miss="$miss [$f]"
done
[ -z "$miss" ] && ok "every isolation flag reaches the CLI (recorded argv, not a dry run)" \
              || no "wrapper did NOT pass isolation flag(s):$miss"
printf '%s' "$ARGV" | grep -q "empty-workroot" \
  && ok "reviewer work root is a dedicated empty dir" || no "no isolated work root in argv"
[ -d "$SR_SCRATCH/empty-workroot" ] && [ -z "$(ls -A "$SR_SCRATCH/empty-workroot" 2>/dev/null)" ] \
  && ok "the work root handed to the reviewer is genuinely EMPTY" \
  || no "work root missing or not empty (project context could load)"
case "$ARGV" in
  *"-o $SANDBOX"*) no "findings path pointed INSIDE the repo root" ;;
  *) ok "findings path stayed outside the repo root" ;;
esac
# FAIL CLOSED FOR AUTOMATION ONLY: a CLI lacking a required isolation flag must refuse
# to auto-run (exit 5) AND still print the manual package, so the review is gated but
# never silently skipped.
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --author claude >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "5" ] && ok "a CLI missing an isolation flag fails closed for automation (exit 5)" \
                   || no "weakened CLI did not fail closed (rc=$SR_RC)"
# NOTE: capture, then grep. Under `set -o pipefail` a direct `... | grep -q` inherits
# the wrapper's deliberate non-zero exit (5), so the assertion would fail on a wrapper
# that behaved perfectly.
MANUAL_OUT="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --author claude 2>/dev/null)"
printf '%s' "$MANUAL_OUT" | grep -q "MANUAL SHERIFF PACKAGE" \
  && ok "gated automation still emits the manual package (review not skipped)" \
  || no "automation gated AND no manual package - the review would be silently dropped"
printf '%s' "$MANUAL_OUT" | grep -q "You are SHERIFF" \
  && ok "the manual package carries the full reviewer contract" \
  || no "manual package emitted without the reviewer contract"
# --probe: the standalone readiness check the upgrade procedure calls. Same exit
# contract as a real run (0 available / 5 missing a required flag / 6 no CLI) and it
# must need NO author and NO stdin, or it cannot be used before a review exists.
PROBE_OUT="$(PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --probe 2>&1)"
PROBE_RC="$(PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_RC" = "0" ] && ok "--probe reports automation available against a conforming CLI" \
                      || no "--probe failed on a conforming CLI (rc=$PROBE_RC)"
printf '%s' "$PROBE_OUT" | grep -q "EXIST, not that they BEHAVE" \
  && ok "--probe states its own limit (flags exist != flags behave)" \
  || no "--probe overclaims: no exists-vs-behaves caveat"
PROBE_RC="$(PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_RC" = "5" ] && ok "--probe fails closed on a CLI missing an isolation flag (exit 5)" \
                      || no "--probe did not fail closed on a weakened CLI (rc=$PROBE_RC)"
PROBE_OUT="$(PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --probe 2>&1)"
printf '%s' "$PROBE_OUT" | grep -q -- "--cd" \
  && ok "--probe names the missing flag" || no "--probe did not name the missing flag"

# A RENAMED flag must not pass as present: --cd-root is not --cd.
PROBE_RC="$(PATH="$STUBDIR/renamed:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_RC" = "5" ] && ok "a renamed isolation flag (--cd-root) does NOT satisfy --cd" \
                      || no "substring match accepted a renamed flag (rc=$PROBE_RC)"
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/renamed:$PATH" bash scripts/sheriff-review.sh --author claude >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "5" ] && ok "the review path also rejects a renamed isolation flag" \
                   || no "review ran against a CLI missing the real flag (rc=$SR_RC)"

# The wrapper must name its CLI ONCE. Two spellings of the same tool is how a probe
# ends up validating a different executable than the review runs (sheriff round 5).
# Comments and the closed AUTHOR-IDENTITY set legitimately contain the vendor word, so
# this looks only at lines that INVOKE something.
STRAY="$(grep -nE '(^|[^_[:alnum:]"$])codex[[:space:]]+(exec|--version)|command -v codex' \
         scripts/sheriff-review.sh | grep -v '^[0-9]*:#' || true)"
[ -z "$STRAY" ] && ok "wrapper invokes its CLI through \$SHERIFF_TOOL only (one spelling)" \
                || no "wrapper still hard-codes the CLI name somewhere: $STRAY"

# Closed-set author identities: an unrecognised spelling must fail CLOSED, and a
# same-vendor spelling that matches no wildcard must still be caught.
[ "$(sr --author ChatGPT)" = "4" ] && ok "closed set catches a same-vendor alias (ChatGPT)" \
                                  || no "same-vendor alias ChatGPT was ACCEPTED"
[ "$(sr --author o3)" = "4" ] && ok "closed set catches a same-vendor model codename (o3)" \
                             || no "same-vendor codename o3 was ACCEPTED"
[ "$(sr --author totally-unknown-thing)" = "4" ] \
  && ok "an unrecognised author identity fails CLOSED" || no "unknown author identity was accepted"
# A different vendor must get THROUGH the vendor gate. Asserted against the crippled
# stub so the gate can never fire a real, billable model call: exit 5 means the vendor
# check passed and it stopped later, at the capability probe.
SR_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/crippled:$PATH" bash scripts/sheriff-review.sh --author gemini >/dev/null 2>&1; echo $?)"
[ "$SR_RC" = "5" ] && ok "a genuinely different vendor passes the vendor gate" \
                   || no "a different vendor was wrongly refused (rc=$SR_RC)"

find "$STUBDIR" -mindepth 0 -delete 2>/dev/null
find "$SR_SCRATCH" -mindepth 0 -delete 2>/dev/null
# The canonical prompt can never be dropped: with no prompt file reachable (this sandbox
# has none), the wrapper still writes the SHERIFF contract into the package. Round 2 found
# the manual path silently shipping without the acceptance criteria; same class.
PKGDIR="$(mktemp -d)"
printf 'ACCEPTANCE: marker-acc\nDIFF: marker-diff\n' \
  | bash scripts/sheriff-review.sh --author claude --scratch "$PKGDIR" --dry-run >/dev/null 2>&1
if [ -f "$PKGDIR/sheriff-package.txt" ]; then
  grep -q "You are SHERIFF" "$PKGDIR/sheriff-package.txt" \
    && ok "package always carries the SHERIFF contract (fallback when the file is absent)" \
    || no "package shipped WITHOUT the reviewer contract"
  grep -q "marker-acc" "$PKGDIR/sheriff-package.txt" && grep -q "marker-diff" "$PKGDIR/sheriff-package.txt" \
    && ok "package carries the acceptance criteria AND the diff from stdin" \
    || no "package dropped the criteria or the diff"
else
  no "wrapper wrote no package at all"
fi
find "$PKGDIR" -mindepth 0 -delete 2>/dev/null

# -- round 6 (2026-08-31): three findings from the sheriff's pass on the v8.3.7 upgrade --

# [A] --ephemeral is now a REQUIRED cap, not hardening. Without it codex persists the
# session -- and the session IS the diff under review -- so a build lacking it must gate
# automation to the manual package instead of warning and running anyway.
mkdir -p "$STUBDIR/noeph"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "      --ignore-rules"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'exit 0'
} > "$STUBDIR/noeph/codex"
chmod +x "$STUBDIR/noeph/codex"
NOEPH_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/noeph:$PATH" bash scripts/sheriff-review.sh --author claude >/dev/null 2>&1; echo $?)"
[ "$NOEPH_RC" = "5" ] && ok "a CLI without --ephemeral fails closed (exit 5), not warn-and-run" \
                      || no "--ephemeral is not enforced as a required cap (rc=$NOEPH_RC)"
NOEPH_OUT="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/noeph:$PATH" bash scripts/sheriff-review.sh --author claude 2>&1 >/dev/null)"
printf '%s' "$NOEPH_OUT" | grep -q -- "--ephemeral" \
  && ok "the refusal names --ephemeral as the missing cap" || no "refusal did not name --ephemeral"
# The good stub was deleted with $STUBDIR above; rebuild it, or this assertion
# silently tests whatever real codex is on PATH (the round-3 class: an assertion
# that only runs when a real CLI is installed) and fails on a CLI-free machine.
mkdir -p "$STUBDIR/good"; write_stub "$STUBDIR/good" 1
PROBE_EPH="$(PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --probe 2>&1)"
printf '%s' "$PROBE_EPH" | grep -E '^ *required:' | grep -q -- "--ephemeral" \
  && ok "--probe reports --ephemeral under required, matching the decision" \
  || no "--probe still advertises --ephemeral as optional hardening"
PROBE_EPH_RC="$(PATH="$STUBDIR/noeph:$PATH" bash scripts/sheriff-review.sh --probe >/dev/null 2>&1; echo $?)"
[ "$PROBE_EPH_RC" = "5" ] && ok "--probe fails closed on a CLI without --ephemeral" \
                          || no "--probe passed a CLI missing a required cap (rc=$PROBE_EPH_RC)"

# [B] A PRE-EXISTING target is refused. Containment resolves PATHS, so a hard link --
# a second name for a tracked file's inode -- sits happily outside the repo and still
# writes into it. One rule ("the wrapper only writes targets it creates") closes the
# hard link, the symlink, and the pre-planted file without telling them apart.
EXDIR="$(mktemp -d)"
: > "$EXDIR/already-there.txt"
[ "$(sr --author claude --out "$EXDIR/already-there.txt")" = "3" ] \
  && ok "refuses a findings path that already exists" || no "wrote through a PRE-EXISTING findings file"
[ "$(sr --author claude --package "$EXDIR/already-there.txt")" = "3" ] \
  && ok "refuses a package path that already exists" || no "wrote through a PRE-EXISTING package file"
# The finding's own scenario, end to end: a hard link OUTSIDE the repo aimed at a file
# INSIDE it. Containment cannot see it; the exists rule refuses it. ln fails on some
# filesystems (FAT/exFAT, some network mounts) -- self-skip rather than fake a pass.
echo "canary-content" > "$SANDBOX/tracked-target.txt"
if ln "$SANDBOX/tracked-target.txt" "$EXDIR/hardlink.txt" 2>/dev/null; then
  [ "$(sr --author claude --out "$EXDIR/hardlink.txt")" = "3" ] \
    && ok "refuses an external HARD LINK pointing at a repo file (the round-6 finding)" \
    || no "a hard link into the repo was accepted as a findings path"
  [ "$(cat "$SANDBOX/tracked-target.txt")" = "canary-content" ] \
    && ok "the hard-linked repo file is byte-identical after the refusal" \
    || no "the repo file was modified through the hard link"
else
  ok "hard-link case SKIPPED (this filesystem cannot create hard links) - known limit"
fi
# A symlink stays refused too: the exists rule must not have replaced that guarantee.
if ln -s "$SANDBOX/tracked-target.txt" "$EXDIR/symlink.txt" 2>/dev/null; then
  [ "$(sr --author claude --out "$EXDIR/symlink.txt")" = "3" ] \
    && ok "still refuses a symlink findings path" || no "symlink refusal regressed"
else
  ok "symlink case SKIPPED (no symlink support here) - known limit"
fi
# A REUSED --scratch dir must not silently overwrite the previous review's record.
REUSE="$(mktemp -d)"
printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude --scratch "$REUSE" >/dev/null 2>&1
REUSE_RC="$(printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude --scratch "$REUSE" >/dev/null 2>&1; echo $?)"
[ "$REUSE_RC" = "3" ] && ok "a reused --scratch dir refuses rather than overwrite the prior findings" \
                      || no "a second run clobbered the previous review in the same scratch (rc=$REUSE_RC)"
find "$EXDIR" "$REUSE" -mindepth 0 -delete 2>/dev/null

# [B2] round 6b, from the sheriff's pass on 6a: package and findings must not be the
# same file. Neither exists at check time, so the exists-rule alone cannot see it; the
# reviewer would get one file as both stdin and -o and overwrite what it must read.
COLL="$(mktemp -d)"
[ "$(sr --author claude --package "$COLL/same.txt" --out "$COLL/same.txt")" = "3" ] \
  && ok "refuses package and findings pointing at the SAME file" \
  || no "accepted one file as both the package and the findings target"
[ "$(sr --author claude --package "$COLL/p.txt" --out "$COLL/./p.txt")" = "3" ] \
  && ok "the same-file check resolves ./ spellings too" || no "a ./ spelling evaded the same-file check"
[ "$(sr --author claude --package "$COLL/a.txt" --out "$COLL/b.txt")" != "3" ] \
  && ok "two genuinely different paths are still accepted" || no "the same-file check refuses a legitimate run"
find "$COLL" -mindepth 0 -delete 2>/dev/null

# [B3] the target is RESERVED, not merely checked: after a refusal-free run the wrapper
# must have created the files itself. A check that walks away leaves a swap window.
RESV="$(mktemp -d)"
printf 'ACCEPTANCE: t\nDIFF: t\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude --scratch "$RESV" >/dev/null 2>&1
[ -f "$RESV/sheriff-package.txt" ] && ok "the wrapper created its own package target" \
                                   || no "no package file was created in the scratch dir"
find "$RESV" -mindepth 0 -delete 2>/dev/null

# [C] The live canary asserts repo CONTENT, not `git status` text. It needs a model call
# so the gate cannot run the canary itself -- but the manifest function is pure shell,
# so the gate CAN lift it out and prove it actually detects mutations. Grepping for the
# function name would only prove the name exists; the sheriff flagged exactly that.
CANARY_F="$SCRIPTS/integration/sheriff-isolation-live.sh"
if grep -qE '^[^#]*BEFORE="\$\(git status' "$CANARY_F"; then
  no "live canary still captures git status as its before-state"
else
  ok "the weak git-status before-state is gone from the canary"
fi
MREPO="$(mktemp -d)"
MTMP="$(mktemp -d)"
(
  cd "$MREPO" || exit 1
  git init -q . 2>/dev/null
  git config user.email t@t; git config user.name t
  mkdir -p sub; printf 'one\n' > sub/tracked.sh; printf 'ignored\n' > .gitignore
  printf 'skipme\n' > skipme; echo "skipme" >> .gitignore
  git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
  printf 'untracked\n' > loose.txt
  # shellcheck disable=SC1090
  eval "$(sed -n '/^repo_manifest(){/,/^}/p' "$CANARY_F")"
  base="$(repo_manifest "$MTMP/b")"
  # 1. content of a TRACKED file
  printf 'two\n' > sub/tracked.sh
  [ "$(repo_manifest "$MTMP/1")" != "$base" ] && echo PASS || echo FAIL
  printf 'one\n' > sub/tracked.sh
  # 2. content of an existing UNTRACKED file (the hash-tracked-only version missed this)
  printf 'changed\n' > loose.txt
  [ "$(repo_manifest "$MTMP/2")" != "$base" ] && echo PASS || echo FAIL
  printf 'untracked\n' > loose.txt
  # 3. MODE change on a tracked file, every byte identical
  chmod 755 sub/tracked.sh 2>/dev/null
  if [ -x sub/tracked.sh ]; then
    [ "$(repo_manifest "$MTMP/3")" != "$base" ] && echo PASS || echo FAIL
    chmod 644 sub/tracked.sh
  else
    echo SKIP
  fi
  # 4. a NEW file appearing
  printf 'new\n' > added.txt
  [ "$(repo_manifest "$MTMP/4")" != "$base" ] && echo PASS || echo FAIL
  find added.txt -maxdepth 0 -delete
  # 5. a tracked file DELETED
  find sub/tracked.sh -maxdepth 0 -delete
  [ "$(repo_manifest "$MTMP/5")" != "$base" ] && echo PASS || echo FAIL
  printf 'one\n' > sub/tracked.sh; chmod 644 sub/tracked.sh 2>/dev/null
  # 6. a GITIGNORED file must NOT trip it (or every build would look like a leak)
  printf 'noise\n' > skipme
  [ "$(repo_manifest "$MTMP/6")" = "$base" ] && echo PASS || echo FAIL
  # 7. stable across repeated calls with nothing changed
  [ "$(repo_manifest "$MTMP/7")" = "$base" ] && echo PASS || echo FAIL
  # 8. an mtime-only touch: identical bytes, identical mode. It must NOT trip the
  #    manifest. Regression test for the 127/2 flake: "ls -ldn" prints mtime at MINUTE
  #    resolution, so every restore above moved the hash whenever the clock happened to
  #    tick mid-block - cases 6 and 7 were a coin flip against the wall clock, ~1 run in
  #    25. The touch here forces the worst case deterministically, so it cannot come back.
  find . -path ./.git -prune -o -type f -print0 2>/dev/null | xargs -0 -r touch -d "2020-03-04 05:06:07" --
  [ "$(repo_manifest "$MTMP/8")" = "$base" ] && echo PASS || echo FAIL
  # 9. negative control: the SAME probe against the pre-fix function (--time-style
  #    stripped back out) must TRIP. Without this, assertion 8 would also pass on a
  #    manifest that had stopped looking at file metadata altogether.
  eval "$(sed -n '/^repo_manifest(){/,/^}/p' "$CANARY_F" | sed 's/ --time-style=+//; s/^repo_manifest(){/repo_manifest_pre8(){/')"
  nbase="$(repo_manifest_pre8 "$MTMP/n1")"
  find . -path ./.git -prune -o -type f -print0 2>/dev/null | xargs -0 -r touch -d "2021-07-08 09:10:11" --
  [ "$(repo_manifest_pre8 "$MTMP/n2")" != "$nbase" ] && echo PASS || echo FAIL
  # 10. FAIL-CLOSED guard (sheriff round 9). "--time-style=+" is GNU-only. If ls rejects
  #     it, stderr is discarded and a { ... } | sha256sum pipeline whose middle stream
  #     vanished still returns a valid-looking hash - so the canary would compare two
  #     hashes that describe nothing and report GREEN. Doctor the flag into one no ls
  #     accepts: the function must produce NOTHING, not a hash.
  eval "$(sed -n '/^repo_manifest(){/,/^}/p' "$CANARY_F" | sed 's/--time-style=+/--time-style=+ --no-such-flag-zz/; s/^repo_manifest(){/repo_manifest_nometa(){/')"
  [ -z "$(repo_manifest_nometa "$MTMP/x" 2>/dev/null)" ] && echo PASS || echo FAIL
) > "$MTMP/results.txt" 2>/dev/null
mres(){ sed -n "$1p" "$MTMP/results.txt" 2>/dev/null; }
c=1
for label in "a tracked file's content" "an existing UNTRACKED file's content" \
             "a MODE change with identical bytes" "a newly added file" \
             "a deleted tracked file"; do
  case "$(mres $c)" in
    PASS) ok "canary manifest detects $label" ;;
    SKIP) ok "canary manifest: $label SKIPPED (no exec-bit support here) - known limit" ;;
    *)    no "canary manifest MISSES $label - a review could mutate it and score GREEN" ;;
  esac
  c=$((c+1))
done
[ "$(mres 6)" = "PASS" ] && ok "canary manifest ignores gitignored files (no false RED)" \
                         || no "canary manifest trips on gitignored files - it would cry wolf every build"
[ "$(mres 7)" = "PASS" ] && ok "canary manifest is stable when nothing changed" \
                         || no "canary manifest is non-deterministic - unusable as an assertion"
[ "$(mres 8)" = "PASS" ] && ok "canary manifest ignores an mtime-only touch (same bytes, same mode)" \
                         || no "canary manifest hashes mtime - it is a coin flip against the wall clock"
[ "$(mres 9)" = "PASS" ] && ok "negative control: the pre-fix manifest DOES trip on mtime alone" \
                         || no "mtime negative control is inert - assertion 8 proves nothing"
[ "$(mres 10)" = "PASS" ] && ok "manifest FAILS CLOSED when ls cannot produce metadata (no silent hash)" \
                          || no "manifest still returns a hash with the metadata stream gone - fail-open"
find "$MREPO" "$MTMP" -mindepth 0 -delete 2>/dev/null


# -- round 8 (2026-08-31): sheriff round-7 findings [1]-[3], closed field-first --

# [A] round-7 [2] — the reviewer CLI must never be handed a CALLER-CONTROLLED output
# path. Reserving $OUT and then letting the CLI reopen it by name left the exclusive
# create undoable in between. The wrapper now points -o at a private file inside a 0700
# mktemp dir and copies the result out through the descriptor it has held since creating
# it. Proven on the recorded argv, not on the source.
R8DIR="$(mktemp -d)"
export STUB_ARGV_LOG="$STUBDIR/argv-r8.txt"
R8_RC="$(printf 'ACCEPTANCE: r8-marker\nDIFF: r8-marker\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude \
      --scratch "$R8DIR/scratch" --out "$R8DIR/findings.txt" \
      --package "$R8DIR/pkg.txt" >/dev/null 2>&1; echo $?)"
[ "$R8_RC" = "0" ] && ok "wrapper still runs end-to-end with caller-supplied --out/--package" \
                   || no "the copy-out rework broke the normal path (rc=$R8_RC)"
R8_ARGV="$(cat "$STUB_ARGV_LOG" 2>/dev/null)"
case "$R8_ARGV" in
  *"-o $R8DIR/findings.txt"*)
    no "the CLI was handed the caller's --out path — round-7 [2] is NOT closed" ;;
  *"-o "*)
    ok "the CLI never receives the caller's --out path (it writes inside a private dir)" ;;
  *)
    no "no -o reached the CLI at all — the argv assertion above is testing nothing" ;;
esac
[ "$(cat "$R8DIR/findings.txt" 2>/dev/null)" = "STUB FINDINGS" ] \
  && ok "the findings still reach the caller's --out, copied through the held descriptor" \
  || no "the caller's --out did not receive the reviewer's output"
grep -q "You are SHERIFF" "$R8DIR/pkg.txt" 2>/dev/null \
  && ok "the caller's --package still receives the full reviewer contract" \
  || no "the caller's --package is missing the reviewer contract"
grep -q "r8-marker" "$R8DIR/pkg.txt" 2>/dev/null \
  && ok "the caller's --package still carries the criteria and diff from stdin" \
  || no "the caller's --package lost the stdin content"

# The private directory is an implementation detail, so ask the wrapper where it is
# rather than guessing: --dry-run prints the exact command it would run.
R8_DRY="$(printf 'ACCEPTANCE: r8\nDIFF: r8\n' \
  | PATH="$STUBDIR/good:$PATH" bash scripts/sheriff-review.sh --author claude \
      --scratch "$R8DIR/s2" --dry-run 2>/dev/null)"
R8_PRIV="$(printf '%s' "$R8_DRY" | sed -n 's/.* -o \([^ ]*\) - <.*/\1/p' | head -1)"
[ -n "$R8_PRIV" ] && ok "--dry-run names the private findings path the CLI would be given" \
                  || no "--dry-run does not show where the CLI would actually write"
case "$R8_PRIV" in
  "$R8DIR"*) no "the private path lives inside the caller's --scratch — it is not private" ;;
  "") : ;;
  *) ok "the private working dir is independent of --scratch (caller cannot place it)" ;;
esac
[ -n "$R8_PRIV" ] && [ ! -e "$R8_PRIV" ] \
  && ok "the private working dir is removed when the wrapper exits (no findings left behind)" \
  || no "the wrapper left its private working dir on disk after exiting"

# [B] round-7 [1] — $PKG must never be REOPENED BY NAME. The exclusive descriptor makes
# the WRITE unswappable; reading the same pathname back afterwards handed the window
# straight back. Everything that reads the package now reads the private copy.
# A grep alone proves only that today's spelling is absent, so the detector is put
# through a negative control: a doctored copy that reinstates the read must be CAUGHT.
pkg_reads(){ grep -nE '^[^#]*(cat[[:space:]]+"\$PKG"|<[[:space:]]*"\$PKG")' "$1"; }
if pkg_reads scripts/sheriff-review.sh >/dev/null 2>&1; then
  no "the wrapper still reads \$PKG by name: $(pkg_reads scripts/sheriff-review.sh | head -2 | tr '\n' ' ')"
else
  ok "no code path reopens the caller's package path for reading (round-7 [1])"
fi
R8_DOCTORED="$R8DIR/doctored-wrapper.sh"
sed 's|cat "$PRIV_PKG"|cat "$PKG"|' scripts/sheriff-review.sh > "$R8_DOCTORED"
if pkg_reads "$R8_DOCTORED" >/dev/null 2>&1; then
  ok "the reopen detector actually fires on a doctored copy (negative control)"
else
  no "the reopen detector is inert — it would not catch the read being reinstated"
fi

# [C] round-7 [3] — the live canary's repo manifest was built from `git ls-files`, which
# never lists git's own administrative state, so `.git/` was invisible: a planted
# .git/hooks/pre-commit is code execution on the author's next commit and it scored GREEN.
# The canary gained a sibling git_manifest(). It needs no model call, so the gate can lift
# it out and prove it DETECTS mutations — grepping for the function name would only prove
# the name exists, which is the round-6 lesson about this exact file.
R8_CANARY="$SCRIPTS/integration/sheriff-isolation-live.sh"
grep -qE '^[^#]*BEFORE_GIT="\$\(git_manifest' "$R8_CANARY" \
  && grep -qE '^[^#]*AFTER_GIT="\$\(git_manifest' "$R8_CANARY" \
  && ok "the canary CALLS git_manifest before and after the review (not just defines it)" \
  || no "git_manifest is defined but never called across the review — the check is decorative"
grep -q "GIT METADATA MUTATED" "$R8_CANARY" \
  && ok "the canary fails loudly when git metadata changes" \
  || no "no failure message for a git-metadata mutation"

GREPO="$(mktemp -d)"; GTMP="$(mktemp -d)"
(
  cd "$GREPO" || exit 1
  git init -q . 2>/dev/null
  git config user.email t@t; git config user.name t
  mkdir -p sub; printf 'one\n' > sub/tracked.sh
  git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
  # shellcheck disable=SC1090
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY")"
  base="$(git_manifest "$GTMP/b")"
  # 1. a file planted in the hooks directory
  printf '#!/bin/sh\necho pwned\n' > .git/hooks/pre-commit
  [ "$(git_manifest "$GTMP/1")" != "$base" ] && echo PASS || echo FAIL
  # 2. removing it puts the manifest back. This is the REVERT proof, and it runs before
  #    anything irreversible, so the later probes cannot borrow its result.
  find .git/hooks/pre-commit -maxdepth 0 -delete 2>/dev/null
  [ "$(git_manifest "$GTMP/2")" = "$base" ] && echo PASS || echo FAIL
  # 3. a MODE change on a hook, every byte identical. Self-skips where the filesystem has
  #    no exec-bit semantics: Git Bash on NTFS reports .git/hooks files -rwxr-xr-x whatever
  #    chmod says, and on such a platform the bit is not what gates execution anyway.
  printf '#!/bin/sh\n' > .git/hooks/pre-commit
  chmod 644 .git/hooks/pre-commit 2>/dev/null; m644="$(git_manifest "$GTMP/3a")"
  chmod 755 .git/hooks/pre-commit 2>/dev/null; m755="$(git_manifest "$GTMP/3b")"
  if [ "$m644" != "$m755" ]; then echo PASS
  elif [ "$(ls -ldn .git/hooks/pre-commit 2>/dev/null | cut -c1-10)" = "-rwxr-xr-x" ]; then echo SKIP
  else echo FAIL; fi
  find .git/hooks/pre-commit -maxdepth 0 -delete 2>/dev/null
  # 4. a .git/config change (core.hooksPath, an alias, a filter - all persistence)
  git config sheriff.canary probe
  [ "$(git_manifest "$GTMP/4")" != "$base" ] && echo PASS || echo FAIL
  # 5. a new loose ref
  git branch -q canary-ref 2>/dev/null
  [ "$(git_manifest "$GTMP/5")" != "$base" ] && echo PASS || echo FAIL
  # 6. refs moved into packed-refs - the same logical refs, different files on disk
  git pack-refs --all >/dev/null 2>&1
  [ "$(git_manifest "$GTMP/6")" != "$base" ] && echo PASS || echo FAIL
  # 7. a STAGED change: the index, hashed logically as `git ls-files --stage`
  printf 'staged\n' > sub/tracked.sh; git add sub/tracked.sh >/dev/null 2>&1
  [ "$(git_manifest "$GTMP/7")" != "$base" ] && echo PASS || echo FAIL
  # 8. .git/info/exclude - it changes what the OTHER manifest is willing to see, so a
  #    mutation there is a mutation to the check itself
  printf 'noise\n' >> .git/info/exclude
  [ "$(git_manifest "$GTMP/8")" != "$base" ] && echo PASS || echo FAIL
  # 9. determinism: two consecutive calls over an UNCHANGED repo must agree. Asserted on
  #    the mutated state on purpose - this is the property that decides whether the canary
  #    cries wolf, and it has to hold whatever the repo happens to contain. Restoring the
  #    pristine state instead would test git's own reversibility, not the manifest's.
  d1="$(git_manifest "$GTMP/9a")"; d2="$(git_manifest "$GTMP/9b")"
  [ "$d1" = "$d2" ] && echo PASS || echo FAIL
) > "$GTMP/results.txt" 2>/dev/null
gres(){ sed -n "$1p" "$GTMP/results.txt" 2>/dev/null; }
c=1
for label in "a file planted in .git/hooks" "REVERT - removing it restores the manifest" \
             "a hook MODE change with identical bytes" "a .git/config change" \
             "a new loose ref" "refs moved into packed-refs" "a STAGED index change" \
             "a .git/info/exclude change"; do
  case "$(gres $c)" in
    PASS) ok "git manifest: $label" ;;
    SKIP) ok "git manifest: $label SKIPPED (no exec-bit semantics here) - known limit" ;;
    *)    no "git manifest MISSES $label - a review could do it and score GREEN" ;;
  esac
  c=$((c+1))
done
[ "$(gres 9)" = "PASS" ] && ok "git manifest is deterministic across consecutive calls (it will not cry wolf)" \
                         || no "git manifest is non-deterministic - it would report a mutation that never happened"
find "$GREPO" "$GTMP" "$R8DIR" -mindepth 0 -delete 2>/dev/null


# -- round 8b (2026-08-31): the sheriff's pass on round 8a returned four more --

# [D] round-8 finding [1], the one this round INTRODUCED. Holding fd 8 open on the
# caller's --out from its own O_EXCL creation closed the pathname window and opened a
# worse one: a child inherits the descriptor, and an inherited fd is a write primitive
# that no pathname rule and no `-s read-only` can take back. Proven with a stub that
# TRIES the write, plus a negative control on a wrapper with the fix removed.
#
# ROUND 10 (2026-09-01) - this block's own control was rebuilt. On the template
# maintainer's Linux box the assertion "fd 8 LEAKED into the reviewer" failed once in
# ~8 full-suite runs and could not be diagnosed afterwards. Root cause, found by forcing
# each case rather than by looping: the old assertion was
#   [ "$(cat $STUB_FD8_LOG)" = "CLOSED" ] || no "fd 8 LEAKED"
# with the wrapper's rc and stderr both discarded (2>&1 into /dev/null). EVERY refusal
# path leaves that log EMPTY - a pre-existing --out (exit 3), a build missing a required
# flag (exit 5), no CLI on PATH (exit 6), an unwritable scratch (exit 2), a findings path
# inside the repo (exit 3) - and empty is not "CLOSED", so all of them printed a SECURITY
# FINDING THAT NEVER HAPPENED and threw away the one line that said why. Same class as
# round 9's empty-manifest fail-open, one turn worse: it fails LOUD in the wrong
# direction, which is exactly how a single unexplainable failure ends up in a changelog.
# The second assertion was its mirror image and a true fail-OPEN: `grep -q FD8-LEAK
# findings.txt || ok "no reviewer-written bytes reached --out"` PASSES when the wrapper
# refused and no findings file exists at all - proving nothing, loudly.
# Both now go through fd8_verdict(), which separates "did the CLI run" from "what did it
# report", and four forced controls below prove the verdicts are distinguishable.
export STUB_FD8_LOG="$STUBDIR/fd8.txt"
# Own argv log: the old block inherited whatever an earlier block had exported, which is
# the round-6 class - an assertion whose meaning depends on a distant line.
export STUB_ARGV_LOG="$STUBDIR/argv-fd8.txt"
mkdir -p "$STUBDIR/leaky"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "      --ephemeral"'
  echo '  echo "      --ignore-rules"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
  echo 'out=""; prev=""'
  echo 'for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done'
  echo 'cat >/dev/null'
  # sheriff round-10 [2]: a failed WRITE is not proof the descriptor is absent - ENOSPC,
  # a quota, or any I/O error on an INHERITED fd 8 would have scored CLOSED and falsely
  # certified the guarantee. Existence is now probed with a redirection that copies the
  # descriptor and writes no bytes; only then is the write attempted, and a present-but-
  # unwritable fd is its own verdict, never CLOSED.
  echo 'if : >&8 2>/dev/null; then'
  echo '  if printf "FD8-LEAK\n" >&8 2>/dev/null; then echo LEAK > "$STUB_FD8_LOG"; else echo LEAK-NOWRITE > "$STUB_FD8_LOG"; fi'
  echo 'else'
  echo '  echo CLOSED > "$STUB_FD8_LOG"'
  echo 'fi'
  echo '[ -n "$out" ] && printf "STUB FINDINGS\n" > "$out"'
  echo 'exit 0'
} > "$STUBDIR/leaky/codex"
chmod +x "$STUBDIR/leaky/codex"
# A stub that RUNS but never reaches the fd-8 probe (a CLI that dies mid-run). It must
# not be reported as a leak either - it is a run with no verdict.
mkdir -p "$STUBDIR/mute"
{
  echo '#!/usr/bin/env bash'
  echo 'if [ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ]; then'
  echo '  echo "  -s, --sandbox <MODE>"'
  echo '  echo "  -C, --cd <DIR>"'
  echo '  echo "      --skip-git-repo-check"'
  echo '  echo "      --ephemeral"'
  echo '  echo "      --ignore-rules"'
  echo '  echo "  -o, --output-last-message <FILE>"'
  echo '  exit 0'
  echo 'fi'
  echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
  echo 'out=""; prev=""'
  echo 'for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done'
  echo 'cat >/dev/null'
  echo '[ -n "$out" ] && printf "STUB FINDINGS\n" > "$out"'
  echo 'exit 0'
} > "$STUBDIR/mute/codex"
chmod +x "$STUBDIR/mute/codex"

# fd8_verdict - classify ONE run. $1 = the wrapper's exit code; the two stub logs supply
# the rest. Four outcomes, and only one of them is a security finding:
#   RAN-CLOSED  the CLI ran and could NOT write to fd 8 (the guarantee holds)
#   RAN-LEAK    the CLI ran and DID write to fd 8 (the real finding)
#   RAN-MUTE    the CLI ran but wrote no verdict (inconclusive, never a leak)
#   NO-RUN      the CLI was never invoked - the wrapper refused or failed first
# sheriff round-10 [1], CRITICAL and the one that mattered: the first version returned
# NO-RUN for ANY nonzero wrapper exit, BEFORE looking at the logs. A reviewer that ran,
# inherited fd 8, recorded LEAK and then made the wrapper exit nonzero afterwards (it
# exits 1 whenever the findings file comes back empty) would have had its leak silenced
# as "never ran" - the rebuild would have hidden the very finding it exists to catch.
# Whether the CLI RAN is now decided by the argv log alone; the exit code is context for
# the message, never an input to the verdict.
fd8_verdict(){
  if [ ! -s "$STUB_ARGV_LOG" ]; then echo "NO-RUN"; return; fi
  case "$(cat "$STUB_FD8_LOG" 2>/dev/null)" in
    CLOSED)       echo "RAN-CLOSED" ;;
    LEAK)         echo "RAN-LEAK" ;;
    LEAK-NOWRITE) echo "RAN-LEAK-PRESENT" ;;
    *)            echo "RAN-MUTE" ;;
  esac
}
# sheriff round-10 [3]: fd8_run is always called inside command substitution, so it runs
# in a SUBSHELL and a plain FD8_RC= assignment dies with it - the refusal code would have
# been empty in exactly the diagnostic message this round exists to print. The rc travels
# through a file, like the other two logs, and the caller reads it back.
# sheriff round-10 second pass [1]: the wrapper is launched through an ABSOLUTE bash
# resolved once, before any control starts filtering $PATH. A control that removes the
# directory holding bash would otherwise fail to launch the wrapper at all, and a
# never-launched wrapper writes no argv log - which scores NO-RUN and passes the control
# without ever reaching the refusal it claims to test. Vacuous-pass class, again.
FD8_BASH="$(command -v bash)"
fd8_run(){ # $1 = stub dir, $2 = wrapper to run, $3 = --out path, $4 = --scratch path
  : > "$STUB_FD8_LOG"; : > "$STUB_ARGV_LOG"
  printf 'ACCEPTANCE: fd8\nDIFF: fd8\n' \
    | PATH="$1:$PATH" "$FD8_BASH" "$2" --author claude \
        --scratch "$4" --out "$3" >/dev/null 2>"$FD8ERR"
  echo $? > "$FD8RC"
  fd8_verdict
}
fd8_rc(){ cat "$FD8RC" 2>/dev/null; }

FD8DIR="$(mktemp -d)"
FD8ERR="$FD8DIR/wrapper.err"
FD8RC="$FD8DIR/wrapper.rc"
FD8_V="$(fd8_run "$STUBDIR/leaky" scripts/sheriff-review.sh "$FD8DIR/findings.txt" "$FD8DIR/s")"
case "$FD8_V" in
  RAN-CLOSED)       ok "the reviewer CLI does NOT inherit the writable descriptor on --out (fd 8 closed for the child)" ;;
  RAN-LEAK)         no "fd 8 LEAKED into the reviewer - /dev/fd/8 is a write primitive into the caller's file" ;;
  RAN-LEAK-PRESENT) no "fd 8 was INHERITED by the reviewer (its write failed for another reason, which is not containment)" ;;
  NO-RUN)           no "fd-8 check INCONCLUSIVE, NOT a leak: the CLI never ran (wrapper rc=$(fd8_rc): $(head -1 "$FD8ERR" 2>/dev/null | cut -c1-100))" ;;
  *)                no "fd-8 check INCONCLUSIVE, NOT a leak: the CLI ran but wrote no fd-8 verdict" ;;
esac
# The leaked-bytes assertion is only meaningful once the run happened - otherwise "no
# leaked bytes" is just "no file", which is what made the old version a fail-open.
if [ "$FD8_V" = "NO-RUN" ]; then
  no "leaked-bytes check INCONCLUSIVE: no run happened, so an absent findings file proves nothing"
elif grep -q "FD8-LEAK" "$FD8DIR/findings.txt" 2>/dev/null; then
  no "reviewer-written bytes reached the caller's --out through the inherited descriptor"
else
  ok "no reviewer-written bytes reached the caller's --out"
fi

# Negative control 1: strip the fd close and the SAME stub must report a LEAK. Without
# this, "CLOSED" is indistinguishable from a stub whose write simply failed for another
# reason. The doctored copy must sit in the SAME scripts/ directory as the real one. With
# no git checkout the wrapper takes the parent of its own scripts/ as the protected root
# (sheriff-review.sh:176), so a copy placed anywhere else changes that root and the run is
# refused with exit 3 before the stub is ever called - the control would then "pass" by
# never running, which is the round-3 class all over again.
FD8_DOCTORED="scripts/nofdclose-r8.sh"
sed 's/ 8>&- 9>&-//' scripts/sheriff-review.sh > "$FD8_DOCTORED"
[ "$(fd8_run "$STUBDIR/leaky" "$FD8_DOCTORED" "$FD8DIR/findings2.txt" "$FD8DIR/s2")" = "RAN-LEAK" ] \
  && ok "the fd-leak detector fires on a wrapper with the close removed (negative control)" \
  || no "the fd-leak detector is inert - it would not notice the close being deleted"

# Negative control 2a, round 10 - the CONTROL FOR THE CRITICAL FIX. The sheriff's pass on
# this rebuild found that keying "did it run" off the wrapper's exit code would silence a
# real leak: a reviewer can inherit fd 8, write through it, and THEN make the wrapper exit
# nonzero (it exits 1 whenever the findings come back empty), which the first version
# scored as NO-RUN. Forced here, both halves at once: the fd-close is removed AND the stub
# writes no findings, so the wrapper really does exit nonzero on a run that really did leak.
mkdir -p "$STUBDIR/leaky-empty"
sed 's|\[ -n "$out" \] && printf "STUB FINDINGS\\n" > "$out"|true|' \
  "$STUBDIR/leaky/codex" > "$STUBDIR/leaky-empty/codex"
chmod +x "$STUBDIR/leaky-empty/codex"
FD8_SILENCED="$(fd8_run "$STUBDIR/leaky-empty" "$FD8_DOCTORED" "$FD8DIR/findings2a.txt" "$FD8DIR/s2a")"
[ "$FD8_SILENCED" = "RAN-LEAK" ] \
  && ok "a leak is still reported when the wrapper exits nonzero afterwards (round-10 critical control)" \
  || no "a real leak was silenced by a nonzero wrapper exit (got $FD8_SILENCED) - the critical defect is back"
[ "$(fd8_rc)" != "0" ] \
  && ok "that control really did exercise the nonzero-exit path (rc=$(fd8_rc))" \
  || no "the nonzero-exit control never produced a nonzero exit - it proves nothing"

# Negative control 2, round 10 - the one that would have named the maintainer's failure on
# sight: a REFUSAL must never be reported as a leak. Forced by pre-creating --out (exit 3).
: > "$FD8DIR/pre-existing.txt"
[ "$(fd8_run "$STUBDIR/leaky" scripts/sheriff-review.sh "$FD8DIR/pre-existing.txt" "$FD8DIR/s3")" = "NO-RUN" ] \
  && ok "a wrapper REFUSAL is classified as no-run, never as an fd-8 leak (round-10 control)" \
  || no "a refusal is still being read as an fd-8 verdict - the round-10 defect is back"
# and the refusal must stay LEGIBLE: the reason has to survive, not be discarded.
grep -q "REFUSED" "$FD8ERR" 2>/dev/null \
  && ok "the refusal reason is captured, not discarded (the next failure is diagnosable)" \
  || no "the wrapper's refusal reason was thrown away - the next flake is undiagnosable again"

# Negative control 3, round 10 - the LEADING (unproven) hypothesis for the maintainer's
# single failure, made harmless by construction. Any transient failure of the wrapper's
# `codex exec --help` probe - a fork/exec that loses to EAGAIN under load, a noexec
# /tmp, an ENOSPC write - yields empty help, which the wrapper correctly reads as a build
# missing its required flags and refuses (exit 5). Under the OLD control that refusal
# printed "fd 8 LEAKED". Here it must be a no-run, and the reason must survive.
mkdir -p "$STUBDIR/emptyhelp"
{
  echo '#!/usr/bin/env bash'
  echo '# help that produces nothing, as a failed exec of the real CLI would'
  echo '[ "${1:-}" = "exec" ] && [ "${2:-}" = "--help" ] && exit 0'
  echo 'printf "%s\n" "$*" > "$STUB_ARGV_LOG"'
  echo 'cat >/dev/null'
  echo 'if : >&8 2>/dev/null; then echo LEAK > "$STUB_FD8_LOG"; else echo CLOSED > "$STUB_FD8_LOG"; fi'
  echo 'exit 0'
} > "$STUBDIR/emptyhelp/codex"
chmod +x "$STUBDIR/emptyhelp/codex"
[ "$(fd8_run "$STUBDIR/emptyhelp" scripts/sheriff-review.sh "$FD8DIR/findings6.txt" "$FD8DIR/s6")" = "NO-RUN" ] \
  && ok "a failed capability probe is classified as no-run, never as an fd-8 leak (round-10 control)" \
  || no "a failed probe is being scored as an fd-8 verdict - the maintainer's failure mode is still mislabelled"
grep -q "lacks required isolation flag" "$FD8ERR" 2>/dev/null \
  && ok "the failed-probe refusal names the missing flags (this is what the next flake will print)" \
  || no "a failed probe refuses without naming why - still undiagnosable"

# Negative control 4: a CLI that runs but writes no verdict is inconclusive, not a leak.
[ "$(fd8_run "$STUBDIR/mute" scripts/sheriff-review.sh "$FD8DIR/findings4.txt" "$FD8DIR/s4")" = "RAN-MUTE" ] \
  && ok "a CLI that runs without probing fd 8 is inconclusive, never a leak (round-10 control)" \
  || no "a silent CLI is being scored as an fd-8 verdict"

# Negative control 5: no reviewer CLI on PATH at all -> no-run, and again never a leak.
# sheriff round-10 [4]: the first version prepended an EMPTY directory to $PATH and called
# that "no CLI". It is not - a real codex further down $PATH is still found, so on a
# machine that has one this control invoked the REAL reviewer: environment-dependent, and
# a billable model call fired from the hook suite, which this file forbids everywhere
# else. It also passed vacuously (the real CLI writes no stub log, which reads as NO-RUN)
# - the round-3 class, an assertion that only means something when nothing is installed.
# $PATH is now filtered to drop every directory that actually holds a codex executable,
# and the removal is PROVEN before the control is allowed to mean anything.
nocli_path(){ # every $PATH entry that does not contain a codex executable
  local out="" d IFS=:
  for d in $PATH; do
    [ -n "$d" ] || continue
    if [ -x "$d/codex" ] || [ -x "$d/codex.exe" ] || [ -x "$d/codex.cmd" ]; then continue; fi
    out="$out${out:+:}$d"
  done
  printf '%s' "$out"
}
FD8_NOCLI="$(nocli_path)"
if [ -z "$FD8_NOCLI" ] || PATH="$FD8_NOCLI" command -v codex >/dev/null 2>&1; then
  no "the no-CLI control could not remove codex from PATH - it would test the real CLI, not a missing one"
else
  ok "the no-CLI control really has no codex on PATH (proven before it is trusted)"
  mkdir -p "$STUBDIR/nocli"
  FD8_NOCLI_V="$(PATH="$FD8_NOCLI" fd8_run "$STUBDIR/nocli" scripts/sheriff-review.sh "$FD8DIR/findings5.txt" "$FD8DIR/s5")"
  [ "$FD8_NOCLI_V" = "NO-RUN" ] \
    && ok "a missing reviewer CLI is classified as no-run, never as an fd-8 leak (round-10 control)" \
    || no "a missing CLI is being scored as an fd-8 verdict"
  # NO-RUN alone is not enough: a wrapper that never LAUNCHED also produces NO-RUN. The
  # control only means something if the wrapper ran far enough to refuse for the stated
  # reason, so assert the exit code and the message it is supposed to print.
  [ "$(fd8_rc)" = "6" ] \
    && ok "the no-CLI control really exercised the wrapper's missing-CLI refusal (exit 6)" \
    || no "the no-CLI control did not reach exit 6 (rc=$(fd8_rc)) - it proves nothing about that path"
  grep -q "not on PATH" "$FD8ERR" 2>/dev/null \
    && ok "the missing-CLI refusal names the reason (not a silent failure to launch)" \
    || no "no missing-CLI refusal message - the wrapper may never have started"
fi


# [E] round-8 finding [3]: core.hooksPath must be read with `--path`, or git's own ~
# expansion is skipped and the manifest watches a directory nothing runs hooks from.
grep -qE '^[^#]*git config --get --path core\.hooksPath' "$R8_CANARY" \
  && ok "core.hooksPath is read with --path (git's own ~ expansion applies)" \
  || no "core.hooksPath is read without --path - a ~-prefixed value would be taken literally"
[ "$(grep -cE '^[^#]*git config --get core\.hooksPath' "$R8_CANARY")" = "0" ] \
  && ok "no remaining plain --get read of core.hooksPath" \
  || no "a plain --get read of core.hooksPath survives somewhere in the canary"

# [F] round-8 findings [2] and [4]: index FLAGS, and the gitdir walk that replaced the
# hand-picked list. Same lift-and-run technique, a second throwaway repo.
G2REPO="$(mktemp -d)"; G2TMP="$(mktemp -d)"; G2HOOKS="$(mktemp -d)"
(
  cd "$G2REPO" || exit 1
  git init -q . 2>/dev/null
  git config user.email t@t; git config user.name t
  printf 'one\n' > tracked.txt
  git add -A >/dev/null 2>&1; git commit -qm init >/dev/null 2>&1
  # shellcheck disable=SC1090
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY")"
  base="$(git_manifest "$G2TMP/b")"
  # 1. assume-unchanged: tells git to STOP NOTICING a working-tree change. ls-files --stage
  #    alone cannot see it; ls-files -v can.
  git update-index --assume-unchanged tracked.txt >/dev/null 2>&1
  [ "$(git_manifest "$G2TMP/1")" != "$base" ] && echo PASS || echo FAIL
  git update-index --no-assume-unchanged tracked.txt >/dev/null 2>&1
  # 2. skip-worktree, the other half of the same finding
  git update-index --skip-worktree tracked.txt >/dev/null 2>&1
  [ "$(git_manifest "$G2TMP/2")" != "$base" ] && echo PASS || echo FAIL
  git update-index --no-skip-worktree tracked.txt >/dev/null 2>&1
  # 3. operation state the hand-picked list missed entirely (MERGE_HEAD steers the next
  #    commit into recording a second parent)
  printf '%s\n' "$(git rev-parse HEAD)" > .git/MERGE_HEAD
  [ "$(git_manifest "$G2TMP/3")" != "$base" ] && echo PASS || echo FAIL
  find .git/MERGE_HEAD -maxdepth 0 -delete 2>/dev/null
  # 4. rerere data - replays a recorded conflict resolution into a future merge
  mkdir -p .git/rr-cache/aaaa; printf 'resolved\n' > .git/rr-cache/aaaa/preimage
  [ "$(git_manifest "$G2TMP/4")" != "$base" ] && echo PASS || echo FAIL
  find .git/rr-cache -mindepth 0 -delete 2>/dev/null
  # 5. the reflog: rewriting it is how a mutation hides from `git reflog`
  printf 'tampered\n' >> .git/logs/HEAD 2>/dev/null
  [ "$(git_manifest "$G2TMP/5")" != "$base" ] && echo PASS || echo FAIL
  # 6. core.hooksPath pointing OUT of the gitdir: the walk above cannot reach it, so the
  #    live hooks directory has to be scanned separately or a planted hook is invisible.
  git config core.hooksPath "$G2HOOKS"
  hbase="$(git_manifest "$G2TMP/6a")"
  printf '#!/bin/sh\necho pwned\n' > "$G2HOOKS/pre-commit"
  [ "$(git_manifest "$G2TMP/6b")" != "$hbase" ] && echo PASS || echo FAIL
  # 7. the object store is EXCLUDED on purpose - a loose object is inert until a ref or
  #    the index points at it. Assert the exclusion, so the claim and the code agree.
  mkdir -p .git/objects/ab; printf 'junk\n' > .git/objects/ab/canary
  [ "$(git_manifest "$G2TMP/7")" = "$(git_manifest "$G2TMP/7b")" ] && echo PASS || echo FAIL
  # 8. a *.lock file must NOT trip it, or the manifest races every concurrent git command
  lbase="$(git_manifest "$G2TMP/8a")"
  : > .git/some-op.lock
  [ "$(git_manifest "$G2TMP/8b")" = "$lbase" ] && echo PASS || echo FAIL
  # 9. an mtime-only touch inside the gitdir must NOT trip it either, and it matters
  #    MORE here than in the working tree: ordinary git commands rewrite .git mtimes
  #    constantly, so hashing them would paint a review RED for merely READING the repo.
  mbase="$(git_manifest "$G2TMP/9a")"
  find .git "$G2HOOKS" -type f -print0 2>/dev/null | xargs -0 -r touch -d "2020-03-04 05:06:07" --
  [ "$(git_manifest "$G2TMP/9b")" = "$mbase" ] && echo PASS || echo FAIL
  # 10. negative control for 9, same shape as the working-tree one.
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY" | sed 's/ --time-style=+//; s/^git_manifest(){/git_manifest_pre8(){/')"
  gnbase="$(git_manifest_pre8 "$G2TMP/n1")"
  find .git "$G2HOOKS" -type f -print0 2>/dev/null | xargs -0 -r touch -d "2021-07-08 09:10:11" --
  [ "$(git_manifest_pre8 "$G2TMP/n2")" != "$gnbase" ] && echo PASS || echo FAIL
  # 11. the same fail-closed guard on this side (sheriff round 9).
  eval "$(sed -n '/^git_manifest(){/,/^}/p' "$R8_CANARY" | sed 's/--time-style=+/--time-style=+ --no-such-flag-zz/; s/^git_manifest(){/git_manifest_nometa(){/')"
  [ -z "$(git_manifest_nometa "$G2TMP/x" 2>/dev/null)" ] && echo PASS || echo FAIL
) > "$G2TMP/results.txt" 2>/dev/null
g2res(){ sed -n "$1p" "$G2TMP/results.txt" 2>/dev/null; }
c=1
for label in "an assume-unchanged index flag" "a skip-worktree index flag" \
             "MERGE_HEAD (operation state the curated list missed)" \
             "rerere data planted for a future merge" "an appended reflog entry" \
             "a hook planted via an out-of-gitdir core.hooksPath"; do
  [ "$(g2res $c)" = "PASS" ] && ok "git manifest detects $label" \
                             || no "git manifest MISSES $label - a review could do it and score GREEN"
  c=$((c+1))
done
[ "$(g2res 7)" = "PASS" ] && ok "git manifest ignores the object store, as its stated exclusion says" \
                          || no "git manifest trips on a loose object - the code and the stated limit disagree"
[ "$(g2res 8)" = "PASS" ] && ok "git manifest ignores *.lock files (it will not race a concurrent git)" \
                          || no "git manifest trips on a transient lock file - it would cry wolf"
[ "$(g2res 9)" = "PASS" ] && ok "git manifest ignores an mtime-only touch inside the gitdir" \
                          || no "git manifest hashes .git mtimes - ordinary git use would score RED"
[ "$(g2res 10)" = "PASS" ] && ok "negative control: the pre-fix git manifest DOES trip on mtime alone" \
                           || no "git-manifest mtime control is inert - assertion 9 proves nothing"
[ "$(g2res 11)" = "PASS" ] && ok "git manifest FAILS CLOSED when ls cannot produce metadata" \
                           || no "git manifest still returns a hash with the metadata stream gone - fail-open"
find "$G2REPO" "$G2TMP" "$G2HOOKS" "$FD8DIR" -mindepth 0 -delete 2>/dev/null


cd "$ROOT" || true
echo "────────────────────────────"
echo "PASS: $pass   FAIL: $fail"
if [ "$fail" -eq 0 ]; then echo "HOOKS: GREEN ✅"; exit 0; else echo "HOOKS: RED 🔴 — fix the ✗ items above."; exit 1; fi
