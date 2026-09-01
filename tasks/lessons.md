# Lessons (durable)
Read at session start. One line per correction. Never delete — this is memory.
Format: `- [area] When X, do Y instead of Z. (why)`

<!-- - [auth] When checking login, also test token-refresh, not just happy path. (missed expiry once) -->
<!-- - [external-state] For any "which version / what does X use right now" question, query the LIVE system (scripts/check_live_state.py) before concluding — never reason from a note. Validate across the whole set, not one example. (stale notes cause re-fix loops + version conflicts) -->
- [sheriff] A guarantee that must hold 100% cannot live only in prose — encode it in executable policy (a script) and test it. (two sheriff passes each found a different forgotten isolation flag)
- [mockups] When building or reviewing a BLC page, use real asset `<img>` tags for weapon and case art — never CSS placeholder boxes. (index2.html was marked a negative result for exactly this)
- [mockups] Serve `mockups/main002/` over `python -m http.server 8099` before any Playwright screenshot — `file://` is blocked and fantaicon's cache-busting query strings only resolve through the server. (silent icon/font failures otherwise)
- [scope] BLC tasks stop at the spec: product/marketing/UX deliverables only, no BloodyCase application code. (Angular/Go are the dev team's)
