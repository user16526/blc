# Lessons (durable)
Read at session start. One line per correction. Never delete — this is memory.
Format: `- [area] When X, do Y instead of Z. (why)`

<!-- - [auth] When checking login, also test token-refresh, not just happy path. (missed expiry once) -->
<!-- - [external-state] For any "which version / what does X use right now" question, query the LIVE system (scripts/check_live_state.py) before concluding — never reason from a note. Validate across the whole set, not one example. (stale notes cause re-fix loops + version conflicts) -->
- [sheriff] A guarantee that must hold 100% cannot live only in prose — encode it in executable policy (a script) and test it. (two sheriff passes each found a different forgotten isolation flag)
- [mockups] When building or reviewing a BLC page, use real asset `<img>` tags for weapon and case art — never CSS placeholder boxes. (index2.html was marked a negative result for exactly this)
- [mockups] Serve `mockups/main002/` over `python -m http.server 8099` before any Playwright screenshot — `file://` is blocked and fantaicon's cache-busting query strings only resolve through the server. (silent icon/font failures otherwise)
- [scope] BLC tasks stop at the spec: product/marketing/UX deliverables only, no BloodyCase application code. (Angular/Go are the dev team's)
- [design-system] A number that tracks a live value (prices, counts, online players) never becomes a locked design token — write the invariant instead ("the pill equals the cheapest case shown on the page"). (a hardcoded "From $0.06" silently went stale and read as a mockup bug for months)
- 2026-09-01 — A reported upstream defect can come back FIXED: before re-applying a
  local workaround at upgrade time, check whether the new CHANGELOG closes it. v8.3.14
  shipped BLC's own D1/D2 fixes, so the right merge was to DELETE our divergence, not
  defend it — and the risk that guarded it (R1) dissolved instead of being mitigated.
- 2026-09-01 — "Take the template" is wrong for any file where the template's own
  content is unchanged and we only APPENDED (.gitignore, docs/ROLES.md, settings.json):
  an overwrite there deletes project content while looking like an update. Diff before
  copying, always; classify per file, never per directory.
- 2026-09-01 — When a template turns a hand-written file into a GENERATED view
  (current.md ← current.json), seed the generator from the old file BEFORE the first
  render, or the first patch silently discards everything that was in it.
- [release] Verify a release FROM its built artifact (unpack, then run the suites inside it), never from the working tree — the tree is where verification RUNS, so its runtime residue (.env from setup.sh, handoffs/, rotted literals) is exactly what a tree-side check cannot see. Encoded: scripts/release-check.sh is the release gate. (2026-09-01: D4 stray .env and a rotted START-HERE literal both passed tree checks and shipped)
- [powershell] Scripts for Windows PowerShell 5.1 must be ASCII-only (or UTF-8 WITH BOM): a BOM-less em-dash inside a string is read as ANSI and breaks the string terminator -> parse errors. Check with grep -P "[^\x00-\x7F]". (pg-tunnel.ps1, 2026-09-01)
- [mcp] crystaldba postgres-mcp needs `uvx --with "mcp<2"`: it imports mcp.server.fastmcp, removed in mcp 2.x. (2026-09-01)
- [cost] A Skill load or a big Read enters the context ONCE but is re-read on every later API call; a 90k-token Read in a 190-call session cost ~$7 of cache reads by itself. Before Read/Skill on anything >10k tokens: grep/head the part needed, or send it to a subagent. Measure with scripts/session-cost.py. (2026-09-02)
- [cost] Transcript usage records repeat per content block: dedupe by message.id before summing tokens, else totals are 2-3x too high. (2026-09-02)
