#!/usr/bin/env bash
# PostToolUse: deterministic backstop for the 250-line limit (team variant) on the kernel.
# The kernel is AGENTS.md since v8.3.28 (CLAUDE.md is a one-line stub importing it); the
# script keeps its old name so no project's settings.json has to change.
# Anthropic: files over 200 lines consume more context and may reduce adherence.
set -euo pipefail
f="AGENTS.md"
[ -f "$f" ] || exit 0
n=$(wc -l < "$f" | tr -d ' ')
if [ "$n" -gt 250 ]; then
  echo "⚑ ATTENTION: AGENTS.md is ${n} lines (>250). Move path-specific content to .claude/rules/, procedures to .claude/skills/, reference to docs/, lessons to tasks/lessons.md. Imports do NOT help — they still load at launch." >&2
  exit 2   # surfaces the message to Claude
fi
if [ "$n" -gt 220 ]; then
  echo "Note: AGENTS.md is ${n} lines — approaching the 250 limit. Consider trimming soon." >&2
fi
exit 0
