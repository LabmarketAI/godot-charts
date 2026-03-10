$repo = "LabmarketAI/godot-desktop-capture"
$demoDir = Join-Path $PSScriptRoot "demo"
$addonsDir = Join-Path $demoDir "addons"
$gdcDir = Join-Path $addonsDir "godot-desktop-capture"

Write-Host "Fetching latest release information for $repo..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
$asset = $release.assets | Where-Object { $_.name -match "godot-desktop-capture-.*\.zip" } | Select-Object -First 1

if (-not $asset) {
    Write-Host "No zip asset found in the latest release!" -ForegroundColor Red
    exit 1
}

$downloadUrl = $asset.browser_download_url
$zipPath = Join-Path $PSScriptRoot $asset.name

Write-Host "Downloading $($asset.name)..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "Cleaning up old version..."
if (Test-Path $gdcDir) {
    Remove-Item -Recurse -Force $gdcDir
}

Write-Host "Extracting to demo/ folder..."
Expand-Archive -Path $zipPath -DestinationPath $demoDir -Force
Remove-Item -Force $zipPath

Write-Host "Successfully updated godot-desktop-capture to $($release.tag_name)!" -ForegroundColor Green
