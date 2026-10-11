#Requires -Version 5.1
<#
.SYNOPSIS
  One-time (re-runnable) Podman Desktop / WSL fixes so the Local stack is reachable on 127.0.0.1.

.DESCRIPTION
  - Writes containers.conf (pids_limit / systemd cgroup) under AppData and .config
  - Checks that a Compose provider is on PATH
  - Warns if WSL mirrored networking is enabled (breaks podman machine)
  - Refreshes netsh portproxy 127.0.0.1 -> WSL eth0 (requires Administrator)

  See docs/PODMAN_WINDOWS.md
#>
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Write-ContainersConf {
  param([string]$Path)
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  $lines = @(
    "[containers]"
    "pids_limit = 0"
    ""
    "[engine]"
    'cgroup_manager = "systemd"'
    ""
  )
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($Path, ($lines -join "`n"), $utf8)
  Write-Host "Wrote $Path"
}

Write-Host "==> containers.conf (cgroup / pids)"
Write-ContainersConf -Path (Join-Path $env:APPDATA "containers\containers.conf")
Write-ContainersConf -Path (Join-Path $env:USERPROFILE ".config\containers\containers.conf")

Write-Host ""
Write-Host "==> Compose provider"
$compose = Get-Command docker-compose, podman-compose -ErrorAction SilentlyContinue |
  Where-Object { $_.Source -notmatch [regex]::Escape("\WindowsApps\") } |
  Select-Object -First 1
if (-not $compose) {
  $stub = Get-Command docker-compose -ErrorAction SilentlyContinue
  if ($stub) {
    Write-Warning "Only WindowsApps docker-compose stub found at $($stub.Source). Prefer: winget install Docker.DockerCompose"
  }
  else {
    Write-Warning "No compose provider on PATH. Install one, then reopen the terminal: winget install Docker.DockerCompose"
  }
}
else {
  Write-Host "OK: $($compose.Source)"
}

Write-Host ""
Write-Host "==> WSL config"
$wslConfig = Join-Path $env:USERPROFILE ".wslconfig"
if (Test-Path $wslConfig) {
  $raw = Get-Content $wslConfig -Raw
  if ($raw -match "networkingMode\s*=\s*mirrored") {
    Write-Warning ".wslconfig enables networkingMode=mirrored - this often breaks podman machine SSH/API. Remove that line (see docs/PODMAN_WINDOWS.md)."
  }
  else {
    Write-Host "OK: mirrored networking not enabled in .wslconfig"
  }
}
else {
  Write-Host "OK: no .wslconfig (default NAT is fine)"
}

Write-Host ""
Write-Host "==> Localhost portproxy (127.0.0.1)"
if (-not $isAdmin) {
  Write-Warning "Not elevated - skipping portproxy. Re-run this script (or ./scripts/Sync-LocalhostPorts.ps1) as Administrator so Rabbit/SQL/Authentik work on 127.0.0.1."
  Write-Host ""
  Write-Host "After elevation:"
  Write-Host "  cd $PWD"
  Write-Host "  ./scripts/Sync-LocalhostPorts.ps1"
  Write-Host ""
  exit 0
}

& (Join-Path $PSScriptRoot "Sync-LocalhostPorts.ps1")

Write-Host ""
Write-Host "Setup complete. Start the stack:"
Write-Host "  ./scripts/up.ps1"
Write-Host "Verify: Test-NetConnection 127.0.0.1 -Port 5672"
