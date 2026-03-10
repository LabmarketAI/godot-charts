$repo = "GodotVR/godot-xr-tools"
$demoDir = Join-Path $PSScriptRoot "demo"
$addonsDir = Join-Path $demoDir "addons"
$xrtoolsDir = Join-Path $addonsDir "godot-xr-tools"

Write-Host "Fetching latest release information for $repo..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
$asset = $release.assets | Where-Object { $_.name -eq "godot-xr-tools.zip" } | Select-Object -First 1

if (-not $asset) {
    Write-Host "No godot-xr-tools.zip asset found in the latest release!" -ForegroundColor Red
    exit 1
}

$downloadUrl = $asset.browser_download_url
$zipPath = Join-Path $PSScriptRoot $asset.name

Write-Host "Downloading $($asset.name)..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "Cleaning up old version..."
if (Test-Path $xrtoolsDir) {
    Remove-Item -Recurse -Force $xrtoolsDir
}

Write-Host "Extracting to demo/ folder..."
Expand-Archive -Path $zipPath -DestinationPath $PSScriptRoot -Force
Remove-Item -Force $zipPath

# The zip extracts 'godot-xr-tools/addons/godot-xr-tools' internally. We must move it into place.
$extractedInner = Join-Path $PSScriptRoot "godot-xr-tools\addons\godot-xr-tools"
New-Item -ItemType Directory -Force -Path $addonsDir | Out-Null
Move-Item -Path $extractedInner -Destination $xrtoolsDir -Force

# Clean up empty extracted root
$cleanUpDir = Join-Path $PSScriptRoot "godot-xr-tools"
if (Test-Path $cleanUpDir) {
    Remove-Item -Recurse -Force $cleanUpDir
}

Write-Host "Successfully updated godot-xr-tools to $($release.tag_name)!" -ForegroundColor Green