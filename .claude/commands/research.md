---
description: Research the current state of a topic BEFORE planning, so the plan isn't built on stale training knowledge.
---
Before planning anything non-trivial, research the CURRENT state of the topic I name
(library choice, API, approach, competitor, ecosystem). Use WebSearch/WebFetch and
the repo itself. Prefer recent, primary sources; note the date of what you find.

Output a short brief: what the current options are, the tradeoffs that matter for
THIS project, and a recommendation with one line of why — then stop for my steer
before /pipeline turns it into a plan.

This is the same discipline as `.claude/rules/verify-external-state.md`: don't
reason from six-month-old training data when the live answer is one search away.
For facts about OUR live systems (deployed version, published config), run
`scripts/check_live_state.py`, not a web search.
