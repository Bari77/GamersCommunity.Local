#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "Created .env from .env.example"
}

$googleId = Select-String -Path .env -Pattern '^\s*AUTHENTIK_GOOGLE_CLIENT_ID\s*=\s*(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() } | Select-Object -First 1
if (-not $googleId) {
    Write-Warning "AUTHENTIK_GOOGLE_CLIENT_ID is empty — Google login is skipped. Fill .env then: podman compose up -d --force-recreate authentik-server authentik-worker"
}

podman compose up -d
Write-Host "Stack starting. Authentik: http://localhost:9000  RabbitMQ: http://localhost:15672"
