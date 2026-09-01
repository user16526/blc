# Rule: Context Management

## The Problem

Context quality degrades at around 50–60% of the context window capacity, risking lost work or code errors.

## Prevention Strategy

- **Commit after every 20 tool calls** with descriptive messages
- **Update SNAPSHOT.md regularly** to preserve project state
- The `post-tool-checkpoint.sh` hook reminds you automatically at every 20-call boundary

## Degradation Indicators

Watch for:
- Repeating previously discussed topics
- Losing track of earlier session work
- Contradicting decisions already made

When you notice these patterns, recover by reading `.claude/SNAPSHOT.md`, `CLAUDE.md`, and recent commit history (`git log --oneline -15`).

## Commit Discipline

"Commit frequently, commit atomically." Each commit should capture a coherent unit of work. This minimizes data loss during context compaction.

## Compaction Hooks

Two automated processes bracket compaction:

**pre-compact** (auto): Commits already-tracked file changes and updates the SNAPSHOT timestamp. Does **not** auto-stage untracked files (to avoid capturing secrets).

**post-compact** (auto): Outputs SNAPSHOT.md contents and recent commits. Read `CLAUDE.md` to fully restore context before resuming work.

## Long Sessions (> 30 minutes)

- Commit and update SNAPSHOT every 15 minutes
- Perform full context verification before starting any major task
- Never assume memory of earlier session steps without checking SNAPSHOT and git log
