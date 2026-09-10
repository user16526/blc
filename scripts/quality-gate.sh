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
  if git diff --cached --name-only 2>/dev/null | grep -E '(^|/)\.env($|\.)' | grep -qv '\.env\.example'; then
    bad ".env is staged — unstage it"
  else ok "no real .env staged"; fi
fi

# 3) no obvious secrets in staged diff
if git rev-parse --git-dir >/dev/null 2>&1; then
  . "$(dirname "$0")/secret-patterns.sh" 2>/dev/null || SECRET_REGEX='(sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
  if git diff --cached -U0 2>/dev/null | grep -Eq "^\+.*$SECRET_REGEX"; then
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
  [ -n "$qg_logs" ] && log="$qg_logs/$(printf '%s' "$label" | tr -c 'A-Za-z0-9' '-' | tr -s '-').log"
  if "$@" >"$log" 2>&1; then ok "$label passed"; else bad "$label FAILED (log: $log)"; fi
}
has_npm_script() { [ -f package.json ] && grep -q "\"$1\"" package.json; }

# 4/5/6 — lint, test, build. Auto-detect the stack; run a check only if it exists.
# Order of preference: npm script → Makefile target → justfile → python → docker.
gate_step() { # $1 = step name (lint|test|build)
  local step="$1"
  if has_npm_script "$step"; then run_if "$step (npm)" npm run -s "$step" 2>/dev/null || run_if "$step (npm)" npm "$step" --silent; return; fi
  if [ -f Makefile ] && grep -q "^${step}:" Makefile; then run_if "$step (make)" make "$step"; return; fi
  if [ -f justfile ] && grep -q "^${step}" justfile; then run_if "$step (just)" just "$step"; return; fi
  case "$step" in
    test)
      if [ -f pyproject.toml ] || ls tests/ >/dev/null 2>&1; then run_if "test (pytest)" python3 -m pytest -q; return; fi ;;
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
  latest=$(ls -t _reports/runs/*.md 2>/dev/null | head -1)
  if [ -z "$latest" ]; then
    bad "no run report in _reports/runs/ for a non-trivial task"
  else
    ok "run report: $latest"
    for sec in Verdict Inputs Findings Artifacts; do
      grep -qi "$sec" "$latest" || bad "run report missing section: $sec"
    done
    # The VALUE of the verdict matters, not the word "Verdict". field project C finding D2
    # (2026-09-01): the shipped report template puts the value on the line AFTER
    # "## Verdict", so the gate reads the header line AND the next one.
    rv=$(grep -iEA1 -m1 'verdict' "$latest" | grep -oEi 'GREEN|YELLOW|RED' | head -1 | tr '[:lower:]' '[:upper:]')
    case "$rv" in
      GREEN) ok "report verdict: GREEN" ;;
      YELLOW|RED) bad "report verdict is $rv — the run itself says it is not done" ;;
      *) bad "report has no parsable verdict value (expected GREEN/YELLOW/RED)" ;;
    esac
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
# A missing CLAUDE.md used to crash awk ("fatal: cannot open file") on stderr and SKIP
# the CORE check without a line on stdout — a check that vanishes reads as a pass
# (v8.3.25). No kernel here means this is not a project root, and the gate says so.
if [ ! -f CLAUDE.md ]; then
  bad "no CLAUDE.md here — not a project root, so the CORE check cannot run (run the gate from the project root)"
elif awk '/CORE:START/{f=1} f{c++} /CORE:END/{f=0} END{exit !c}' CLAUDE.md; then
  if [ -f .claude/core.sha ]; then
    cur=$(awk '/CORE:START/{f=1} f{print} /CORE:END/{f=0}' CLAUDE.md | sha256sum | awk '{print $1}')
    [ "$cur" = "$(cat .claude/core.sha)" ] && ok "CORE matches baseline" || bad "CORE changed vs baseline — needs approval + re-baseline"
  else note "no CORE baseline yet — run ./scripts/core-baseline.sh"; fi
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
