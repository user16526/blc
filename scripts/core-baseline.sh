#!/usr/bin/env bash
# Re-baseline the protected CORE block of CLAUDE.md after an APPROVED change.
# Run this ONLY after you've agreed to a kernel change.
#   ./scripts/core-baseline.sh
set -euo pipefail
f="CLAUDE.md"
out=".claude/core.sha"

core=$(awk '/CORE:START/{flag=1} flag{print} /CORE:END/{flag=0}' "$f")
if [ -z "$core" ]; then
  echo "No CORE:START/END block found in $f — nothing to baseline." >&2; exit 1
fi
echo "$core" | sha256sum | awk '{print $1}' > "$out"
echo "✓ CORE baseline updated → $out"
echo "  ($(echo "$core" | wc -l) lines hashed)"
