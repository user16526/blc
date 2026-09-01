---
name: finish
description: Session completion — run tests, commit, update SNAPSHOT, report results
tools: [Read, Edit, Write, Glob, Grep, Bash]
disableModelInvocation: false
---

# Skill: Finish Session

## Steps (execute in order)

1. **Run tests** — detect project type and run appropriate command:
   - Node.js: `npm test`
   - Python: `python3 -m pytest tests/ -v`
   - Document failures; do not block completion if tests fail

2. **Check git status** — `git status --short` to identify modified files.

3. **Stage permitted files** — add files by name (never `git add .`). Skip permanently forbidden items (`.env`, `*.key`, `*.db`, `node_modules/`, etc.).

4. **Commit** — with a descriptive message summarizing the session's work.

5. **Update SNAPSHOT.md** — record:
   - What was accomplished this session
   - What is still in progress
   - Next steps
   - Known issues
   - Current timestamp

6. **Handle repo access mode** — check `manifest.md` for `repo_access`. In `public`/`private-shared` mode, do not commit framework files.

7. **Write session log** — append to `.claude/logs/sessions/YYYY-MM-DD_HH-MM.md`:
   - Test results
   - Commit hash(es)
   - Errors encountered
   - Session duration

8. **Report to user** — 5–7 lines covering:
   - Completed work
   - Test results
   - Commit hash
   - Remaining tasks

## Constraints

- Do NOT auto-push to remote
- Complete within 2 minutes
- Assess each modified file's category before staging
