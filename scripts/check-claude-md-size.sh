#!/usr/bin/env bash
# PostToolUse: deterministic backstop for the 250-line limit (team variant) on CLAUDE.md.
# Anthropic: files over 200 lines consume more context and may reduce adherence.
set -euo pipefail
f="CLAUDE.md"
[ -f "$f" ] || exit 0
n=$(wc -l < "$f" | tr -d ' ')
if [ "$n" -gt 250 ]; then
  echo "⚑ ATTENTION: CLAUDE.md is ${n} lines (>250). Move path-specific content to .claude/rules/, procedures to .claude/skills/, reference to docs/, lessons to tasks/lessons.md. Imports do NOT help — they still load at launch." >&2
  exit 2   # surfaces the message to Claude
fi
if [ "$n" -gt 220 ]; then
  echo "Note: CLAUDE.md is ${n} lines — approaching the 250 limit. Consider trimming soon." >&2
fi
exit 0
