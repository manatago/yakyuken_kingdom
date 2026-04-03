# Restore godot/assets from a zip archive in the project root.
# Usage:
#   .\scripts\restore-assets.ps1              # latest zip
#   .\scripts\restore-assets.ps1 c8effaa      # specific commit hash
#   .\scripts\restore-assets.ps1 assets_c8effaa_20260403.zip  # specific file

param([string]$Target = "")

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
# Handle case where script is run from repo root
if (-not (Test-Path "$RepoRoot/godot")) {
    $RepoRoot = (Get-Location).Path
}

$AssetsDir = Join-Path $RepoRoot "godot/assets"

# Find archive
$Archive = ""
if ($Target -eq "") {
    $Archive = Get-ChildItem "$RepoRoot/assets_*.zip" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
} elseif (Test-Path "$RepoRoot/$Target") {
    $Archive = (Resolve-Path "$RepoRoot/$Target").Path
} elseif (Test-Path $Target) {
    $Archive = (Resolve-Path $Target).Path
} else {
    $Found = Get-ChildItem "$RepoRoot/assets_${Target}_*.zip" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($Found) { $Archive = $Found.FullName }
}

if (-not $Archive -or -not (Test-Path $Archive)) {
    Write-Error "No matching archive found"
    Write-Host "Available archives:"
    Get-ChildItem "$RepoRoot/assets_*.zip" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
    exit 1
}

Write-Host "Archive: $(Split-Path -Leaf $Archive)"

if (Test-Path $AssetsDir) {
    Write-Host "Removing existing assets..."
    Remove-Item -Recurse -Force $AssetsDir
}

Write-Host "Extracting to godot/ ..."
Expand-Archive -Path $Archive -DestinationPath (Join-Path $RepoRoot "godot") -Force

$Count = (Get-ChildItem -Recurse -File $AssetsDir | Measure-Object).Count
Write-Host "Done: $Count files restored to godot/assets/"
