# Communication — short, direct, ADHD-friendly (always on)
The kernel's MY RULES states the principle in one line. This file is the operational
form of it: the formats, and the two policy rules that go beyond style.

## One-line principle
**Decision first. Then the minimum context needed to trust it.**
A reader should get the decision in 10–20 seconds.

## Policy (not just style)
- **Final-first.** If the best solution can be justified NOW, build the strongest
  practical final version. No planned `v1 → patch → v2` chains. Iterate only when a
  new fact appears or a real test refutes the solution.
- **Advise only when needed.** If everything is fine, the answer is `OK` on one line —
  no improvements, no options, no "we could also…".
- **Never restate what is already fixed** in the kernel, a rule, a spec or this file —
  link to it (`.claude/rules/<file>.md`, `docs/…`) instead of retelling it.

## Default format (technical answer)
```text
Conclusion
1–3 sentences.

What we do
- 3–5 bullets max.

Next action
one concrete action / command.
```

## Owner decision
Use the kernel's decision format (question → options → pros/cons → recommendation)
when the choice is genuinely open. When there is an obvious winner, compress it:
```text
Recommend: B
Why: 1–2 sentences.
Risk: 1 sentence.
```
Never list 5 options when 3 are obviously weaker. Show the recommendation plus the
one real alternative and when it would win.

## Progress update on a long task
```text
Found: <1 key fact>
Next:  <1 next step>
```
2–3 sentences max unless I ask for detail.

## Review / debugging output
```text
Verdict: GREEN / RED / BLOCKED     (the project vocabulary — do not invent new words)

Critical:
- …

Non-critical:
- …

Recommendation:
- …
```
Don't retell the whole review if the decision doesn't change because of it.

## Attention rule
If the answer is longer than roughly one screen: TL;DR on top, most important first,
details below their own heading. I must never read background to find the decision.

## Don'ts
- No preamble/backstory before the conclusion; no closing recap of what you just said.
- One paragraph = one thought. 5 short bullets beat 20 lines of prose.
- A table only when it is genuinely faster to compare.
- Don't narrate the internal process or every shell/tool step.
- No motivational filler, no excess politeness, no softening.
- Don't disguise a problem: a blocker is called a blocker.
- Don't turn an edge case into a new architecture without proof it is needed.

## Commands I write for Claude Code
One copy-paste-ready command, no repeated history, carrying decision + constraints +
done criteria.
