#!/usr/bin/env bash
# Baseline / verify the protected CORE block of CLAUDE.md.
#
#   ./scripts/core-baseline.sh           re-baseline: hash CORE, WRITE .claude/core.sha
#   ./scripts/core-baseline.sh --check   verify only: compare, NEVER write
#   ./scripts/core-baseline.sh --help
#
# Exit codes: 0 = ok (written, or --check matched)
#             1 = --check mismatch, or no CORE block found
#             2 = usage error (unknown argument)
#
# Re-baselining is the LAST step of an approved kernel change, never a way to
# make check-core.sh stop complaining. Writing a new baseline over an unapproved
# edit does not fix the edit, it only destroys the evidence that CLAUDE.md moved.
#
# Why --check exists, and why an unknown argument is fatal (v8.3.24):
# until now this script parsed nothing and re-baselined unconditionally, so ANY
# argument was silently ignored. On 2026-09-08 a session ran it with `--check`
# expecting a dry run, and it rewrote the baseline instead — over a kernel edit
# that had not been approved yet. The hash then matched, so check-core.sh went
# green and the protection was gone with no error anywhere. A flag that is
# ignored is worse than a flag that does not exist: it reads as a promise.
set -euo pipefail

usage() {
  echo "usage: core-baseline.sh [--check]"
  echo "  (no args)  re-baseline: hash the CORE block and write .claude/core.sha"
  echo "  --check    verify only: compare against .claude/core.sha, never write"
}

mode="write"
while [ $# -gt 0 ]; do
  case "$1" in
    --check) mode="check"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "core-baseline: unknown argument: $1" >&2
       echo "core-baseline: refusing to run — this script writes .claude/core.sha, so it will not guess what you meant." >&2
       usage >&2
       exit 2 ;;
  esac
done

f="CLAUDE.md"
out=".claude/core.sha"

core=$(awk '/CORE:START/{flag=1} flag{print} /CORE:END/{flag=0}' "$f")
if [ -z "$core" ]; then
  echo "No CORE:START/END block found in $f — nothing to baseline." >&2; exit 1
fi
sum=$(echo "$core" | sha256sum | awk '{print $1}')
lines=$(echo "$core" | wc -l)

if [ "$mode" = "check" ]; then
  if [ ! -f "$out" ]; then
    echo "✗ no baseline at $out — run ./scripts/core-baseline.sh (no args) after an APPROVED kernel change." >&2
    exit 1
  fi
  have=$(tr -d ' \t\r\n' < "$out")
  if [ "$sum" = "$have" ]; then
    echo "✓ CORE matches $out  ($lines lines hashed)"
    exit 0
  fi
  echo "✗ CORE does NOT match $out" >&2
  echo "    baseline: $have" >&2
  echo "    current : $sum" >&2
  echo "  The protected block in $f changed. Get the change approved, THEN re-baseline." >&2
  exit 1
fi

echo "$sum" > "$out"
echo "✓ CORE baseline updated → $out"
echo "  ($lines lines hashed)"
