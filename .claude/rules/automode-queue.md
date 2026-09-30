# Automode queue — what may be started without asking (always on)

Only relevant when automode is ON, or inside a `/run-spec` run. Otherwise nothing here
applies.

The kernel's AUTOMODE paragraph says: after a GREEN gate, take the next eligible board
item without asking. It points here for everything that sentence leans on — *eligible*,
the claim, the budget and the stop list — so each is written ONCE, outside the
hash-protected block, and the kernel and this file can never drift apart. A stop
condition that has to be judged is not a stop condition. **Selection is opt-in: if you
have to reason about whether an item qualifies, it does not.**

## Eligible item
A line in `tasks/board.md` that

1. begins `- [todo]`,
2. carries the literal tag `@auto`, and
3. carries a `DoD:` clause naming the proof that closes it.

Anything else is INELIGIBLE. That includes every untagged item, every backlog entry,
anything naming the owner, and anything you would classify above the NORMAL row
(inside `/run-spec`: above the row the approved plan recorded for that step, `row:`).
Order is file order among tagged items.

An untagged board is an empty queue, and that is the correct default. Tagging is how
the owner says "you may start this without me"; nothing infers it on their behalf.

A line that also carries `@spec:<id>` belongs to the `/run-spec` run that wrote it after
the owner approved that spec's plan. Only that run takes it; the plain automode queue
skips it.

## Claim it, or leave it alone
Before starting, flip the line to `- [doing] … @auto` and commit that one line. An item
already `[doing]` belongs to another session — skip it, never take it over. On GREEN,
flip it to `- [done]` with the report path. Without the claim, two concurrent sessions
take the same item, or one session re-takes the item it just finished.

## Before dispatching anyone
Read THIS project's `.claude/agents/` roster first (`orchestration` skill, step 0).
Builder and reviewers are roster names only.

## The stop list — the only one
Stop, and ask or report, on ANY of these. The kernel paragraph points here instead of
carrying its own copy, so this is the list to edit.

Where the queue ends
- **End of the board** — no eligible item left. For a `/run-spec` run: every step its
  approval marker lists is `[done]`.
- **The budget is spent** (below).

What the item is
- **No done-criteria** — no `DoD:` clause naming the proof that closes it.
- **A HIGH item, or anything you would put above NORMAL.** A board records no row, so
  the moment you find yourself classifying an item upward, that is the stop.
  Inside `/run-spec` the approved plan did record one (`row:`): the plan OK covers the
  step up to THAT row, and the stop is a step you would put above it.
- **The DESTRUCTIVE row** — money, prod, secrets, work-erasing. Automode never shifts it,
  and no spec step carries it.
- **An ambiguous item** — two readings with different outcomes.
- **A deploy, or any write to a live box.** The deploy rule needs the owner's go-ahead
  for THAT deploy, and automode never overrides it.
- **Anything that spends money, or changes cloud/DNS/provider config.**

What the work needs
- **A precondition you cannot satisfy yourself** — sudo, another team, an owner-only
  secret.
- **A role that is not on the active roster** — only in `_archive/`, or nowhere.
  Re-activating a role is a team-proposal decision, never a substitution.
- **A go-ahead that was given to a different session** — it does not carry over
  (`.claude/rules/go-ahead-scope.md`) — except a plan OK recorded on the board with its
  plan hash, which `/run-spec` step 3 verifies instead of re-asking.

What happened
- **An orchestration stop condition** — a RED not auto-fixable in ≤2 loops, anything
  irreversible, a security finding, scope drift (`orchestration` skill).
- **The kernel's every-row stops** — any RED, any "done" without evidence, anything
  irreversible, a BLOCKED gate.
- **The item did not reach GREEN in one gate cycle** — stop rather than iterating
  toward it.

Asking is always allowed here. The kernel's "plan-pause question only where the matrix
requires approval" governs *plan pauses*, never a genuine blocker.

## Budget
At most **3 items per session** for the plain queue, then stop and report — long
autonomous runs are worth having, unbounded ones are not.

A `/run-spec` run's budget is its approved spec instead: exactly the steps its approval
marker on the board lists, taken strictly in step order, never an item added afterwards.
It does not count against the 3, and it ends at the end of the spec.

Automode never restarts itself. After `/clear`, a compaction, or a pause, it resumes
only from an explicit human turn — otherwise auto-resume and auto-advance form a loop
whose only exit is closing the session. A `/run-spec` run continues through a compaction
of the same session; after `/clear`, a restart or a pause it resumes only from an
explicit `/run-spec <spec>`. The plan OK recorded in the board marker holds while the spec
hashes as approved (`/run-spec` step 3, `go-ahead-scope.md`); a changed spec asks a
one-line OK on the remaining steps.
