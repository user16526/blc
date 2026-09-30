# Research Brief Template

One brief per `Kind: choice` step. Copy to `specs/NNN-slug/research/Sxx.md` (≤40 lines).
Written by the fresh-context researcher of `/write-spec` step 2a; the session copies its
recommendation into the step's Deliverable / DoD. The gate greps the line prefixes below
(`Recommendation:`, `Evidence:` + a `- ` line, `What would change this recommendation:`,
`Confidence:`) — keep them exactly.

```markdown
# Sxx — <the question, one sentence>
Options: A <…> | B <…> | (C <…>)
Recommendation: <A|B|C> — <one sentence why>
Evidence:
- <claim> — <URL, accessed YYYY-MM-DD> | <repo path / command + output> | unverified
What would change this recommendation: <one concrete check or fact>
Rejected because: B — <…>; C — <…>
Confidence: high | medium | low
Spent: <n> searches, <n> fetches, <n> experiments
```

- Every Evidence line carries a source or the word `unverified`. A claim resting on a
  blog or forum alone is `unverified`.
- `What would change this recommendation:` names a checkable thing, never "new information".
- No `Recommendation:` line = invalid brief. A survey is not a brief.
