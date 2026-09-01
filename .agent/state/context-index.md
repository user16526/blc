# Context Index — where everything lives
<!-- The map the kernel points to. Update when you add a capsule/doc. -->

- Kernel rules .......... CLAUDE.md (CORE block, protected)
- What's true now ....... .agent/state/current.json (authoritative, merged ONLY
                          via scripts/state-patch.py) + current.md (rendered view)
- State schema .......... .agent/state/state-schema.json (skill: state-patch)
- Compaction handoff .... .agent/state/handoff.md (auto, gitignored; resurfaced on resume)
- Decisions ............. .agent/state/decisions.md (append-only)
- Risks ................. .agent/state/risks.md
- Open loops ............ .agent/state/open-loops.md
- Domain memory ......... .agent/capsules/*.md
    · bloodycase-product.md ....... platform, game modes, monetization, scope limit
    · mockups-design-system.md .... mockup conventions + the APPROVED design system
- Lessons ............... tasks/lessons.md
- Run evidence .......... _reports/runs/ (latest.json + dated .md)
- Roles catalog ......... docs/ROLES.md
- Client material ....... designs/, weeekly-co-founder-calls/, *.docx / *.xlsx (root) — read-only
- Mockups ............... mockups/main002/ (+ mockups/BRIEF.md, mockups/competitors/)
- Retired pre-v8 files .. temp/retired-pre-v8/ (gitignored; the real copy is branch `main`)
