---
name: testing
description: Run unit and integration tests, report results
tools: [Read, Glob, Grep, Bash]
disableModelInvocation: false
---

# Skill: Testing

## Project Detection

Identify project type by checking for config files:
- `package.json` → Node.js
- `pyproject.toml`, `pytest.ini`, `setup.py` → Python

## Test Execution

| Project type | Command |
|---|---|
| Node.js | `npm test` |
| Python | `python3 -m pytest tests/ -v` |

## Result Interpretation

- **All pass** — report count of passing tests
- **Failures** — list failing tests with error messages and recommendations
- **No tests found** — suggest creating baseline coverage

## When to Run

- After each significant commit
- As part of `/finish` workflow
- On explicit user request
- After the `implementer` subagent returns results

## Coverage (optional)

If configured:
- Node.js: Jest coverage (`--coverage`)
- Python: `pytest --cov` with coverage plugin

Display summary metrics when available.
