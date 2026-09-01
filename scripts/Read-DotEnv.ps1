# scripts/Read-DotEnv.ps1 - dot-source, then call Read-DotEnv to get a hashtable of KEY=value
# pairs from the project .env (gitignored). Comments and blank lines are skipped;
# surrounding single/double quotes are stripped. Values are never printed.
function Read-DotEnv([string]$Path) {
  if (-not $Path) { $Path = Join-Path (Split-Path -Parent $PSScriptRoot) '.env' }
  if (-not (Test-Path $Path)) { throw ".env not found at $Path - copy .env.example to .env and fill the PG_* keys" }
  $cfg = @{}
  foreach ($raw in Get-Content $Path) {
    $line = $raw.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { continue }
    $i = $line.IndexOf('=')
    if ($i -lt 1) { continue }
    $k = $line.Substring(0, $i).Trim()
    $v = $line.Substring($i + 1).Trim()
    if ($v.Length -ge 2 -and (($v[0] -eq '"' -and $v[-1] -eq '"') -or ($v[0] -eq "'" -and $v[-1] -eq "'"))) {
      $v = $v.Substring(1, $v.Length - 2)
    }
    $cfg[$k] = $v
  }
  return $cfg
}
