# scripts/pg-mcp-register.ps1 - register the Postgres MCP server in Claude Code.
#
# Server: Postgres MCP Pro (crystaldba/postgres-mcp) via uvx (pinned mcp<2: the package
#         still imports mcp.server.fastmcp, removed in mcp 2.x), --access-mode=restricted
#         = read-only transactions + SQL parsing + statement timeout. Fits the BLC
#         scope limit (analysis only, never writes to the product DB).
# Scope:  local  -> stored in ~/.claude.json for THIS machine + project only.
#         The connection string (with password) never enters the repo.
# Reads PGUSER / PGPASSWORD / PGDATABASE / PG_LOCAL_PORT from .env (gitignored).
#
#   .\scripts\pg-mcp-register.ps1     # (re)register; then restart Claude Code
#
# Prereq: the tunnel is up (.\scripts\pg-tunnel.ps1 in another terminal).
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Read-DotEnv.ps1')
$cfg = Read-DotEnv

foreach ($k in 'PGUSER', 'PGPASSWORD', 'PGDATABASE') {
  if (-not $cfg.ContainsKey($k) -or $cfg[$k] -eq '') { throw "$k must be set in .env (see .env.example)" }
}
$localPort = if ($cfg['PG_LOCAL_PORT']) { $cfg['PG_LOCAL_PORT'] } else { '5432' }
$user = [uri]::EscapeDataString($cfg['PGUSER'])
$pass = [uri]::EscapeDataString($cfg['PGPASSWORD'])
$uri  = "postgresql://${user}:${pass}@127.0.0.1:${localPort}/$($cfg['PGDATABASE'])"

if (-not (Get-Command uvx -ErrorAction SilentlyContinue)) { throw 'uvx not found on PATH (install uv: https://docs.astral.sh/uv/)' }
Write-Host '[pg-mcp] warming uvx cache for postgres-mcp ...'
& uvx --with "mcp<2" postgres-mcp --help | Select-Object -First 1

# Replace any previous registration (ignore "not found").
try { & claude mcp remove -s local postgres 2>$null | Out-Null } catch {}
Write-Host '[pg-mcp] registering "postgres" (scope local, access-mode restricted)'
& claude mcp add postgres -s local -e "DATABASE_URI=$uri" -- uvx --with "mcp<2" postgres-mcp --access-mode=restricted
if ($LASTEXITCODE -ne 0) { throw "claude mcp add failed ($LASTEXITCODE)" }

Write-Host '[pg-mcp] done. Restart Claude Code; check with: claude mcp list'
