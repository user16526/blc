---
paths:
  - "docs/**"
  - "tasks/**"
  - "**/*-tz*.md"
  - "**/*spec*.md"
  - "**/*report*.md"
---
# Artifact Versioning (R1)
<!-- Adapted from the SE guide's hard rule R1. Loads only when working with docs/specs/reports. -->

Specs, briefs, plans, reports, mockups — name them with a full timestamp so the
newest is always obvious and nothing gets silently overwritten:

`{name}_{YYYY-MM-DD}_{HHMM}_v{N}.{ext}`
e.g. `landing-brief_2026-05-30_1430_v2.md`

- Never name a file `final`, `latest`, or `new` — in a week you won't know which is which.
- `v{N}` = which iteration (v1 → v2 after a review). Timestamp = when.
- Don't delete old versions — keep them beside the new one so you can diff / roll back.
- Exception: files regenerated every time (e.g. an export CSV) can skip the version
  but should carry a `generated_at` value inside the file.
