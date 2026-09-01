---
name: housekeeping
description: Pre-push maintenance — sync docs, update CHANGELOG, bump version, audit secrets
tools: [Read, Edit, Write, Glob, Grep, Bash]
disableModelInvocation: false
---

# Skill: Housekeeping

Run this before any `git push`. Modifies only documentation and metadata — never project code.

## Steps

1. **Sync README.md** — verify installation instructions, API descriptions, and code examples match the actual implementation. Correct any drift automatically.

2. **Update CHANGELOG.md** — identify undocumented commits since the last version tag. Add them following Keep a Changelog conventions. If no CHANGELOG exists and the project has 10+ commits, create one.

3. **Bump version** — analyze changes to determine if a major, minor, or patch version increment is warranted. Update `package.json` or `pyproject.toml` accordingly.

4. **Security audit** — scan tracked files for sensitive patterns: `.env*`, `*.key`, `*.pem` files, build directories. Move any found items to `.gitignore`.

5. **Update framework metadata** — refresh `.claude/SNAPSHOT.md` and `manifest.md` to reflect current project state.

6. **Detect documentation drift** — identify mismatches between documented APIs and actual code. Correct documentation automatically.

## Constraints

- Complete within 3 minutes
- Never modify project source code — only documentation and metadata
- The agent must invoke housekeeping before `git push` — this is not automatic
