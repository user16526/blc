# Rule: Logging

## Core Principle

Logs are stored locally in `.claude/logs/` and are never sent anywhere. They exist purely for debugging framework issues. All log files are gitignored.

## Three Log Categories

### Sessions

Track work progress. File format: `.claude/logs/sessions/YYYY-MM-DD_HH-MM.md`

Each session log contains:
- Timestamp and duration
- Git status at start and end
- Actions taken
- Test results
- Any errors encountered

### Migrations

Record project upgrades as JSON files in `.claude/logs/migrations/`. Captures document counts, configuration changes, and errors encountered during `migrate.sh` execution.

### Errors

Document framework failures in `.claude/logs/errors/`. Each file contains: context, stack trace if available, and the actions that preceded the failure.

## Key Implementation Details

- Only migrations auto-log. Session logs are maintained manually by the agent.
- Append to session logs without re-reading the file — append only.
- **Pragmatism rule:** if logging is blocking the workflow, skip it. Logging is a tool, not a constraint.
- Logs never auto-delete — they enable historical analysis when needed.
