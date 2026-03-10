$chartsDir = $PSScriptRoot
$captureDir = Join-Path (Split-Path $chartsDir -Parent) "godot-desktop-capture"

if (-not (Test-Path $captureDir)) {
    Write-Host "Error: Local godot-desktop-capture repo not found at $captureDir" -ForegroundColor Red
    exit 1
}

$sourceAddon = Join-Path $captureDir "project\addons\godot-desktop-capture"
$destAddon = Join-Path $chartsDir "demo\addons\godot-desktop-capture"

if (-not (Test-Path $sourceAddon)) {
    Write-Host "Error: Compiled addon not found in $sourceAddon. Did you run build_local.ps1?" -ForegroundColor Red
    exit 1
}

Write-Host "Syncing godot-desktop-capture from local sibling repository..."

# Sync files (Remove old destination and copy new)
if (Test-Path $destAddon) {
    Remove-Item -Recurse -Force $destAddon
}

Copy-Item -Path $sourceAddon -Destination (Join-Path $chartsDir "demo\addons") -Recurse -Force

Write-Host "Successfully synced local godot-desktop-capture to the demo project!" -ForegroundColor Green