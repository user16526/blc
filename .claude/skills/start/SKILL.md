---
name: start
description: Session initialization — load project state and report readiness
tools: [Read, Glob, Grep, Bash]
disableModelInvocation: false
---

# Skill: Start Session

## Steps (execute in order)

1. **Read SNAPSHOT.md** — assess current project state. If the file does not exist, create it from the template.

2. **Read CLAUDE.md** — load project context (purpose, architecture, contracts).

3. **Check git status** — run `git status --short` and `git log --oneline -10` to see recent history.

4. **Verify framework version** — non-blocking background check; do not halt if it fails.

5. **Create session log** — in `.claude/logs/sessions/` with current timestamp and initial state.

6. **Report to user** — brief (5–7 lines) covering:
   - Current project status
   - What was done in the prior session
   - Pending tasks / next steps
   - Readiness to receive a new spec

## Constraints

- Do NOT display file contents to the user
- Do NOT run tests (that is `/finish`)
- Do NOT auto-commit uncommitted changes
- Complete within 30 seconds

## Result

After completion, the agent is ready to receive task specifications from the user, with full project context loaded.
