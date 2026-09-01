#!/usr/bin/env bash
# release-check.sh — the release gate. Verifies a release FROM ITS ARTIFACT,
# never from the working tree (v8.3.19, lesson [release]).
#
#   bash scripts/release-check.sh [--out-dir <dir>] [--wrapper <folder>]
#
# Why this exists: twice on 2026-09-01 a working-tree verification passed while
# the shipped artifact carried a defect it could not see — a stray .env seeded
# by setup.sh (D4) and a rotted version literal in START-HERE. The working tree
# is where verification runs; it is therefore never what ships. This script
# builds, unpacks the RESULT, and runs every check inside that unpack.
#
# Runs on the CANONICAL tree only (needs context-guard/ to build). In a project
# it exits 2 with an explanation — it is a release-side gate, not a project gate.
# Zero network. Exit 0 = GREEN (ship), 1 = RED (do not ship), 2 = not applicable.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1
out=""; wrapper=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out-dir) out="$2"; shift 2;;
    --wrapper) wrapper="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done
if [ ! -f context-guard/version.json ]; then
  echo "release-check: not the canonical tree (no context-guard/version.json) — n/a." >&2
  exit 2
fi
fail=0; pass=0
ok(){ echo "  ✓ $1"; pass=$((pass+1)); }
no(){ echo "  ✗ $1"; fail=$((fail+1)); }
[ -n "$out" ] || out="$(mktemp -d)"
work="$(mktemp -d)"
tv="$(tr -d '\r\n' < TEMPLATE_VERSION)"
tname="$(printf '%s' "$tv" | tr . _).zip"

echo "release-check: building from $(pwd) → $out"
python3 scripts/build-release.py --out-dir "$out" > "$work/build.log" 2>&1 \
  && ok "build-release.py clean (TEMPLATE_VERSION $tv)" || { no "build-release.py failed"; cat "$work/build.log"; exit 1; }
[ -f "$out/$tname" ] && ok "artifact name derives from TEMPLATE_VERSION: $tname" \
  || { no "expected artifact $tname not produced"; ls "$out"; exit 1; }
( cd "$out" && sha256sum -c "${tname%.zip}.sha256" >/dev/null 2>&1 ) \
  && ok "sha256 companion matches artifact" || no "sha256 companion MISMATCH"

# ---- everything below runs INSIDE the unpacked artifact -----------------------
( cd "$work" && unzip -q "$out/$tname" ) || { no "artifact does not unzip"; exit 1; }
ex="$work/$tv"
[ -d "$ex" ] && ok "inner folder named by version ($tv)" || { no "inner folder is not $tv"; ls "$work"; exit 1; }
cd "$ex" || exit 1

stray="$(find . \( -name '.env' -o -name '*.cg-tmp' -o -name '__pycache__' -o -name '*.pyc' \
        -o -name 'handoffs' -o -name '.DS_Store' -o -name '*.orig' -o -name '*.rej' -o -name '*.bak' \) 2>/dev/null)"
[ -z "$stray" ] && ok "no stray/runtime files in artifact" || no "stray files in artifact: $(echo "$stray" | tr '\n' ' ')"

leak="$(find . -path './context-guard/*' -o -name 'install-context-guard.py' -o -name 'test-context-guard.sh' \
        -o -name 'cg-acceptance.sh' -o -name 'test-onboarding.sh' 2>/dev/null | head -1)"
[ -z "$leak" ] && ok "no Context Guard release files leaked into the template" || no "CG release file in template: $leak"

# Version literals that can rot: a release zip name or a bare template version
# in prose, outside the files that legitimately hold history.
rot="$(grep -rn -E 'v8_3_[0-9]+\.zip|Canonical source: `v8' --include='*.md' . \
       | grep -v -E 'CHANGELOG\.md|TEMPLATE-DELTA\.md' || true)"
[ -z "$rot" ] && ok "no rot-able version literals outside history docs" || no "version literal will rot: $rot"

head -3 CHANGELOG.md | grep -q "## $tv" && ok "CHANGELOG top entry is $tv" || no "CHANGELOG top entry is not $tv"

# ---- optional: an all-in-one wrapper folder must EQUAL the PRISTINE unpack -----
# (must run BEFORE setup.sh below seeds .env / exec bits into the unpack)
if [ -n "$wrapper" ]; then
  if diff -r "$ex" "$wrapper" >/dev/null 2>&1; then ok "wrapper folder == artifact content (empty diff)"
  else no "wrapper folder differs from artifact — pack FROM the artifact, not from a tree"; fi
fi

bash setup.sh >/dev/null 2>&1
[ -x scripts/pre-commit ] && ok "setup.sh restores exec bits inside the artifact" || no "setup.sh did not make pre-commit executable"
th="$(timeout 300 bash scripts/test-hooks.sh 2>&1 | tail -2 | head -1)"
echo "$th" | grep -q 'FAIL: 0' && ok "test-hooks from artifact: $th" || no "test-hooks from artifact: $th"
python3 scripts/state-patch.py --self-test 2>&1 | grep -q 'GREEN' \
  && ok "state-patch self-test from artifact (utf-8)" || no "state-patch self-test failed"
PYTHONIOENCODING=cp1252 python3 scripts/state-patch.py --self-test 2>&1 | grep -q 'GREEN' \
  && ok "state-patch self-test from artifact (cp1252 console, D3 regression)" || no "state-patch self-test dies under cp1252 (D3 regressed)"

echo "────────────────────────────"
echo "release-check: PASS $pass  FAIL $fail"
if [ "$fail" -eq 0 ]; then echo "RELEASE: GREEN ✅ — ship $out/$tname"; exit 0
else echo "RELEASE: RED 🔴 — do not ship"; exit 1; fi
