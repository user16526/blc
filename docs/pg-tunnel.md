# Remote Postgres for Claude Code — SSH tunnel + read-only MCP

Why: direct SSH sessions to the DB host keep dropping, so the DB is brought to this
machine through a self-healing SSH port-forward and read by Claude via an MCP server.
Nothing here writes to BloodyCase data (restricted mode = read-only transactions).

## One-time setup
1. `.env` (gitignored): fill the `PG_*` and `PGUSER/PGPASSWORD/PGDATABASE` keys
   listed in `.env.example`.
2. Make sure the SSH key works without a prompt:
   `ssh -o BatchMode=yes <user>@<host> 'echo ok'`
3. Register the MCP server (stores the connection string machine-locally in
   `~/.claude.json`, scope `local`):
   `.\scripts\pg-mcp-register.ps1`

## Every session
1. Terminal A, leave it open: `.\scripts\pg-tunnel.ps1`
   (reconnects automatically when the SSH session drops; Ctrl+C stops it).
2. Start Claude Code in `D:\claude\blc`. `claude mcp list` should show `postgres` connected.
   MCP servers connect at launch, so the tunnel must be up BEFORE Claude Code starts.

## Verify
- Tunnel: `Test-NetConnection 127.0.0.1 -Port 5432` → `TcpTestSucceeded : True`
- MCP: `claude mcp list` → `postgres … ✔ Connected`
- In Claude: ask for `SELECT version();` via the postgres tool.

## Read-only role (ask the dev team / DevOps to create it; recommended)
```sql
CREATE ROLE claude_ro WITH LOGIN PASSWORD '<strong password>';
GRANT CONNECT ON DATABASE <db> TO claude_ro;
GRANT USAGE ON SCHEMA public TO claude_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO claude_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO claude_ro;
```

## Files
- `scripts/pg-tunnel.ps1` — the port-forward with reconnect loop
- `scripts/pg-mcp-register.ps1` — `claude mcp add` wrapper (`uvx --with "mcp<2" postgres-mcp --access-mode=restricted`)
- `scripts/Read-DotEnv.ps1` — shared `.env` parser
- Secrets live only in `.env` and `~/.claude.json`; never in the repo.
