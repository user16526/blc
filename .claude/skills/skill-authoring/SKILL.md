---
name: skill-authoring
description: Write a new skill (or improve one) by copying the shape of an existing working skill. Use when you've done the same thing more than twice and want to make it a reusable command — instead of re-deriving the procedure each time.
---

# Skill Authoring — copy a working shape, don't start blank

A skill is a reusable procedure your agents can run forever. The cheapest way to a
good one is NOT to write from scratch — it's to copy the structure of a skill that
already works in this repo and adapt it.

## When to make a skill
- You (or an agent) did the same multi-step thing 3+ times.
- A correction keeps recurring and a one-liner in `lessons.md` isn't enough.
- A procedure is worth getting right once and never re-deriving.
If it must hold 100% of the time, prefer a HOOK (`.claude/settings.json`) over a
skill. If it's a fact, not a procedure, route it via `memory-router` instead.

## How (the copy-the-shape method)
1. Find the closest existing skill in `.claude/skills/` (e.g. `deploy`, `pipeline`,
   `checkpoint`). Read its `SKILL.md`.
2. Copy its frontmatter + section shape into `.claude/skills/<name>/SKILL.md`.
3. Rewrite each section for the new procedure. Keep it tight — a skill is a
   checklist, not an essay.
4. The `description:` must say WHEN to use it (triggers), not just what it is —
   that's what makes Claude Code load it at the right moment.
5. Keep shared rules in ONE skill; don't paste the same paragraph into many.

## Frontmatter that triggers reliably
```
---
name: <kebab-case>
description: <one sentence: what it does> Use when <concrete trigger(s)>.
---
```
Bad description: "Helps with deployment." (no trigger)
Good description: "Safe deploy procedure. Use whenever I say deploy/ship/release."

## After writing
- Test it on a real task; if it didn't load when expected, sharpen the triggers.
- If it's project-specific, leave it here. If it's generic and reused across
  projects, that's a candidate for a plugin (see `.claude/rules/plugins-and-mcp.md`).
