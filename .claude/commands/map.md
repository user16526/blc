# /map — project map snapshot

Run `python3 scripts/project-map.py` from the project root. It writes
`docs/project-map.html` (visual: rooms = folders, workers = agents) and
`docs/project-map.txt` (same map for terminals/Codex).

Then: show the user the TXT map inline and give the path to the HTML file.
If it failed, show the error — don't fake a map.

Remember and say it plainly: the map is a SNAPSHOT of recorded state
(board.md, current.md), not live telemetry. Stale board → stale map;
suggest a board cleanup if what you see contradicts reality.
