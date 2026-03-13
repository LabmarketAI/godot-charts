$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $RepoRoot 'addons/godot-charts'
$Target = Join-Path $RepoRoot 'demo/addons/godot-charts'

if (!(Test-Path $Source)) {
    throw "Source addon directory not found: $Source"
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null

$null = robocopy $Source $Target /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) {
    throw "robocopy failed with exit code $LASTEXITCODE"
}

Write-Host "Synchronized: addons/godot-charts -> demo/addons/godot-charts"
