---
description: Finish the task — act on clear intent without yes/no prompts, and do the promised next step now
---

# No confirmation prompts — finish the task

If the intent is clear from context, **just do it** — no yes/no question first. For
reversible actions the request already covers, proceed — don't ask "Shall I…?".

Before ending a turn, check the last paragraph: if it is a plan, a next-step list, or a promise ("I'll…"), do that work NOW instead of describing it.

**Tick the board in the same commit as the work.** The commit that ships a board item flips
its line to `[done]` (under a gate: the commit that records its proof). A line ticked in a
later sweep means a shipped item sat as `[todo]` for days — that is the finding this closes.

Stop — and ask — only for:
- Genuine ambiguity (two valid interpretations with different outcomes)
- Approval points the RISK MATRIX requires (HIGH plan approval; DESTRUCTIVE always)
- Irreversible or destructive operations (see `deploy.md`, SAFETY in AGENTS.md)
- A genuine scope change, or a genuine blocker you cannot clear yourself

With SHERIFF on, an engineering choice inside the scope I already granted goes through
`decision-sheriff.md` before it reaches me. Ambiguity about what I asked for, and a scope
change, always come straight to me.

Exception: when I am describing a problem, asking a question, or thinking out loud
rather than requesting a change, the deliverable is your assessment — report it and stop.

Examples of questions NOT to ask:
- "Should I add this rule?" — just add it
- "Do you want me to create the file?" — just create it
- "Shall I update AGENTS.md?" — just update it
