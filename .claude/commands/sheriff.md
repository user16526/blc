Run an on-demand SHERIFF check of the current step (triggers: /sheriff, or the
human saying sheriff / шериф / шер / шері / шері-мен and asking to check).
Read `.claude/skills/cross-review/SKILL.md` first and follow it. Then:

1. **Scope** — the current step's diff (this task's files vs the task's start
   point). If the internal loop isn't GREEN yet, say so and ask whether to
   proceed anyway. A diff touching the cross-review mechanism itself is always
   in scope (SKILL.md, "On itself").
2. **Pick the reviewer — cross-vendor is the point.** Read the dated role
   mapping in `.agent/state/decisions.md`. The sheriff MUST be a different
   vendor than the AUTHOR of the diff; this project runs Codex too (`AGENTS.md`),
   so the author is not always Claude. Author Claude → sheriff Codex (the
   wrapper below). Author Codex → sheriff a fresh Claude session with zero task
   context; a cold subagent is NOT enough, it inherits the project contract.
3. **Run it through the wrapper. Never build the codex command by hand.**

   ```
   printf '%s' "$ACCEPTANCE_CRITERIA_AND_DIFF" \
     | bash scripts/sheriff-review.sh --author claude
   ```

   Pipe the acceptance criteria + the diff on stdin; the wrapper prepends the
   canonical prompt itself and prints the findings path on its last line. It
   owns every boundary — isolated scratch dirs outside the repo, an empty work
   root (`-C`), the read-only sandbox, the `-o` path — and refuses loudly rather
   than run a weakened review. Read the exit code: `4` same-vendor, `3` a path
   inside the repo, `5` the CLI lacks a required isolation flag, `6` no CLI.
   On `5`/`6` automation is gated but the review is NOT: the wrapper prints a
   manual copy-paste package — hand it to a different-vendor reviewer and STOP
   until the findings come back.

   Do not reconstruct the flag set from memory. Each boundary in it was missing
   once, and each cost a review round to find.
4. **Process findings** per the skill: ✅ fix silently / 🧪 settle by test /
   ❌ ≤2 with falsifiable reasons. Run the full test suite.
5. **Unresolved ❌** → print the filled-in, anonymized arbiter package
   (`prompts/arbiter.md`) for the owner to paste into a fresh arbiter chat.
   STOP until the verdict returns; execute it without appeal.
6. **Record** — append `cross_review: closed | n/a` + a one-line findings
   summary to the run report.

Two checks outside a review, in escalating strength:
- `bash scripts/sheriff-review.sh --probe` — is automation available on this
  machine? No author, no diff; exits 0 / 5 / 6 like a real run. Run it after an
  install or a template merge.
- `bash scripts/integration/sheriff-isolation-live.sh` — does the isolation still
  BEHAVE? Run it after a codex-cli version bump or any change to the wrapper. The
  gate proves the flags are passed and the probe proves they exist; only this
  proves they still work.
