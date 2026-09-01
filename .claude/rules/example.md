---
paths:
  - "src/api/**/*.ts"
  - "**/*.sql"
---
# Example path-scoped rule (delete or replace)

This file loads into context ONLY when Claude works with files matching `paths`
above — not every session. That is what actually saves context (unlike @imports).

Put domain rules that apply to a subset of files here. Examples:
- API: validate all input; use the standard error response shape.
- SQL: parameterized queries only; no string interpolation.

Make one file per topic (e.g. `frontend.md`, `infra.md`, `tracking.md`).
Note (current Claude Code quirks): path-scoped rules load on Read, not always on
Write/create; and `paths:` in USER-level (~/.claude/rules/) rules is unreliable —
keep them PROJECT-level (here in `.claude/rules/`).
