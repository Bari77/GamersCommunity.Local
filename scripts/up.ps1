#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "Created .env from .env.example"
}

podman compose up -d
Write-Host "Stack starting. Authentik: http://localhost:9000  RabbitMQ: http://localhost:15672"
