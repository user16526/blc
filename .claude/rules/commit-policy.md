# Rule: Commit Policy

## Core Principle

The agent decides what to commit independently, without asking the user. Always stage specific files by name — never use `git add .`.

## Three Access Modes

### public / private-shared

Only "the product" reaches the remote — source code, user documentation, configs. Development artifacts stay local:
- Framework files (`.claude/rules/`, `.claude/skills/`, `.claude/hooks/`, etc.)
- Experiment files and test logs
- Session and migration logs

### private-solo

Everything commits except permanently forbidden items (see below).

### Unspecified

Defaults to `private-solo`, unless a public remote is detected (check `git remote get-url origin`).

The active mode is stored in `manifest.md` as `repo_access=`.

## Always-Forbidden Items (all modes)

Regardless of mode, these never commit:
- `.env*` files
- Credentials, keys, certificates (`.key`, `.pem`, `.p12`)
- Local databases (`*.db`, `*.sqlite`)
- Dependencies (`node_modules/`, `venv/`, `.venv/`)
- Build outputs (`dist/`, `build/`, `__pycache__/`)
- Personal agent settings

## Before Pushing

Verify that staged files contain no secrets or dev artifacts. Use `/housekeeping` before any `git push`.

## Switching Modes

Use `scripts/switch-repo-access.sh` to switch between modes. If the project already committed framework files as `private-solo` and is transitioning to `public`/`private-shared`, a simple `.gitignore` change is not enough — tracked files must be removed from the index.
