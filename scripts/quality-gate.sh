#!/usr/bin/env bash
# Quality gate: a non-trivial task cannot be "done" until this passes.
# Run from project root:  ./scripts/quality-gate.sh [--trivial]
# Exit 0 = GREEN (all required checks pass). Exit 1 = blocked (see messages).
# It runs a check ONLY if the relevant command/state exists — never invents one.
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

# helper: run a script from package.json or a known tool, only if it exists
run_if() { # $1 = label, $2.. = command
  local label="$1"; shift
  checks_run=$((checks_run+1))
  if "$@" >/tmp/qg.out 2>&1; then ok "$label passed"; else bad "$label FAILED (see /tmp/qg.out)"; fi
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
    # The VALUE of the verdict matters, not the word "Verdict".
    rv=$(grep -iEm1 'verdict' "$latest" | grep -oEi 'GREEN|YELLOW|RED' | head -1 | tr '[:lower:]' '[:upper:]')
    case "$rv" in
      GREEN) ok "report verdict: GREEN" ;;
      YELLOW|RED) bad "report verdict is $rv — the run itself says it is not done" ;;
      *) bad "report has no parsable verdict value (expected GREEN/YELLOW/RED)" ;;
    esac
    # machine-readable state: must exist AND match schema AND bind to THIS commit
    if [ ! -f _reports/runs/latest.json ]; then
      bad "missing _reports/runs/latest.json"
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
for e in errs:
    print(f"  {e}")
sys.exit(1 if errs else 0)
PY
      then ok "latest.json schema + verdict GREEN + bound to HEAD"
      else bad "latest.json failed validation (see lines above)"; fi
    else
      note "python3 unavailable — latest.json deep validation skipped"
      ok "latest.json present"
    fi
  fi
else
  note "trivial task — run report not required"
fi

# 9) control-state / memory health
if awk '/CORE:START/{f=1} f{c++} /CORE:END/{f=0} END{exit !c}' CLAUDE.md; then
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
if [ "$fail" -eq 0 ]; then echo "GATE: GREEN ✅"; exit 0
else echo "GATE: BLOCKED 🔴 — fix the ✗ items above. Task is NOT done."; exit 1; fi
