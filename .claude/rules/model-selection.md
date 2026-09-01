# Model selection — the lineup decays, so ask, don't assume (always on)
<!-- Same logic as verify-external-state, applied to the model lineup itself.
     No `paths:` frontmatter: model choices can come up in any work. -->

The set of available models and their relative strengths changes. Any model name
remembered from training, old notes, or an old config is a POINTER, not truth.

## When the choice matters, do two things in order
Triggers: configuring a new agent/subagent, changing the reviewer roster,
starting a long or expensive run, or the human asks "which model".
1. **Check the lineup live first** (`/model` list, official docs) — never recycle
   names from memory.
2. **Then ask the human** using the standard decision format (question → options →
   pros/cons → recommendation). Record the agreed role→model mapping in
   `decisions.md` WITH a date — a dated entry older than the lineup is a pointer too.

## Match the model to the PHASE, not just the task
Thinking-heavy phases (brainstorm, spec, plan, review) deserve the strongest model.
Executing an already-approved task list can usually take a cheaper model in a
FRESH context (pairs with the context-hygiene rule). Propose the split; the human
decides the cost/quality trade.

## Don't
Don't hardcode a model name into agents/skills as eternal truth, and don't silently
"upgrade" or "downgrade" a model mid-project without saying so.
