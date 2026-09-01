# scripts/pg-tunnel-ensure.ps1 - make sure the Postgres SSH tunnel is up.
# If localhost:PG_LOCAL_PORT already listens -> "UP". Otherwise starts
# scripts/pg-tunnel.ps1 in its own minimized PowerShell window (survives this
# shell) and waits until the port answers. Exit 0 = tunnel up, 1 = failed.
#   .\scripts\pg-tunnel-ensure.ps1
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Read-DotEnv.ps1')
$cfg = Read-DotEnv
$port = if ($cfg['PG_LOCAL_PORT']) { [int]$cfg['PG_LOCAL_PORT'] } else { 5432 }

function Test-Port([int]$p) {
  $c = New-Object System.Net.Sockets.TcpClient
  try { $c.Connect('127.0.0.1', $p); $true } catch { $false } finally { $c.Dispose() }
}

if (Test-Port $port) { Write-Host "[pg-tunnel] UP on localhost:$port"; exit 0 }

$tunnel = Join-Path $PSScriptRoot 'pg-tunnel.ps1'
Write-Host "[pg-tunnel] not running - starting it in a separate window ..."
Start-Process powershell -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', "`"$tunnel`"" -WindowStyle Minimized | Out-Null

for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Milliseconds 750
  if (Test-Port $port) { Write-Host "[pg-tunnel] UP on localhost:$port (started, window minimized)"; exit 0 }
}
Write-Host "[pg-tunnel] FAILED: localhost:$port still closed after 15s - check the tunnel window (ssh key? host down?)"
exit 1
