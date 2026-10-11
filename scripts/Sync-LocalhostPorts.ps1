#Requires -Version 5.1
<#
.SYNOPSIS
  Map 127.0.0.1 published stack ports to the Podman WSL machine eth0 IP (netsh portproxy).

.NOTES
  Requires an elevated PowerShell. Safe to re-run after machine recreate / IP change.
#>
$ErrorActionPreference = "Stop"

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Error "Sync-LocalhostPorts.ps1 must run in an elevated PowerShell (Run as administrator)."
}

$distro = "podman-machine-default"
$ports = @(5672, 15672, 9000, 9443, 14333)

$running = podman machine list --format "{{.Name}} {{.Running}}" 2>$null |
  Where-Object { $_ -match ("^" + [regex]::Escape($distro) + "\s+true$") }
if (-not $running) {
  Write-Host "Starting $distro..."
  podman machine start | Out-Null
}

$ethLine = (wsl -d $distro -- ip -4 -br addr show eth0 2>$null | Out-String)
if (-not ($ethLine -match "(\d+\.\d+\.\d+\.\d+)")) {
  Write-Error "Could not read eth0 IPv4 for WSL distro '$distro'. Is the machine running?"
}
$wslIp = $Matches[1]
Write-Host "WSL eth0: $wslIp"

foreach ($p in $ports) {
  netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=$p 2>$null | Out-Null
  $null = netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=$p connectaddress=$wslIp connectport=$p
  Write-Host ("  127.0.0.1:{0} -> {1}:{0}" -f $p, $wslIp)
}

Write-Host ""
netsh interface portproxy show v4tov4
Write-Host ""
Write-Host "Localhost portproxy refreshed. Apps should keep using 127.0.0.1 (not $wslIp)."
