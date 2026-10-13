#Requires -Version 5.1
# Checks every GamersCommunity repo against the shared lint baseline (AgentKit lint/ + @bari77/gc-lint).
#
# Usage (from GamersCommunity.Local):
#   ./scripts/Lint-Workspace.ps1          # check only, exit 1 on any violation
#   ./scripts/Lint-Workspace.ps1 -Fix     # prettier --write, eslint --fix, dotnet format
#   ./scripts/Lint-Workspace.ps1 -Only Platform,WorldOfWarcraft

param(
    [switch] $Fix,
    [string[]] $Only = @()
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$targets = @(
    @{ Name = "DevKit"; Repo = "GamersCommunity.DevKit"; Front = "."; Solution = "GamersCommunity.DevKit.sln" },
    @{ Name = "Core"; Repo = "GamersCommunity.Core"; Front = $null; Solution = "GamersCommunity.Core.sln" },
    @{ Name = "Gateway"; Repo = "GamersCommunity.Gateway"; Front = $null; Solution = "GamersCommunity.Gateway.sln" },
    @{ Name = "Platform"; Repo = "GamersCommunity.Platform"; Front = "Platform.Front"; Solution = "GamersCommunity.Platform.sln" },
    @{ Name = "Template"; Repo = "GamersCommunity.Games.Template"; Front = "Template.Front"; Solution = "GamersCommunity.Template.sln" },
    @{ Name = "WorldOfWarcraft"; Repo = "GamersCommunity.Games.WorldOfWarcraft"; Front = "WorldOfWarcraft.Front"; Solution = "GamersCommunity.WorldOfWarcraft.sln" },
    @{ Name = "LeagueOfLegends"; Repo = "GamersCommunity.Games.LeagueOfLegends"; Front = "LeagueOfLegends.Front"; Solution = "GamersCommunity.LeagueOfLegends.sln" }
)

if ($Only.Count -gt 0) {
    $targets = $targets | Where-Object { $Only -contains $_.Name }
}

$failures = @()

function Invoke-Step([string] $label, [string] $directory, [scriptblock] $command) {
    Write-Host "==> $label" -ForegroundColor Cyan
    Push-Location $directory
    $ErrorActionPreference = "Continue"
    try {
        & $command
        if ($LASTEXITCODE -ne 0) {
            $script:failures += $label
        }
    }
    finally {
        Pop-Location
    }
}

foreach ($target in $targets) {
    $repo = Join-Path $root $target.Repo

    if (-not (Test-Path $repo)) {
        Write-Warning "$($target.Name): $repo not found, skipped"
        continue
    }

    if ($target.Front) {
        $front = Join-Path $repo $target.Front
        $script = if ($Fix) { "lint:fix" } else { "lint" }
        Invoke-Step "$($target.Name) front (npm run $script)" $front { npm run $script }
    }

    if ($target.Solution) {
        $solution = Join-Path $repo $target.Solution
        if ($Fix) {
            Invoke-Step "$($target.Name) dotnet format" $repo { dotnet format $solution }
        }
        else {
            Invoke-Step "$($target.Name) dotnet format --verify-no-changes" $repo { dotnet format $solution --verify-no-changes }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Lint failed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host ""
Write-Host "All repositories match the lint baseline." -ForegroundColor Green
