# scripts/pg-tunnel.ps1 - SSH port-forward of the remote BloodyCase Postgres to localhost.
#
# Reads PG_SSH_HOST / PG_SSH_USER / PG_SSH_PORT / PG_LOCAL_PORT / PG_REMOTE_HOST /
# PG_REMOTE_PORT from .env (gitignored; keys documented in .env.example).
# Keeps the tunnel alive: reconnects with backoff whenever the SSH session drops.
#
#   .\scripts\pg-tunnel.ps1          # run in its own terminal, leave it open
#   .\scripts\pg-tunnel.ps1 -Once    # single attempt, exit with ssh's code (for testing)
#
# Auth is by SSH key (~/.ssh/id_ed25519). No password is read or stored here.
param([switch]$Once)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Read-DotEnv.ps1')
$cfg = Read-DotEnv

function Get-Cfg([string]$k, $default) {
  if ($cfg.ContainsKey($k) -and $cfg[$k] -ne '') { return $cfg[$k] } else { return $default }
}

$sshHost    = Get-Cfg 'PG_SSH_HOST'    $null
$sshUser    = Get-Cfg 'PG_SSH_USER'    $null
if (-not $sshHost -or -not $sshUser) { throw 'PG_SSH_HOST and PG_SSH_USER must be set in .env (see .env.example)' }
$sshPort    = Get-Cfg 'PG_SSH_PORT'    '22'
$localPort  = [int](Get-Cfg 'PG_LOCAL_PORT'  '5432')
$remoteHost = Get-Cfg 'PG_REMOTE_HOST' '127.0.0.1'
$remotePort = Get-Cfg 'PG_REMOTE_PORT' '5432'

$busy = Get-NetTCPConnection -LocalPort $localPort -State Listen -ErrorAction SilentlyContinue
if ($busy) {
  $owner = (Get-Process -Id $busy[0].OwningProcess -ErrorAction SilentlyContinue).ProcessName
  throw "localhost:$localPort is already listening (process: $owner). Another tunnel or a local Postgres? Stop it or change PG_LOCAL_PORT."
}

$sshArgs = @(
  '-N',
  '-p', $sshPort,
  '-L', "127.0.0.1:${localPort}:${remoteHost}:${remotePort}",
  '-o', 'ExitOnForwardFailure=yes',
  '-o', 'ServerAliveInterval=30',
  '-o', 'ServerAliveCountMax=3',
  '-o', 'ConnectTimeout=15',
  '-o', 'BatchMode=yes',
  "$sshUser@$sshHost"
)

Write-Host "[pg-tunnel] localhost:$localPort -> ${sshUser}@${sshHost}:$sshPort -> ${remoteHost}:$remotePort   (Ctrl+C to stop)"
$delay = 2
while ($true) {
  $start = Get-Date
  & ssh @sshArgs
  $code = $LASTEXITCODE
  if ($Once) { exit $code }
  # Long-lived session that dropped -> reconnect fast; immediate failure -> back off (max 60s).
  if (((Get-Date) - $start).TotalSeconds -gt 60) { $delay = 2 } else { $delay = [Math]::Min($delay * 2, 60) }
  Write-Host "[pg-tunnel] ssh exited ($code) at $(Get-Date -Format 'HH:mm:ss') - reconnecting in ${delay}s"
  Start-Sleep -Seconds $delay
}
