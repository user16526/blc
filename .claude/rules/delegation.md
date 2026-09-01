# Rule: Delegation to Subagents

## Task Assessment Criteria

When receiving a task — assess first:

**Do yourself (< 2 min):**
- Quick edits, small fixes
- Discussion, analysis, answering questions
- Changes < 50 lines of code
- Updating configs and meta-files

**Delegate to subagent (> 5 min):**
- Code > 50 lines
- New modules or components
- Refactoring existing code
- UI changes
- Research and documentation analysis
- Testing (unit, integration, E2E)

## Delegation Protocol

1. **Write a detailed spec** for the subagent:
   - Task context
   - Files to read
   - Expected result
   - Constraints

2. **Launch the subagent** (via Agent tool)

3. **Inform the user** what was launched (briefly)

4. **Parallelism:** launch multiple subagents simultaneously for independent tasks

## Required Cycle After Subagent Completion

**This is critical. Without this step, the subagent's work is lost.**

Subagents (`implementer`, `researcher`, `reviewer`) **do not commit** — that is the manager's responsibility. The `SubagentStop` hook will remind you, but you must execute the cycle.

After a subagent returns a result:

1. **Evaluate the result** — was the spec fulfilled correctly?
2. **git add + git commit** — record the subagent's changes (the manager commits, not the subagent)
3. **Update SNAPSHOT.md** — what changed, what is the current project state
4. **Integrate into context** — ensure your understanding of the project is current

**For parallel subagents:** do not wait for all to finish. Commit each subagent's result as it arrives. One subagent = one commit + one SNAPSHOT update.

If this cycle is skipped:
- After compaction the agent will "forget" the subagent's work
- In the next session — project state will be stale
- Drift risk: the agent may redo already-completed work

## Standard Subagents

| Agent | When to use |
|-------|-------------|
| `researcher` | Code search, web research, documentation analysis |
| `implementer` | Writing code > 50 lines, creating modules |
| `reviewer` | Code review, quality check, finding issues |
