#Requires -Version 5.1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Test-Path .env)) {
  Copy-Item .env.example .env
  Write-Host "Created .env from .env.example"
}

$googleId = Select-String -Path .env -Pattern '^\s*AUTHENTIK_GOOGLE_CLIENT_ID\s*=\s*(.+)$' |
  ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() } |
  Select-Object -First 1
if (-not $googleId) {
  Write-Warning "AUTHENTIK_GOOGLE_CLIENT_ID is empty - Google login is skipped. Fill .env then: podman compose up -d --force-recreate authentik-server authentik-worker"
}

podman compose up -d

# Keep app configs on 127.0.0.1: refresh WSL portproxy when elevated (see docs/PODMAN_WINDOWS.md).
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
  & (Join-Path $PSScriptRoot "Sync-LocalhostPorts.ps1")
}
else {
  $ok = $false
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    $async = $client.BeginConnect("127.0.0.1", 5672, $null, $null)
    if ($async.AsyncWaitHandle.WaitOne(2000)) {
      $client.EndConnect($async)
      $ok = $true
    }
    $client.Close()
  }
  catch {
    $ok = $false
  }
  if (-not $ok) {
    Write-Warning @"
127.0.0.1:5672 is not reachable. Containers may be up on the WSL IP only.
Run once in an elevated PowerShell (after Podman install / machine recreate):
  ./scripts/Setup-PodmanWindows.ps1
Or just refresh ports:
  ./scripts/Sync-LocalhostPorts.ps1
See docs/PODMAN_WINDOWS.md
"@
  }
}

Write-Host "Stack starting. Authentik: http://127.0.0.1:9000  RabbitMQ: http://127.0.0.1:15672"
